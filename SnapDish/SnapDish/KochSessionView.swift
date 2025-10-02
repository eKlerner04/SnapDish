import SwiftUI
import Combine

struct KochSessionView: View {
    let api: APIClient
    let lobby: Lobby
    let host: User
    let currentUser: User?

    @State private var members: [User] = []
    @State private var isLoadingMembers = false
    @State private var errorText: String?

    @State private var recipesCount: Int = 0
    @State private var isLoadingRecipes = false
    @State private var recipesError: String?

    @State private var goToCreateRecipes = false
    @State private var goToVoting = false

    @State private var recipesUpdatedCancellable: AnyCancellable?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                lobbyInfoCard
                actionButtons
                statsCards
                membersSection
                errorSection
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Koch-Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Koch-Session")
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
                Button {
                    Task { await reloadAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.snapDishOrange)
                        .rotationEffect(.degrees(isLoadingMembers || isLoadingRecipes ? 360 : 0))
                        .animation(
                            isLoadingMembers || isLoadingRecipes 
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .easeOut(duration: 0.3),
                            value: isLoadingMembers || isLoadingRecipes
                        )
                }
                .disabled(isLoadingMembers || isLoadingRecipes)
            }
        }
        .background(
            Group {
                NavigationLink(
                    destination: destinationCreateRecipes,
                    isActive: $goToCreateRecipes,
                    label: { EmptyView() }
                )
                .hidden()
                
                NavigationLink(
                    destination: destinationVoting,
                    isActive: $goToVoting,
                    label: { EmptyView() }
                )
                .hidden()
            }
        )
        .snapDishBackground()
        .onAppear {
            goToVoting = false
            recipesUpdatedCancellable = NotificationCenter.default
                .publisher(for: .recipesUpdated)
                .sink { _ in
                    Task { await loadRecipesCount() }
                }
        }
        .onDisappear {
            recipesUpdatedCancellable?.cancel()
            recipesUpdatedCancellable = nil
        }
        .task {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                await reloadAll()
            }
        }
        .refreshable {
            await reloadAll()
        }
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
            Task { await reloadAll() }
        }
    }

    // MARK: - View Components
    
    @ViewBuilder
    private var heroSection: some View {
    }
    
    @ViewBuilder
    private var lobbyInfoCard: some View {
        VStack(spacing: 0) {
            // Code Highlight
            VStack(spacing: 8) {
                Text("LOBBY-CODE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary.opacity(0.5))
                
                HStack(spacing: 12) {
                    
                    Text(lobby.code)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color.snapDishOrange.opacity(0.06))
            
            Divider()
            
            // Host Info
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Host")
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.6))
                    Text(host.name.isEmpty ? "Host" : host.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
            }
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
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Rezepte erstellen
            Button {
                goToCreateRecipes = true
            } label: {
                SessionActionCard(
                    imageName: "createRecipe",
                    title: "Rezepte erstellen",
                    subtitle: "Zutaten sammeln & AI starten",
                    accentColor: Color.snapDishOrange
                )
            }
            .buttonStyle(.plain)
            
            // Rezepte voten
            Button {
                goToVoting = true
            } label: {
                SessionActionCard(
                    imageName: "voteRecipe",
                    title: "Rezepte voten",
                    subtitle: recipesCount > 0 ? "\(recipesCount) Rezepte verfügbar" : "Noch keine Rezepte",
                    accentColor: Color.snapDishBlue
                )
            }
            .buttonStyle(.plain)
            .disabled(recipesCount == 0)
            .opacity(recipesCount == 0 ? 0.6 : 1.0)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var statsCards: some View {
        HStack(spacing: 12) {
            // Rezepte
            InfoStatCard(
                imageName: "recipe",
                count: recipesCount,
                label: "Rezepte",
                accentColor: Color.snapDishOrange
            )
            
            // Mitglieder
            InfoStatCard(
                imageName: "members",
                count: members.count + 1,
                label: "Mitglieder",
                accentColor: Color.snapDishBlue
            )
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var membersSection: some View {
        if !members.isEmpty || isLoadingMembers {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Mitglieder")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Button {
                        Task { await reloadAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                    }
                    .disabled(isLoadingMembers)
                }
                .padding(.horizontal, 20)
                
                if isLoadingMembers && members.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if members.isEmpty {
                    Text("Noch keine Mitglieder beigetreten")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Host
                            MemberBubble(user: host, isHost: true)
                            
                            // Members
                            ForEach(members.filter { $0.id != host.id }, id: \.id) { member in
                                MemberBubble(user: member, isHost: false)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let err = errorText {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.red.opacity(0.1))
            )
            .padding(.horizontal, 20)
        }
        
        if let err = recipesError {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.1))
            )
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var destinationCreateRecipes: some View {
        CreateRecipesView(api: api, lobby: lobby, host: host)
    }

    @ViewBuilder
    private var destinationVoting: some View {
        if let me = currentUser {
            LeftRightView(api: api, lobby: lobby, currentUser: me)
        } else {
            Text("Unbekannter Nutzer")
        }
    }

    @MainActor
    private func reloadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadMembers() }
            group.addTask { await loadRecipesCount() }
        }
    }

    @MainActor
    private func loadMembers() async {
        errorText = nil
        isLoadingMembers = true
        defer { isLoadingMembers = false }
        do {
            var fetched = try await api.fetchLobbyMembers(lobbyId: lobby.id)
            fetched.removeAll { $0.id == host.id }
            members = fetched
        } catch {
            errorText = "Mitglieder konnten nicht geladen werden"
        }
    }

    @MainActor
    private func loadRecipesCount() async {
        isLoadingRecipes = true
        defer { isLoadingRecipes = false }
        do {
            let list = try await api.fetchRecipes(lobbyId: lobby.id)
            recipesCount = list.count
            recipesError = nil // Fehler zurücksetzen bei erfolgreichem Laden
        } catch {
            recipesError = "Rezepte konnten nicht geladen werden: \(error.localizedDescription)"
            // recipesCount nicht zurücksetzen, um den letzten bekannten Wert zu behalten
        }
    }
}

// MARK: - Session Action Card (mit Custom Images)
private struct SessionActionCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Custom Image Icon
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
            
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
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
    }
}

// MARK: - Info Stat Card (mit Custom Images)
private struct InfoStatCard: View {
    let imageName: String
    let count: Int
    let label: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            
            Text("\(count)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)
            
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary.opacity(0.6))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - Member Bubble
private struct MemberBubble: View {
    let user: User
    let isHost: Bool
    
    var initials: String {
        let parts = user.name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        let combo = (first + last)
        return combo.isEmpty ? String(user.name.prefix(2)).uppercased() : combo.uppercased()
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isHost ? Color.yellow.opacity(0.3) : Color.snapDishBlue.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Text(initials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(isHost ? .yellow : Color.snapDishBlue)
                
                if isHost {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: 56, height: 56)
                }
            }
            
            Text(user.name.isEmpty ? "User" : user.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

#Preview {
}


