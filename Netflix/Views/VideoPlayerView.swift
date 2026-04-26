//
//  VideoPlayerView.swift
//  Netflix
//

import SwiftUI
import WebKit
import AVKit

struct VideoPlayerView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileService: ProfileService

    @ObservedObject private var watchPartyService = WatchPartyService.shared

    @State private var isLoading = true
    @State private var vidkingURL: URL? = nil
    @State private var fallbackPlayer: AVPlayer? = nil
    @State private var timeObserverToken: Any? = nil
    @State private var showChat = false

    private var isInWatchParty: Bool { watchPartyService.currentRoom != nil }
    private var usingFallback: Bool { vidkingURL == nil }

    private static let hlsStreams = [
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/master.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
    ]
    private var fallbackStreamURL: URL {
        URL(string: Self.hlsStreams[abs(movie.title.hashValue) % Self.hlsStreams.count])!
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.4)
                    Text("Loading…")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                }
            } else if let url = vidkingURL {
                VidkingWebView(url: url)
                    .ignoresSafeArea()
            } else if let player = fallbackPlayer {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .onDisappear { player.pause() }
            }

            // Overlays (hidden while loading)
            VStack {
                HStack {
                    if isInWatchParty && !isLoading {
                        Button(action: { withAnimation(.spring(response: 0.3)) { showChat.toggle() } }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(watchPartyService.connectionState == .connected ? Color.green : Color.orange)
                                    .frame(width: 7, height: 7)
                                Text(watchPartyService.isHost ? "Hosting" : "Watching together")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.65))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 52)
                        .padding(.leading, 20)
                    }
                    Spacer()
                    Button(action: closePlayer) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 52)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            .opacity(isLoading ? 0 : 1)

            if isInWatchParty && !isLoading && showChat {
                WatchPartyChatOverlayView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onDisappear { cleanupPlayer() }
        .task { await loadContent() }
        // Sync HLS fallback for watch party guests
        .onChange(of: watchPartyService.remotePosition) { _, newPos in
            guard let pos = newPos,
                  let player = fallbackPlayer,
                  !watchPartyService.isHost,
                  usingFallback else { return }
            if abs(player.currentTime().seconds - pos) > 5 {
                player.seek(to: CMTime(seconds: pos, preferredTimescale: 600))
            }
        }
        .onChange(of: watchPartyService.remoteIsPlaying) { _, isPlaying in
            guard let isPlaying,
                  let player = fallbackPlayer,
                  !watchPartyService.isHost,
                  usingFallback else { return }
            isPlaying ? player.play() : player.pause()
        }
    }

    // MARK: - Actions

    private func closePlayer() {
        saveCurrentPosition()
        cleanupPlayer()
        dismiss()
    }

    private func cleanupPlayer() {
        if let token = timeObserverToken {
            fallbackPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        fallbackPlayer?.pause()
    }

    // MARK: - Load

    private func loadContent() async {
        isLoading = true
        if movie.tmdbId != 0 {
            let base: String
            if movie.isMovie {
                base = "https://www.vidking.net/embed/movie/\(movie.tmdbId)"
            } else {
                base = "https://www.vidking.net/embed/tv/\(movie.tmdbId)/1/1"
            }
            let params = movie.isMovie
                ? "color=e50914&autoPlay=true"
                : "color=e50914&autoPlay=true&nextEpisode=true&episodeSelector=true"
            vidkingURL = URL(string: "\(base)?\(params)")
            recordProgress(position: 0)

            // Signal watch party guests that host started
            if isInWatchParty && watchPartyService.isHost {
                watchPartyService.broadcastPartyStarted()
            }
        } else {
            setupFallback()
        }
        isLoading = false
    }

    private func setupFallback() {
        let player = AVPlayer(playerItem: AVPlayerItem(url: fallbackStreamURL))
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        fallbackPlayer = player
        player.play()
        recordProgress(position: 0)

        let capturedMovie = movie
        let capturedProfileId = profileService.currentProfile?.id
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 5, preferredTimescale: 600), queue: .main
        ) { [weak player] time in
            guard let player,
                  let pid = capturedProfileId,
                  let duration = player.currentItem?.duration.seconds,
                  duration.isFinite, duration > 0 else { return }
            WatchProgressService.shared.updateProgress(
                tmdbId: capturedMovie.tmdbId, profileId: pid,
                title: capturedMovie.title, posterURL: capturedMovie.posterURL,
                position: time.seconds, duration: duration
            )
            if WatchPartyService.shared.isHost {
                WatchPartyService.shared.broadcastSync(
                    position: time.seconds,
                    isPlaying: player.timeControlStatus == .playing
                )
            }
        }
    }

    // MARK: - Progress

    private func recordProgress(position: Double) {
        guard let profileId = profileService.currentProfile?.id else { return }
        let duration = movie.duration > 0 ? Double(movie.duration) * 60 : 5400
        WatchProgressService.shared.updateProgress(
            tmdbId: movie.tmdbId, profileId: profileId,
            title: movie.title, posterURL: movie.posterURL,
            position: position, duration: duration
        )
    }

    private func saveCurrentPosition() {
        guard usingFallback, let player = fallbackPlayer else { return }
        let pos = player.currentTime().seconds
        guard pos.isFinite, pos > 0 else { return }
        recordProgress(position: pos)
    }
}

// MARK: - Vidking WKWebView

struct VidkingWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = true
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
