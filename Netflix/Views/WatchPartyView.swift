//
//  WatchPartyView.swift
//  Netflix
//

import SwiftUI

struct WatchPartyView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileService: ProfileService

    @ObservedObject private var watchPartyService = WatchPartyService.shared

    @State private var phase: Phase = .landing
    @State private var joinCodeInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showPlayer = false

    enum Phase { case landing, roomReady(WatchPartyRoom), joinEntry, roomJoined(WatchPartyRoom) }

    private var profileName: String { profileService.currentProfile?.name ?? "Guest" }
    private var profileId: UUID { profileService.currentProfile?.id ?? UUID() }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.1).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: handleClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    Spacer()
                    Text("Watch Party")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)

                switch phase {
                case .landing:
                    landingView
                case .roomReady(let room):
                    roomCreatedView(room: room)
                case .joinEntry:
                    joinEntryView
                case .roomJoined(let room):
                    roomJoinedView(room: room)
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let msg = errorMessage { Text(msg) }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            VideoPlayerView(movie: movie)
                .onDisappear {
                    watchPartyService.leaveRoom()
                }
        }
    }

    // MARK: - Landing

    private var landingView: some View {
        VStack(spacing: 24) {
            // Movie preview
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: movie.posterURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 64, height: 96)
                .cornerRadius(10)
                .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(movie.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(movie.isMovie ? "Movie · \(movie.releaseYear)" : "TV Series · \(movie.releaseYear)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 20)

            Text("Watch movies together in sync with friends — create a room or join one with a code.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 14) {
                Button(action: createRoom) {
                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "person.2.fill")
                            Text("Create a Room")
                                .fontWeight(.bold)
                        }
                    }
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(14)
                .disabled(isLoading)

                Button(action: { withAnimation { phase = .joinEntry } }) {
                    HStack(spacing: 10) {
                        Image(systemName: "link")
                        Text("Join with Code")
                            .fontWeight(.semibold)
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Room Created

    private func roomCreatedView(room: WatchPartyRoom) -> some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                Text("Room Created!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Share this code with your friends")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            // Room code display
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ForEach(Array(room.roomCode), id: \.self) { char in
                        Text(String(char))
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 52)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                }

                Button(action: {
                    UIPasteboard.general.string = room.roomCode
                }) {
                    Label("Copy Code", systemImage: "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.04))
            .cornerRadius(20)
            .padding(.horizontal, 20)

            // Connection status
            HStack(spacing: 8) {
                Circle()
                    .fill(watchPartyService.connectionState == .connected ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(watchPartyService.connectionState == .connected ? "Connected · \(watchPartyService.participants.count) in room" : "Connecting...")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: { showPlayer = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start Watching")
                        .fontWeight(.bold)
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .padding(.top, 8)
    }

    // MARK: - Join Entry

    private var joinEntryView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Enter Room Code")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Ask your friend for their 6-character code")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            TextField("", text: $joinCodeInput)
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .textCase(.uppercase)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .onChange(of: joinCodeInput) { joinCodeInput = String($0.uppercased().prefix(6)) }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(Color.white.opacity(0.07))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 20)

            Button(action: joinRoom) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text("Join Room")
                        .fontWeight(.bold)
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(joinCodeInput.count == 6 ? Color.red : Color.gray.opacity(0.4))
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .disabled(joinCodeInput.count < 6 || isLoading)

            Button(action: { withAnimation { phase = .landing } }) {
                Text("Back")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Room Joined

    private func roomJoinedView(room: WatchPartyRoom) -> some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Joined!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("You're watching with a friend")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            HStack(spacing: 16) {
                AsyncImage(url: URL(string: room.moviePosterUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 64, height: 96)
                .cornerRadius(10)
                .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(room.movieTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(watchPartyService.connectionState == .connected ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(watchPartyService.connectionState == .connected ? "Connected" : "Connecting...")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 20)

            Spacer()

            Button(action: { showPlayer = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Watch Now")
                        .fontWeight(.bold)
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .cornerRadius(14)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func createRoom() {
        isLoading = true
        Task {
            do {
                let room = try await WatchPartyService.shared.createRoom(
                    movie: movie,
                    profileId: profileId,
                    profileName: profileName
                )
                await MainActor.run {
                    isLoading = false
                    withAnimation { phase = .roomReady(room) }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func joinRoom() {
        isLoading = true
        Task {
            do {
                let room = try await WatchPartyService.shared.joinRoom(
                    code: joinCodeInput,
                    profileId: profileId,
                    profileName: profileName
                )
                await MainActor.run {
                    isLoading = false
                    withAnimation { phase = .roomJoined(room) }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleClose() {
        watchPartyService.leaveRoom()
        dismiss()
    }
}
