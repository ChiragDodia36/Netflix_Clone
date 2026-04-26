//
//  WatchPartyChatOverlayView.swift
//  Netflix
//

import SwiftUI

struct WatchPartyChatOverlayView: View {
    @ObservedObject var watchPartyService = WatchPartyService.shared
    @State private var inputText = ""
    @State private var isExpanded = true
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()

            // Chat panel
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(watchPartyService.connectionState == .connected ? Color.green : Color.orange)
                                .frame(width: 7, height: 7)
                            Text("Watch Party · \(watchPartyService.participants.count) watching")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded = false } }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.7))

                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(watchPartyService.chatMessages) { msg in
                                    ChatBubble(message: msg)
                                        .id(msg.id)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .frame(height: 180)
                        .onChange(of: watchPartyService.chatMessages.count) { _, _ in
                            if let last = watchPartyService.chatMessages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                    }
                    .background(Color.black.opacity(0.5))

                    // Input bar
                    HStack(spacing: 8) {
                        TextField("Message...", text: $inputText)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .focused($isInputFocused)
                            .submitLabel(.send)
                            .onSubmit { sendMessage() }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)

                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                                .foregroundColor(inputText.isEmpty ? .gray : .red)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                }
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
                .frame(width: 240)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Collapsed bubble
                Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded = true } }) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)

                        // Unread badge (always fresh — messages are read when expanded)
                        if !watchPartyService.chatMessages.isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 14, height: 14)
                                .overlay(Text("\(min(watchPartyService.chatMessages.count, 9))")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white))
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 60)
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        watchPartyService.sendChatMessage(text: trimmed)
        inputText = ""
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: WatchPartyChatMessage

    var body: some View {
        VStack(alignment: message.isSelf ? .trailing : .leading, spacing: 2) {
            if !message.isSelf {
                Text(message.profileName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.red.opacity(0.8))
            }
            Text(message.text)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(message.isSelf ? Color.red.opacity(0.7) : Color.white.opacity(0.12))
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: message.isSelf ? .trailing : .leading)
    }
}
