import SwiftUI

struct JoinLobbyView: View {
    let api: APIClient

    @State private var name: String = ""
    @State private var code: String = ""
    @State private var response: JoinLobbyResponse?
    @State private var isLoading = false
    @State private var errorText: String?

    // Navigation in die Koch-Session
    @State private var goToSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Subline
                Text("Tritt einer bestehenden Kochrunde bei und koche mit!")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
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
                                .foregroundStyle(Color.snapDishBlue)
                            
                            TextField("z.B. Sarah", text: $name)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
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
                                .stroke(Color.snapDishBlue.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Code Input mit Icon
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lobby-Code")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundStyle(Color.snapDishBlue)
                            
                            TextField("6-stelliger Code", text: $code)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
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
                                .stroke(Color.snapDishBlue.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Join Button
                    Button {
                        Task { await join() }
                    } label: {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                Text("Lobby beitreten")
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
                                            Color.snapDishBlue,
                                            Color(red: 0.1, green: 0.4, blue: 0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundStyle(.white)
                        .shadow(color: Color.snapDishBlue.opacity(0.4), radius: 12, y: 6)
                    }
                    .disabled(isLoading || nameTrimmed.isEmpty || codeTrimmed.isEmpty)
                    .opacity(isLoading || nameTrimmed.isEmpty || codeTrimmed.isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                
                // Ergebnis-Bereich
                if let res = response {
                    VStack(spacing: 20) {
                        // Success Animation
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.green)
                            
                            Text("Erfolgreich beigetreten! 🎉")
                                .font(.title3)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        
                        // Lobby Info Card
                        VStack(spacing: 16) {
                            InfoRow(icon: "number.circle.fill", title: "Lobby-Code", value: res.lobby.code, accentColor: Color.snapDishBlue)
                            
                            Divider()
                            
                            InfoRow(icon: "person.fill", title: "Dein Name", value: res.user.name, accentColor: Color.snapDishOrange)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundStyle(Color.primary.opacity(0.6))
                                    Text("User-ID")
                                        .font(.caption)
                                        .foregroundStyle(Color.primary.opacity(0.6))
                                }
                                Text(res.user.id)
                                    .font(.caption2)
                                    .foregroundStyle(Color.primary.opacity(0.4))
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.95))
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
                        .padding(.horizontal, 20)
                        
                        // Start Session Info
                        Text("Du wirst automatisch zur Koch-Session weitergeleitet...")
                            .font(.caption)
                            .foregroundStyle(Color.primary.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
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
        .navigationTitle("Lobby beitreten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Lobby beitreten")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.snapDishBlue,
                                Color(red: 0.1, green: 0.4, blue: 0.9)
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
                isActive: $goToSession,
                label: { EmptyView() }
            )
            .hidden()
        )
        .snapDishBackground()
    }

    @ViewBuilder
    private var destinationView: some View {
        if let res = response {
            let hostPlaceholder = User(id: res.lobby.hostId, name: "Host", createdAt: "")
            KochSessionView(api: api, lobby: res.lobby, host: hostPlaceholder, currentUser: res.user)
        } else {
            EmptyView()
        }
    }

    private var nameTrimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var codeTrimmed: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func join() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }
        
        withAnimation {
            // Animation vorbereiten
        }
        
        do {
            let res = try await api.joinLobby(name: nameTrimmed, code: codeTrimmed)
            response = res
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                // Success Animation
            }
            // Automatisch zur Session nach 1 Sekunde
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            goToSession = true
        } catch {
            withAnimation {
                errorText = error.localizedDescription
            }
        }
    }
}

// MARK: - Info Row Component (Reuse from CreateLobbyView)
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

#Preview {
    NavigationStack {
        JoinLobbyView(api: APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!))
    }
}
