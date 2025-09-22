import SwiftUI

struct ContentView: View {
    @State private var config = AppConfig()

    private var api: APIClient? {
        try? APIProvider.makeClient(config: config)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Willkommen bei SnapDish")
                    .font(.title2)
                    .bold()

                VStack(spacing: 4) {
                    Text("Server:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(config.serverBaseURL.isEmpty ? "— nicht gesetzt —" : config.serverBaseURL)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(config.serverBaseURL.isEmpty ? .red : .secondary)
                }
                .frame(maxWidth: .infinity)

                NavigationLink {
                    ChatView(config: config)
                } label: {
                    Text("Zum Chat")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(api == nil)

                NavigationLink {
                    HealthDemoView(config: config)
                } label: {
                    Text("Health-Demo öffnen")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Divider()

                if let api {
                    NavigationLink {
                        CreateLobbyView(api: api)
                    } label: {
                        Text("Lobby erstellen")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    NavigationLink {
                        JoinLobbyView(api: api)
                    } label: {
                        Text("Lobby beitreten")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("Bitte Server-URL in den Einstellungen setzen.")
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                NavigationLink {
                    SettingsView(config: config)
                } label: {
                    Label("Einstellungen", systemImage: "gear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Start")
        }
    }
}

#Preview {
    ContentView()
}
