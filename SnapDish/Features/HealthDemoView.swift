import SwiftUI

struct HealthDemoView: View {
    @State private var healthText = "—"
    @State private var input = "moin..."
    @State private var output = ""

    let config: AppConfig

    private var api: APIClient? {
        try? APIProvider.makeClient(config: config)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Health: \(healthText)")
                .font(.headline)

            TextEditor(text: $input)
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary))

            Button("Verbessern") {
                Task {
                    guard let api else {
                        output = "Server-URL nicht gesetzt."
                        return
                    }
                    do {
                        let res = try await api.improveEmail(text: input)
                        if let err = res.error, !err.isEmpty {
                            output = "Server-Fehler: \(err)"
                        } else {
                            output = res.email_improved ?? "(keine Antwort)"
                        }
                    } catch {
                        output = "Fehler: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            ScrollView {
                Text(output.isEmpty ? "—" : output)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .task {
            guard let api else {
                healthText = "Server-URL fehlt"
                return
            }
            do {
                let res = try await api.health()
                healthText = res.status
            } catch {
                healthText = "Server nicht erreichbar?"
            }
        }
    }
}

#Preview {
    HealthDemoView(config: AppConfig())
}
