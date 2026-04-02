//
//  VideoPlayerView.swift
//  Netflix
//

import SwiftUI
import WebKit
import AVKit

// MARK: - Full-screen landscape player

struct VideoPlayerView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileService: ProfileService

    @State private var vimeoURL: URL? = nil
    @State private var useFallback = false
    @State private var isSearching = true
    @State private var fallbackPlayer: AVPlayer? = nil
    @State private var timeObserverToken: Any? = nil

    private static let hlsStreams = [
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/master.m3u8",
        "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
    ]

    private var fallbackStreamURL: URL {
        let index = abs(movie.title.hashValue) % Self.hlsStreams.count
        return URL(string: Self.hlsStreams[index])!
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isSearching {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.4)
                    Text("Finding trailer...")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                }
            } else if let url = vimeoURL, !useFallback {
                VimeoWebView(embedURL: url)
                    .ignoresSafeArea()
            } else if let player = fallbackPlayer {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onDisappear { player.pause() }
            }

            // Close button — top right
            VStack {
                HStack {
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
            .opacity(isSearching ? 0 : 1)
        }
        .onAppear {
            forceOrientation(.landscapeRight)
        }
        .onDisappear {
            cleanupPlayer()
            forceOrientation(.portrait)
        }
        .task { await loadContent() }
    }

    // MARK: - Actions

    private func closePlayer() {
        saveCurrentPosition()
        cleanupPlayer()
        forceOrientation(.portrait)
        dismiss()
    }

    private func cleanupPlayer() {
        if let token = timeObserverToken {
            fallbackPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        fallbackPlayer?.pause()
    }

    // MARK: - Orientation

    private func forceOrientation(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = mask
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    }

    // MARK: - Load

    private func loadContent() async {
        isSearching = true
        if let url = await VimeoService.shared.searchTrailer(for: movie.title) {
            vimeoURL = url
            useFallback = false
            // Vimeo: mark as started (can't track real position in WKWebView)
            recordProgress(position: 30)
        } else {
            useFallback = true
            setupFallback()
        }
        isSearching = false
    }

    private func setupFallback() {
        let item = AVPlayerItem(url: fallbackStreamURL)
        let player = AVPlayer(playerItem: item)
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        fallbackPlayer = player
        player.play()

        // Record start immediately, then update position every 5 seconds
        recordProgress(position: 0)
        let capturedMovie = movie
        let capturedProfileId = profileService.currentProfile?.id
        let interval = CMTime(seconds: 5, preferredTimescale: 600)

        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: interval, queue: .main
        ) { [weak player] time in
            guard let player,
                  let pid = capturedProfileId,
                  let duration = player.currentItem?.duration.seconds,
                  duration.isFinite, duration > 0 else { return }
            WatchProgressService.shared.updateProgress(
                tmdbId: capturedMovie.tmdbId,
                profileId: pid,
                title: capturedMovie.title,
                posterURL: capturedMovie.posterURL,
                position: time.seconds,
                duration: duration
            )
        }
    }

    // MARK: - Progress tracking

    private func recordProgress(position: Double) {
        guard let profileId = profileService.currentProfile?.id else { return }
        let duration = movie.duration > 0 ? Double(movie.duration) * 60 : 5400
        WatchProgressService.shared.updateProgress(
            tmdbId: movie.tmdbId,
            profileId: profileId,
            title: movie.title,
            posterURL: movie.posterURL,
            position: position,
            duration: duration
        )
    }

    private func saveCurrentPosition() {
        guard useFallback, let player = fallbackPlayer else { return }
        let position = player.currentTime().seconds
        guard position.isFinite, position > 0 else { return }
        recordProgress(position: position)
    }
}

// MARK: - Vimeo WKWebView — fills full landscape screen

struct VimeoWebView: UIViewRepresentable {
    let embedURL: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = true
        #if os(iOS)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        #endif
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

        // Full-screen landscape HTML — video fills 100vw × 100vh
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100vw;
                    height: 100vh;
                    background: #000;
                    overflow: hidden;
                }
                iframe {
                    position: fixed;
                    top: 0; left: 0;
                    width: 100vw;
                    height: 100vh;
                    border: none;
                }
            </style>
        </head>
        <body>
            <iframe
                src="\(embedURL.absoluteString)"
                allow="autoplay; fullscreen; picture-in-picture"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://player.vimeo.com"))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
