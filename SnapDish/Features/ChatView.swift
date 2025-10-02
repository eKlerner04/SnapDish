import SwiftUI
import Combine

// MARK: - Modelle

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant, system }
    let id = UUID()
    let role: Role
    let text: String
    let date: Date = Date()
}

// MARK: - ViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        .init(role: .assistant, text: "Frag mich etwas…")
    ]
    @Published var input: String = ""
    @Published var isLoading: Bool = false

    let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    func send() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard let baseURL = config.resolvedBaseURL else {
            withAnimation {
                messages.append(.init(role: .system, text: "Bitte Server-URL in den Einstellungen setzen."))
            }
            return
        }

        withAnimation {
            messages.append(.init(role: .user, text: trimmed))
        }
        input = ""
        isLoading = true
        defer { isLoading = false }

        var req = URLRequest(url: baseURL.appendingPathComponent("api/example/chat"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["message": trimmed]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                withAnimation {
                    messages.append(.init(role: .system, text: "Fehler vom Server (\((resp as? HTTPURLResponse)?.statusCode ?? -1))."))
                }
                return
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["reply"] as? String {
                withAnimation {
                    messages.append(.init(role: .assistant, text: answer))
                }
            } else {
                withAnimation {
                    messages.append(.init(role: .system, text: "Keine gültige Antwort erhalten."))
                }
            }
        } catch {
            withAnimation {
                messages.append(.init(role: .system, text: "Fehler: \(error.localizedDescription)"))
            }
        }
    }
}

// MARK: - View

struct ChatView: View {
    @StateObject private var vm: ChatViewModel
    @FocusState private var inputFocused: Bool

    init(config: AppConfig) {
        _vm = StateObject(wrappedValue: ChatViewModel(config: config))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Chatverlauf
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.messages) { msg in
                            ChatBubble(message: msg)
                                .transition(.move(edge: msg.role == .user ? .trailing : .leading).combined(with: .opacity))
                        }

                        if vm.isLoading {
                            TypingBubble()
                                .transition(.opacity)
                        }

                        Color.clear.frame(height: 1).id(ScrollAnchor.bottom)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.messages.count) { _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: vm.isLoading) { isLoading in
                    if isLoading { scrollToBottom(proxy) }
                }
                .onAppear {
                    scrollToBottom(proxy, animated: false)
                }
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboardCompat()
        .snapDishBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        withAnimation {
                            vm.messages.removeAll()
                            vm.messages.append(.init(role: .assistant, text: "Neu gestartet. Was möchtest du wissen?"))
                        }
                    } label: {
                        Label("Chat leeren", systemImage: "trash")
                    }

                    if let url = vm.config.resolvedBaseURL {
                        Label(url.absoluteString, systemImage: "link")
                    } else {
                        Label("Keine Server-URL", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Optionen")
            }
        }
        .safeAreaInset(edge: .bottom) {
            InputBar(
                text: $vm.input,
                isLoading: vm.isLoading,
                onSend: { Task { await vm.send() } }
            )
            .focused($inputFocused)
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.08), radius: 12, y: -2)
        }
    }

    // MARK: - Helpers

    private enum ScrollAnchor { static let bottom = "BOTTOM_ANCHOR" }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(ScrollAnchor.bottom, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(ScrollAnchor.bottom, anchor: .bottom)
        }
    }
}

// MARK: - UI-Bausteine

private struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }
    private var isSystem: Bool { message.role == .system }

    private var bubbleBackground: some ShapeStyle {
        if isUser {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.snapDishBlue, Color(red: 0.1, green: 0.4, blue: 0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else if isSystem {
            return AnyShapeStyle(Color(.tertiarySystemFill))
        } else {
            return AnyShapeStyle(Color(.secondarySystemBackground))
        }
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if !isUser {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(isUser ? Color.white : (isSystem ? .secondary : .primary))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(bubbleBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .frame(maxWidth: 280, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message.date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .font(.body)
                        .foregroundStyle(isUser ? Color.white : (isSystem ? .secondary : .primary))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(bubbleBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .frame(maxWidth: 280, alignment: .trailing)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message.date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct TypingBubble: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text("Schreibt …")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct InputBar: View {
    @Binding var text: String
    var isLoading: Bool
    var onSend: () -> Void

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Nachricht schreiben …", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: Capsule())
                .disabled(isLoading)
                .submitLabel(.send)
                .onSubmit {
                    if !isLoading && !trimmed.isEmpty { onSend() }
                }

            Button {
                onSend()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 17, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || trimmed.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Kompat-Helfer

private extension View {
    @ViewBuilder
    func scrollDismissesKeyboardCompat() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(config: AppConfig())
    }
}
