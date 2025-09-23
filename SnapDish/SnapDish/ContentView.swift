import SwiftUI

struct ContentView: View {
    @State private var config = AppConfig()

    private var api: APIClient? {
        try? APIProvider.makeClient(config: config)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let api {
                    VStack(spacing: 16) {
                        NavigationLink {
                            CreateLobbyView(api: api)
                        } label: {
                            BigActionButtonLabel(
                                icon: "plus.circle.fill",
                                title: "Lobby erstellen",
                                subtitle: "Starte eine neue Kochrunde"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 16))

                        NavigationLink {
                            JoinLobbyView(api: api)
                        } label: {
                            BigActionButtonLabel(
                                icon: "person.2.fill",
                                title: "Lobby beitreten",
                                subtitle: "Mit Code einer Lobby beitreten"
                            )
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: 16))
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("Bitte Server-URL in den Einstellungen setzen.")
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
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
            .navigationTitle("SnapDish")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ChatView(config: config)
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right")
                    }
                    .disabled(api == nil)
                    .accessibilityLabel("Zum Chat")
                }
            }
        }
    }
}

private struct BigActionButtonLabel: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
            Text(title)
                .font(.title3)
                .bold()
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
}
