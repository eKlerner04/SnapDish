import SwiftUI

struct SettingsView: View {
    @State private var serverURLString: String
    @State private var healthText: String = "—"
    @State private var isChecking = false
    @Environment(\.dismiss) private var dismiss

    let config: AppConfig

    init(config: AppConfig) {
        self.config = config
        _serverURLString = State(initialValue: config.serverBaseURL)
    }

    var body: some View {
        Form {
            Section("Server") {
                TextField("http://192.168.0.23:3000", text: $serverURLString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)
                Button {
                    save()
                } label: {
                    Text("URL speichern")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task { await checkHealth() }
                } label: {
                    if isChecking {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Prüfe…")
                        }
                    } else {
                        Text("Health prüfen")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(serverURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                LabeledContent("Health", value: healthText)
            }

            Section("Hinweis") {
                Text("""
                Wenn du die App auf einem echten Gerät nutzt, trage hier die lokale IP-Adresse deines Macs ein (z. B. `http://172.31.129.105:3000`). \
                Die findest du auf deinem Mac im Terminal mit:
                ipconfig getifaddr en0
                Beide Geräte müssen im selben WLAN sein.
                """)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Button("Schließen") { dismiss() }
            }
        }
        .navigationTitle("Einstellungen")
        .onAppear {
            healthText = "—"
        }
    }

    private func save() {
        config.serverBaseURL = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func checkHealth() async {
        healthText = "—"
        isChecking = true
        defer { isChecking = false }
        let trimmed = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            healthText = "Ungültige URL"
            return
        }
        let api = APIClient(baseURL: url)
        do {
            let res = try await api.health()
            healthText = res.status
        } catch {
            healthText = "Fehler: \(error.localizedDescription)"
        }
    }
}
