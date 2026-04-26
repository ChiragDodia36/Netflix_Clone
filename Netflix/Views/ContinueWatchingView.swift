//
//  ContinueWatchingView.swift
//  Netflix
//

import SwiftUI

// MARK: - Section (shown on Home tab)

struct ContinueWatchingSection: View {
    let items: [WatchProgress]
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Continue Watching")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        ContinueWatchingCard(item: item) {
                            if let movie = movies.first(where: { $0.tmdbId == item.tmdbId }) {
                                onMovieTap(movie)
                            }
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
            // Removed fixed height and maxWidth
        }
    }
}

// MARK: - Card with progress bar

struct ContinueWatchingCard: View {
    let item: WatchProgress
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Poster + progress bar overlay
                ZStack(alignment: .bottom) {
                    AsyncImage(url: URL(string: item.moviePosterURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                    .frame(width: 160, height: 240)
                    .cornerRadius(16)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    // Progress bar at bottom of poster
                    VStack(spacing: 0) {
                        Spacer()
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.25))
                                    .frame(height: 3)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.red)
                                    .frame(width: geo.size.width * item.percentComplete, height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 8)
                    }

                    // Play icon overlay
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .offset(x: 1)
                        )
                }
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.95 : 1.0)

                // Title + time remaining
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.movieTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if item.minutesRemaining > 0 {
                        Text("\(item.minutesRemaining) min left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.45))
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
