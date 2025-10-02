import SwiftUI

struct ContentView: View {
    @State private var config = AppConfig()

    private var api: APIClient? {
        try? APIProvider.makeClient(config: config)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero-Bereich mit Giraffe (optional, falls du ein Hero-Image hast)
                        VStack(spacing: 12) {
                            Text("SnapDish")
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.5, blue: 0.2),  // warmes Orange
                                            Color(red: 1.0, green: 0.3, blue: 0.4)   // warmes Rot
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("Gemeinsam kochen, gemeinsam genießen")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        // Server-Status
                        if let api {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Server verbunden")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                        } else {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("Keine Verbindung")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            )
                        }

                        // Haupt-Buttons mit Icons
                        if let api {
                            VStack(spacing: 20) {
                                // Lobby erstellen (Primary Action)
                                NavigationLink {
                                    CreateLobbyView(api: api)
                                } label: {
                                    FoodActionCard(
                                        iconName: "kochTopf",
                                        title: "Kochrunde starten",
                                        subtitle: "Erstelle eine neue Lobby",
                                        accentColor: Color(red: 1.0, green: 0.5, blue: 0.2),
                                        isPrimary: true
                                    )
                                }
                                .buttonStyle(.plain)
                                
                                // Lobby beitreten
                                NavigationLink {
                                    JoinLobbyView(api: api)
                                } label: {
                                    FoodActionCard(
                                        iconName: "lobbyJoin",
                                        title: "Lobby beitreten",
                                        subtitle: "Mit Code einer Runde beitreten",
                                        accentColor: Color(red: 0.2, green: 0.6, blue: 1.0),
                                        isPrimary: true
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Fehler-Card
                            VStack(spacing: 12) {
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.red)
                                Text("Server nicht erreichbar")
                                    .font(.headline)
                                Text("Bitte Server-URL in den Einstellungen setzen.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80)
                }
                
                VStack(spacing: 0) {
                    Divider()
                    
                    NavigationLink {
                        SettingsView(config: config)
                    } label: {
                        HStack(spacing: 12) {
                            Image("settings")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                            Text("Einstellungen")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ChatView(config: config)
                    } label: {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(
                                api == nil ? .gray : Color(red: 1.0, green: 0.5, blue: 0.2)
                            )
                    }
                    .disabled(api == nil)
                    .accessibilityLabel("Zum Chat")
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        HealthDemoView(config: config)
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(
                                api == nil ? .gray : .pink
                            )
                    }
                    .disabled(api == nil)
                    .accessibilityLabel("Health Demo")
                }
            }
        }
        .snapDishBackground()
    }
}

// MARK: - Food Action Card
private struct FoodActionCard: View {
    let iconName: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let isPrimary: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon-Container
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(accentColor)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    isPrimary
                        ? LinearGradient(
                            colors: [
                                accentColor.opacity(0.1),
                                accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(
            color: accentColor.opacity(isPrimary ? 0.25 : 0.15),
            radius: isPrimary ? 10 : 8,
            y: isPrimary ? 4 : 3
        )
    }
}

#Preview {
    ContentView()
}
