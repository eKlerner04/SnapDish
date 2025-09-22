import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var input: String = ""
    @State private var reply: String = "Frag mich etwas…"
    @State private var isLoading: Bool = false

    let config: AppConfig

    var body: some View {
        VStack(spacing: 16) {
            Text("Antwort:")
                .font(.headline)

            ScrollView {
                Text(reply)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)

            TextField("Deine Frage eingeben", text: $input)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .disabled(isLoading)

            Button {
                Task { await sendMessage() }
            } label: {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Senden…")
                    }
                } else {
                    Text("Senden")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .navigationTitle("Chat")
        .toolbar {
        }
    }

    private func sendMessage() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let baseURL = config.resolvedBaseURL else {
            reply = "Bitte Server-URL in den Einstellungen setzen."
            return
        }

        isLoading = true
        defer { isLoading = false }

        var req = URLRequest(url: baseURL.appendingPathComponent("api/example/chat"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["message": trimmed]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                reply = "Fehler vom Server"
                return
            }
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let answer = json["reply"] as? String {
                reply = answer
            } else {
                reply = "Keine Antwort"
            }
        } catch {
            reply = "Fehler: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ChatView(config: AppConfig())
}
