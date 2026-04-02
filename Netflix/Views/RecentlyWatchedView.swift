//
//  RecentlyWatchedView.swift
//  Netflix
//
//  Feature H — Viewing History

import SwiftUI

// MARK: - Section (shown on Home tab)

struct RecentlyWatchedSection: View {
    let items: [WatchProgress]
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recently Watched")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                NavigationLink {
                    ViewingHistoryView(items: items, movies: movies, onMovieTap: onMovieTap)
                } label: {
                    Text("See All")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items.prefix(10)) { item in
                        HistoryCard(item: item) {
                            if let movie = movies.first(where: { $0.tmdbId == item.tmdbId }) {
                                onMovieTap(movie)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 290)
        }
    }
}

// MARK: - History card (poster + date badge)

struct HistoryCard: View {
    let item: WatchProgress
    let onTap: () -> Void
    @State private var isPressed = false

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.lastWatchedAt, relativeTo: Date())
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topTrailing) {
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
                    .scaleEffect(isPressed ? 0.95 : 1.0)

                    // Completed checkmark badge
                    if item.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.green)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .padding(2)
                            )
                            .padding(10)
                    }
                }
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.movieTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(relativeDate)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Full history screen ("See All")

struct ViewingHistoryView: View {
    let items: [WatchProgress]
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.05, blue: 0.13).ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(items) { item in
                        HistoryCard(item: item) {
                            if let movie = movies.first(where: { $0.tmdbId == item.tmdbId }) {
                                onMovieTap(movie)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Watch History")
        .navigationBarTitleDisplayMode(.large)
    }
}
