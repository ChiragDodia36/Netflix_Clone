//
//  WatchPartyService.swift
//  Netflix
//
//  Supabase Realtime Broadcast for Watch Party sync.
//  Requires SupabaseURL and SupabaseAnonKey in Info.plist.
//

import Foundation
import Combine

class WatchPartyService: ObservableObject {
    static let shared = WatchPartyService()

    // MARK: - Published state

    @Published var currentRoom: WatchPartyRoom? = nil
    @Published var isHost = false
    @Published var participants: [String] = []
    @Published var chatMessages: [WatchPartyChatMessage] = []
    @Published var remotePosition: Double? = nil
    @Published var remoteIsPlaying: Bool? = nil
    @Published var connectionState: WatchPartyConnectionState = .disconnected
    @Published var hostStarted = false

    // MARK: - Supabase config

    private var supabaseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String ?? ""
    }
    private var supabaseAnonKey: String {
        Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String ?? ""
    }
    private var isConfigured: Bool { !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty }

    // MARK: - WebSocket state

    private var webSocketTask: URLSessionWebSocketTask?
    private var heartbeatTimer: Timer?
    private var channelTopic: String?
    private var joinRef = "1"
    private var refCounter = 1
    private var myProfileName = ""

    private init() {}

    // MARK: - Room Management

    func createRoom(movie: Movie, profileId: UUID, profileName: String) async throws -> WatchPartyRoom {
        guard isConfigured else { throw WatchPartyError.notConfigured }
        myProfileName = profileName
        let roomCode = generateRoomCode()
        let body: [String: Any] = [
            "room_code": roomCode,
            "host_id": profileId.uuidString,
            "movie_tmdb_id": movie.tmdbId,
            "movie_title": movie.title,
            "movie_poster_url": movie.posterURL
        ]
        let data = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: URL(string: "\(supabaseURL)/rest/v1/watch_party_rooms")!)
        request.httpMethod = "POST"
        setHeaders(&request)
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw WatchPartyError.roomCreationFailed
        }

        let rooms = try decodeRooms(responseData)
        guard let room = rooms.first else { throw WatchPartyError.roomCreationFailed }

        await MainActor.run {
            currentRoom = room
            isHost = true
            participants = [profileName]
        }
        connectToChannel(roomCode: roomCode, profileName: profileName)
        return room
    }

    func joinRoom(code: String, profileId: UUID, profileName: String) async throws -> WatchPartyRoom {
        guard isConfigured else { throw WatchPartyError.notConfigured }
        myProfileName = profileName

        let urlStr = "\(supabaseURL)/rest/v1/watch_party_rooms?room_code=eq.\(code)&is_active=eq.true&select=*"
        var request = URLRequest(url: URL(string: urlStr)!)
        setHeaders(&request)

        let (data, _) = try await URLSession.shared.data(for: request)
        let rooms = try decodeRooms(data)
        guard let room = rooms.first else { throw WatchPartyError.roomNotFound }

        await MainActor.run {
            currentRoom = room
            isHost = false
            participants = [profileName]
        }
        connectToChannel(roomCode: code, profileName: profileName)
        return room
    }

    func leaveRoom() {
        disconnectFromChannel()
        DispatchQueue.main.async {
            self.currentRoom = nil
            self.isHost = false
            self.participants = []
            self.chatMessages = []
            self.remotePosition = nil
            self.remoteIsPlaying = nil
            self.hostStarted = false
        }
    }

    // MARK: - Broadcast

    func broadcastPartyStarted() {
        sendBroadcast(event: "started", payload: [:])
    }

    func broadcastSync(position: Double, isPlaying: Bool) {
        guard currentRoom != nil, isHost else { return }
        let payload: [String: Any] = [
            "position": position,
            "is_playing": isPlaying,
            "sender": myProfileName
        ]
        sendBroadcast(event: "sync", payload: payload)
    }

    func sendChatMessage(text: String) {
        let msgId = UUID()
        let payload: [String: Any] = [
            "id": msgId.uuidString,
            "profile_name": myProfileName,
            "text": text,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        sendBroadcast(event: "chat", payload: payload)
        // Echo locally as "self" message
        let msg = WatchPartyChatMessage(id: msgId, profileName: myProfileName, text: text, timestamp: Date(), isSelf: true)
        DispatchQueue.main.async { self.chatMessages.append(msg) }
    }

    // MARK: - WebSocket / Phoenix Protocol

    private func connectToChannel(roomCode: String, profileName: String) {
        let topic = "party-\(roomCode)"
        channelTopic = topic
        DispatchQueue.main.async { self.connectionState = .connecting }

        guard let url = URL(string: "\(supabaseURL)/realtime/v1/websocket?apikey=\(supabaseAnonKey)&vsn=1.0.0") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        joinChannel(topic: topic)
        startReceiving()
        startHeartbeat()

        // Announce presence
        let joinPayload: [String: Any] = ["profile_name": profileName]
        sendBroadcast(event: "joined", payload: joinPayload)
    }

    private func joinChannel(topic: String) {
        let realtimeTopic = "realtime:\(topic)"
        let message: [Any] = [
            joinRef,
            nextRef(),
            realtimeTopic,
            "phx_join",
            [
                "config": [
                    "broadcast": ["self": false],
                    "presence": ["key": ""]
                ],
                "access_token": supabaseAnonKey
            ] as [String: Any]
        ]
        sendRaw(message)
    }

    private func sendBroadcast(event: String, payload: [String: Any]) {
        guard let topic = channelTopic else { return }
        let realtimeTopic = "realtime:\(topic)"
        let message: [Any] = [
            joinRef,
            nextRef(),
            realtimeTopic,
            "broadcast",
            ["type": "broadcast", "event": event, "payload": payload] as [String: Any]
        ]
        sendRaw(message)
    }

    private func sendRaw(_ message: [Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let str = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(str)) { error in
            if let error { print("WatchParty send error: \(error)") }
        }
    }

    private func nextRef() -> String {
        refCounter += 1
        return "\(refCounter)"
    }

    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                if case .string(let str) = message { self.handleMessage(str) }
                self.startReceiving()
            case .failure(let error):
                print("WatchParty receive error: \(error)")
                DispatchQueue.main.async { self.connectionState = .disconnected }
            }
        }
    }

    private func handleMessage(_ str: String) {
        guard let data = str.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [Any],
              arr.count >= 5 else { return }

        let event = arr[3] as? String ?? ""
        let payload = arr[4] as? [String: Any] ?? [:]

        switch event {
        case "phx_reply":
            if (payload["status"] as? String) == "ok" {
                DispatchQueue.main.async { self.connectionState = .connected }
            }
        case "broadcast":
            let bEvent = payload["event"] as? String ?? ""
            let bPayload = payload["payload"] as? [String: Any] ?? [:]
            handleBroadcast(event: bEvent, payload: bPayload)
        default: break
        }
    }

    private func handleBroadcast(event: String, payload: [String: Any]) {
        switch event {
        case "sync":
            guard !isHost else { return }
            let position = payload["position"] as? Double ?? 0
            let isPlaying = payload["is_playing"] as? Bool ?? false
            DispatchQueue.main.async {
                self.hostStarted = true
                self.remotePosition = position
                self.remoteIsPlaying = isPlaying
            }

        case "chat":
            let id = UUID(uuidString: payload["id"] as? String ?? "") ?? UUID()
            let name = payload["profile_name"] as? String ?? "Unknown"
            let text = payload["text"] as? String ?? ""
            let formatter = ISO8601DateFormatter()
            let ts = formatter.date(from: payload["timestamp"] as? String ?? "") ?? Date()
            let msg = WatchPartyChatMessage(id: id, profileName: name, text: text, timestamp: ts, isSelf: false)
            DispatchQueue.main.async { self.chatMessages.append(msg) }

        case "started":
            guard !isHost else { return }
            DispatchQueue.main.async { self.hostStarted = true }

        case "joined":
            if let name = payload["profile_name"] as? String {
                DispatchQueue.main.async {
                    if !self.participants.contains(name) { self.participants.append(name) }
                }
            }

        default: break
        }
    }

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            let heartbeat: [Any] = ["", self.nextRef(), "phoenix", "heartbeat", [:] as [String: Any]]
            self.sendRaw(heartbeat)
        }
    }

    private func disconnectFromChannel() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        channelTopic = nil
        DispatchQueue.main.async { self.connectionState = .disconnected }
    }

    // MARK: - Helpers

    private func setHeaders(_ request: inout URLRequest) {
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }

    private func decodeRooms(_ data: Data) throws -> [WatchPartyRoom] {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return try decoder.decode([WatchPartyRoom].self, from: data)
    }

    private func generateRoomCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no ambiguous chars (0/O, 1/I)
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
