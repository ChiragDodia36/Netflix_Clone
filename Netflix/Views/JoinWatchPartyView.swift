//
//  JoinWatchPartyView.swift
//  Netflix
//
//  Standalone sheet for joining a Watch Party without needing a movie card.
//  After joining the guest waits on a lobby screen until the host starts playback.
//

import SwiftUI

struct JoinWatchPartyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileService: ProfileService

    @ObservedObject private var watchPartyService = WatchPartyService.shared

    @State private var phase: Phase = .codeEntry
    @State private var codeInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var joinedMovie: Movie? = nil

    enum Phase { case codeEntry, waiting }

    private var profileName: String { profileService.currentProfile?.name ?? "Guest" }
    private var profileId: UUID   { profileService.currentProfile?.id ?? UUID() }

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
                    Text(phase == .codeEntry ? "Join Watch Party" : "Watch Party")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)

                switch phase {
                case .codeEntry:
                    codeEntryView
                case .waiting:
                    waitingView
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
        // Launch player as soon as host starts broadcasting sync
        .fullScreenCover(isPresented: Binding(
            get: { watchPartyService.hostStarted && joinedMovie != nil },
            set: { if !$0 {
                watchPartyService.hostStarted = false
                watchPartyService.leaveRoom()
                dismiss()
            }}
        )) {
            if let movie = joinedMovie {
                VideoPlayerView(movie: movie)
                    .onDisappear {
                        watchPartyService.leaveRoom()
                    }
            }
        }
    }

    // MARK: - Code Entry

    private var codeEntryView: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
            }
            .padding(.bottom, 20)

            VStack(spacing: 8) {
                Text("Enter Room Code")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Ask the host for their 6-character code")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 32)

            TextField("", text: $codeInput)
                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .keyboardType(.asciiCapable)
                .onChange(of: codeInput) { _, val in
                    codeInput = String(val.uppercased().prefix(6))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(Color.white.opacity(0.07))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                    codeInput.count == 6 ? Color.red.opacity(0.6) : Color.white.opacity(0.15),
                    lineWidth: 1.5
                ))
                .padding(.horizontal, 32)

            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < codeInput.count ? Color.red : Color.white.opacity(0.2))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, 14)

            Spacer()

            Button(action: joinRoom) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Join Room")
                            .fontWeight(.bold)
                    }
                }
            }
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(codeInput.count == 6 ? Color.red : Color.gray.opacity(0.35))
            .cornerRadius(14)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .disabled(codeInput.count < 6 || isLoading)
        }
    }

    // MARK: - Waiting Room

    private var waitingView: some View {
        VStack(spacing: 28) {
            // Movie card
            if let movie = joinedMovie {
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
            }

            // Waiting indicator
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(1.3)
                Text("Waiting for the host to start…")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Text("The video will play automatically when the host starts.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.04))
            .cornerRadius(20)
            .padding(.horizontal, 20)

            // Participants
            if !watchPartyService.participants.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("In this room")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(watchPartyService.participants, id: \.self) { name in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(name.prefix(1)).uppercased())
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.red)
                                        )
                                    Text(name)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func joinRoom() {
        isLoading = true
        Task {
            do {
                let room = try await WatchPartyService.shared.joinRoom(
                    code: codeInput,
                    profileId: profileId,
                    profileName: profileName
                )
                let movie = Movie(
                    tmdbId: room.movieTmdbId,
                    title: room.movieTitle,
                    posterURL: room.moviePosterUrl,
                    backdropURL: room.moviePosterUrl,
                    releaseYear: 0,
                    rating: "",
                    duration: 0,
                    genre: "",
                    isMovie: true,
                    isTrending: false,
                    isFeatured: false,
                    description: ""
                )
                await MainActor.run {
                    isLoading = false
                    joinedMovie = movie
                    withAnimation { phase = .waiting }
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
