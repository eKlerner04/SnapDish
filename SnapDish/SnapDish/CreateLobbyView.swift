import SwiftUI

struct CreateLobbyView: View {
    let api: APIClient

    @State private var hostName: String = ""
    @State private var response: CreateLobbyResponse?
    @State private var isLoading = false
    @State private var errorText: String?

    // Navigation in KochSessionView
    @State private var startSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Hero-Bereich
                VStack(spacing: 12) {
                    Text("Erstelle deine eigene Kochrunde und lade Freunde ein!")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 2)
                
                // Input-Bereich
                VStack(spacing: 24) {
                    // Name Input mit Icon
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dein Name")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.snapDishOrange)
                            
                            TextField("z.B. Emil", text: $hostName)
                                .textInputAutocapitalization(.words)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.9))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.snapDishOrange.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Create Button
                    Button {
                        Task { await create() }
                    } label: {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Kochrunde starten")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.snapDishOrange,
                                            Color(red: 1.0, green: 0.3, blue: 0.4)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundStyle(.white)
                        .shadow(color: .snapDishOrange.opacity(0.4), radius: 12, y: 6)
                    }
                    .disabled(isLoading || hostName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(isLoading || hostName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                
                // Ergebnis-Bereich
                if let res = response {
                    VStack(spacing: 20) {
                        // Success Animation mit Orange/Rot
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.snapDishOrange.opacity(0.2),
                                                Color(red: 1.0, green: 0.3, blue: 0.4).opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color.snapDishOrange,
                                                Color(red: 1.0, green: 0.3, blue: 0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Lobby erfolgreich erstellt!")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        
                        // Lobby Info Card - Verbessert
                        VStack(spacing: 0) {
                            // Lobby-Code Highlight
                            VStack(spacing: 8) {
                                Text("Lobby-Code")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.primary.opacity(0.6))
                                    .textCase(.uppercase)
                                
                                HStack(spacing: 12) {
                                    
                                    Text(res.lobby.code)
                                        .font(.system(size: 32, weight: .black, design: .rounded))
                                        .foregroundStyle(Color.primary)
                                        .textSelection(.enabled)
                                }
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.snapDishOrange.opacity(0.08),
                                        Color.snapDishOrange.opacity(0.03)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            Divider()
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.snapDishOrange)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Host")
                                        .font(.caption)
                                        .foregroundStyle(Color.primary.opacity(0.6))
                                    Text(res.host.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            
                            Divider()
                            
                            // Lobby-ID
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(Color.primary.opacity(0.5))
                                    Text("Lobby-ID")
                                        .font(.caption)
                                        .foregroundStyle(Color.primary.opacity(0.6))
                                }
                                Text(res.lobby.id)
                                    .font(.caption2)
                                    .foregroundStyle(Color.primary.opacity(0.4))
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.snapDishOrange.opacity(0.2), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
                        .padding(.horizontal, 20)
                        
                        // Start Session Button
                        Button {
                            startSession = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                Text("Zur Koch-Session")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.snapDishOrange,
                                                Color(red: 1.0, green: 0.3, blue: 0.4)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundStyle(.white)
                            .shadow(color: .snapDishBlue.opacity(0.3), radius: 12, y: 6)
                        }
                        .padding(.horizontal, 20)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Error-Bereich
                if let err = errorText {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(0.1))
                    )
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Lobby erstellen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Lobby erstellen")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.snapDishOrange,
                                Color(red: 1.0, green: 0.3, blue: 0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .background(
            NavigationLink(
                destination: destinationView,
                isActive: $startSession,
                label: { EmptyView()}
            )
            .hidden()
        )
        .snapDishBackground()
    }

    @ViewBuilder
    private var destinationView: some View {
        if let res = response {
            KochSessionView(api: api, lobby: res.lobby, host: res.host, currentUser: res.host)
        } else {
            EmptyView()
        }
    }

    private func create() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }
        
        withAnimation {
            // Animation vorbereiten
        }
        
        do {
            response = try await api.createLobby(hostName: hostName)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                // Success Animation
            }
        } catch {
            withAnimation {
                errorText = error.localizedDescription
            }
        }
    }
}

// MARK: - Info Row Component
private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview() {
}
