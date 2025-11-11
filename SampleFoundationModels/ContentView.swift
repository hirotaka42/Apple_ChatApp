//
//  ContentView.swift
//  SampleFoundationModels
//
//  Created by user on R 7/11/11.
//

import SwiftUI
import FoundationModels

struct ChatMessage: Identifiable, Hashable {
    enum Role {
        case user
        case assistant
        case system
    }
    let id = UUID()
    let role: Role
    let text: String
    let timestamp: Date = .init()
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            GenerativeView()
        }
        .preferredColorScheme(nil) // Support both light and dark mode
    }
}

struct GenerativeView: View {
    // System Language Model への参照
    private var model = SystemLanguageModel.default

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var lastError: String?
    @State private var session: LanguageModelSession?

    var body: some View {
        ZStack {
            // Liquid Glass Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.15),
                    Color.pink.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ステータス表示エリア
                statusBanner()
                    .padding(.top, 8)

                switch model.availability {
                case .available:
                    chatUI(enabled: true)
                        .task {
                            // セッションを初期化
                            if session == nil {
                                print("🔄 セッションを初期化中...")
                                session = LanguageModelSession(model: model)
                                print("✅ セッション初期化完了")
                            } else {
                                print("ℹ️ セッションは既に初期化済み")
                            }
                        }

                case .unavailable(.deviceNotEligible):
                    chatUI(enabled: false)

                case .unavailable(.appleIntelligenceNotEnabled):
                    chatUI(enabled: false)

                case .unavailable(.modelNotReady):
                    chatUI(enabled: false)

                case .unavailable(let other):
                    chatUI(enabled: false)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func statusBanner() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch model.availability {
            case .available:
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: model.availability)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FoundationModels 利用可能")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Apple Intelligence が正常に動作しています")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

            case .unavailable(.deviceNotEligible):
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("デバイス非対応")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("このデバイスは Apple Intelligence に対応していません")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("対応デバイス: A17 Pro / M-series チップ搭載デバイス")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

            case .unavailable(.appleIntelligenceNotEnabled):
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Intelligence 無効")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("設定 > Apple Intelligence & Siri で有効にしてください")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

            case .unavailable(.modelNotReady):
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("モデル準備中")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("モデルをダウンロード・初期化中です。しばらくお待ちください。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.9)
                }

            case .unavailable(let other):
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("利用不可")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("モデルを利用できません: \(String(describing: other))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func chatUI(enabled: Bool) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if messages.isEmpty {
                            emptyStateView()
                        } else {
                            ForEach(messages) { msg in
                                messageRow(msg)
                                    .id(msg.id)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 8)
                }
                .onChange(of: messages) { _, _ in
                    if let lastID = messages.last?.id {
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            inputBar(enabled: enabled && !isSending)
        }
        .navigationTitle("Chat")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if !messages.isEmpty {
                    Button(action: {
                        withAnimation {
                            messages.removeAll()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("すべてのメッセージをクリア")
                }
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { lastError != nil },
            set: { if !$0 { lastError = nil } }
        )) {
            Button("OK", role: .cancel) { lastError = nil }
        } message: {
            Text(lastError ?? "")
        }
    }

    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
                .symbolEffect(.pulse)
            Text("会話を始めましょう")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text("下のメッセージボックスから質問を入力してください")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                // Assistant icon
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))

                bubble(text: message.text, timestamp: message.timestamp, isUser: false)
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
                bubble(text: message.text, timestamp: message.timestamp, isUser: true)

                // User icon
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
            }
        }
    }

    @ViewBuilder
    private func bubble(text: String, timestamp: Date, isUser: Bool) -> some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)

            Text(timeString(from: timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background {
            if isUser {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.6),
                        Color.blue.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.regularMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(isUser ? 0.3 : 0.2),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    @ViewBuilder
    private func inputBar(enabled: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text input field
            HStack(spacing: 8) {
                TextField("メッセージを入力", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .disabled(!enabled)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .submitLabel(.send)
                    .onSubmit {
                        if enabled && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending {
                            Task { await send() }
                        }
                    }
            }

            // Send button
            Button {
                Task { await send() }
            } label: {
                Image(systemName: isSending ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        enabled && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
                            ? LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.gray, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .disabled(!enabled || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .frame(width: 44, height: 44)
            .background(.thinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .accessibilityLabel(isSending ? "送信を停止" : "メッセージを送信")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            .regularMaterial,
            in: Rectangle()
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.white.opacity(0.2)),
            alignment: .top
        )
    }

    @MainActor
    private func send() async {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        // デバッグ: モデルの可用性を確認
        print("🔍 Model availability: \(model.availability)")

        guard model.availability == .available else {
            lastError = "モデルが利用できません。現在のステータス: \(model.availability)"
            return
        }

        isSending = true
        defer { isSending = false }

        messages.append(.init(role: .user, text: prompt))
        inputText = ""

        do {
            // Apple Intelligence API を使用してテキスト生成
            guard let session = session else {
                print("❌ セッションが初期化されていません")
                throw NSError(domain: "LanguageModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "セッションが初期化されていません"])
            }

            print("✅ セッションが利用可能、応答をリクエスト中...")

            // LanguageModelSession の respond メソッドを使用
            let response = try await session.respond(to: prompt)

            print("✅ 応答を受信: \(response.content.prefix(50))...")

            // レスポンスから文字列を取得
            messages.append(.init(role: .assistant, text: response.content))
        } catch {
            print("❌ エラー発生: \(error.localizedDescription)")
            lastError = error.localizedDescription
            messages.append(.init(role: .assistant, text: "エラーが発生しました: \(error.localizedDescription)"))
        }
    }
}

#Preview {
    ContentView()
}
