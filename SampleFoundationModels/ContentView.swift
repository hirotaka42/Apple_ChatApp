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
        VStack(spacing: 0) {
            // ステータス表示エリア
            statusBanner()

            switch model.availability {
            case .available:
                chatUI(enabled: true)
                    .task {
                        // セッションを初期化
                        if session == nil {
                            session = LanguageModelSession(model: model)
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

    @ViewBuilder
    private func statusBanner() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch model.availability {
            case .available:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("FoundationModels 利用可能")
                        .font(.headline)
                    Spacer()
                }
                Text("Apple Intelligence が正常に動作しています")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .unavailable(.deviceNotEligible):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("デバイス非対応")
                        .font(.headline)
                    Spacer()
                }
                Text("このデバイスは Apple Intelligence に対応していません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("対応デバイス: A17 Pro / M-series チップ搭載デバイス")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

            case .unavailable(.appleIntelligenceNotEnabled):
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Apple Intelligence 無効")
                        .font(.headline)
                    Spacer()
                }
                Text("設定 > Apple Intelligence & Siri で有効にしてください")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .unavailable(.modelNotReady):
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)
                    Text("モデル準備中")
                        .font(.headline)
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text("モデルをダウンロード・初期化中です。しばらくお待ちください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            case .unavailable(let other):
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("利用不可")
                        .font(.headline)
                    Spacer()
                }
                Text("モデルを利用できません: \(String(describing: other))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func chatUI(enabled: Bool) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { msg in
                            messageRow(msg)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages) { _, _ in
                    if let lastID = messages.last?.id {
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            inputBar(enabled: enabled && !isSending)
        }
        .navigationTitle("Chat")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isSending {
                    ProgressView()
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
    private func messageRow(_ message: ChatMessage) -> some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                bubble(text: message.text, isUser: false)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble(text: message.text, isUser: true)
            }
        }
    }

    @ViewBuilder
    private func bubble(text: String, isUser: Bool) -> some View {
        Text(text)
            .padding(12)
            .background(isUser ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
            .foregroundStyle(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func inputBar(enabled: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("メッセージを入力", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(!enabled)

            Button("クリア") {
                messages.removeAll()
            }
            .disabled(!enabled && messages.isEmpty)

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!enabled || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding()
    }

    @MainActor
    private func send() async {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        guard model.availability == .available else {
            lastError = "モデルが利用できません。"
            return
        }

        isSending = true
        defer { isSending = false }

        messages.append(.init(role: .user, text: prompt))
        inputText = ""

        do {
            // Apple Intelligence API を使用してテキスト生成
            guard let session = session else {
                throw NSError(domain: "LanguageModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "セッションが初期化されていません"])
            }

            // LanguageModelSession の respond メソッドを使用
            let response = try await session.respond(to: prompt)

            // レスポンスから文字列を取得
            messages.append(.init(role: .assistant, text: response.content))
        } catch {
            lastError = error.localizedDescription
            messages.append(.init(role: .assistant, text: "エラーが発生しました: \(error.localizedDescription)"))
        }
    }
}

#Preview {
    ContentView()
}
