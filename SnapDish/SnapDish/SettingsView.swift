import SwiftUI
import Foundation

struct SettingsView: View {
    @State private var serverURLString: String
    @State private var healthText: String = "—"
    @State private var isChecking = false
    @State private var showSuccessMessage = false
    @Environment(\.dismiss) private var dismiss

    let config: AppConfig

    init(config: AppConfig) {
        self.config = config
        _serverURLString = State(initialValue: config.serverBaseURL)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                headerSection
                
                // Server Configuration Card
                serverConfigCard
                
                // Health Status Card
                healthStatusCard
                
                // Info Card
                infoCard
                
                // Action Buttons
                actionButtons
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Einstellungen")
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
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Fertig") { 
                    dismiss() 
                }
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
                .fontWeight(.semibold)
            }
        }
        .snapDishBackground()
        .onAppear {
            healthText = "—"
        }
    }

    // MARK: - View Components
    
    @ViewBuilder
    private var headerSection: some View {
    }
    
    @ViewBuilder
    private var serverConfigCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundStyle(Color.snapDishBlue)
                    .font(.title2)
                
                Text("Server-URL")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
                TextField("http://192.168.0.23:3000", text: $serverURLString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)
                .font(.body)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.snapDishBlue.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
            
                Button {
                    save()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccessMessage = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSuccessMessage = false
                    }
                }
                } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("URL speichern")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.snapDishBlue, Color(red: 0.1, green: 0.4, blue: 0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                )
                .shadow(color: Color.snapDishBlue.opacity(0.3), radius: 8, y: 4)
            }
        
            .buttonStyle(.plain)
            
            if showSuccessMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("URL erfolgreich gespeichert!")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.snapDishBlue.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var healthStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.circle")
                    .foregroundStyle(Color.snapDishGreen)
                    .font(.title2)
                
                Text("Server-Status")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button {
                    Task { await checkHealth() }
                } label: {
                    HStack(spacing: 8) {
                    if isChecking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Prüfe…")
                        } else {
                            Image(systemName: "arrow.clockwise")
                            Text("Health prüfen")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.snapDishGreen)
                    )
                }
                .buttonStyle(.plain)
                .disabled(serverURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isChecking)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(healthText)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(healthText == "ok" ? .green : healthText.contains("Fehler") ? .red : .primary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.snapDishGreen.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var infoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.snapDishOrange)
                    .font(.title2)
                
                Text("Hinweise")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Für echte Geräte:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Trage die lokale IP-Adresse deines Macs ein (z. B. `http://172.17.224.85:3000`)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Text("IP-Adresse finden:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.top, 8)
                
                Text("Öffne das Terminal auf deinem Mac und gib ein:")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Text("ipconfig getifaddr en0")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                
                Text("Wichtig:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .padding(.top, 8)
                
                Text("Beide Geräte müssen im selben WLAN sein!")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.snapDishOrange.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Fertig")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
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
                .shadow(color: Color.snapDishOrange.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Functions

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

#Preview {
    NavigationStack {
        SettingsView(config: AppConfig())
    }
}
