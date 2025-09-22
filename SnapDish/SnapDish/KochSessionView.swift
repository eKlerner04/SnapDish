import SwiftUI
import Combine

struct KochSessionView: View {
    let api: APIClient
    let lobby: Lobby
    let host: User
    // Wer schaut gerade die Session an? (Host oder Mitglied)
    let currentUser: User?

    @State private var members: [User] = []
    @State private var isLoadingMembers = false
    @State private var errorText: String?

    // Rezepte-Count (nur Anzeigezweck)
    @State private var recipesCount: Int = 0
    @State private var isLoadingRecipes = false
    @State private var recipesError: String?

    // Navigation
    @State private var goToCreateRecipes = false
    @State private var goToVoting = false

    // Notification-Listener
    @State private var recipesUpdatedCancellable: AnyCancellable?

    var body: some View {
        List {
            Section("Lobby") {
                LabeledContent("Code", value: lobby.code)
                LabeledContent("Lobby-ID", value: lobby.id)
                LabeledContent("Host-ID", value: lobby.hostId)
            }

            Section("Host") {
                VStack(alignment: .leading, spacing: 2) {
                    Text(host.name.isEmpty ? "Host" : host.name)
                    Text(host.id).font(.caption).foregroundStyle(.secondary)
                }
            }

            if let me = currentUser {
                Section("Du") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(me.name)
                        Text(me.id).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Aktionen") {
                if isCurrentUserHost {
                    Button {
                        goToCreateRecipes = true
                    } label: {
                        Text("Rezepte erstellen")
                    }
                } else {
                    Text("Bitte warten, bis der Host Rezepte erstellt hat.")
                        .foregroundStyle(.secondary)
                }

                // Immer freigegeben: LeftRightView lädt selbst und zeigt leeren Zustand, wenn keine Rezepte da sind.
                Button {
                    goToVoting = true
                } label: {
                    Text("Rezepte swipen/voten")
                }
            }

            Section(header: Text("Mitglieder")) {
                if isLoadingMembers && members.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Lade Mitglieder…")
                    }
                } else if let err = errorText, members.isEmpty {
                    Text(err).foregroundStyle(.red)
                } else if members.isEmpty {
                    Text("Noch keine Mitglieder beigetreten")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(members, id: \.id) { member in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name)
                            Text(member.id).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Rezepte") {
                if isLoadingRecipes {
                    HStack {
                        ProgressView()
                        Text("Prüfe Rezepte…")
                    }
                } else if let rerr = recipesError {
                    Text(rerr).foregroundStyle(.red)
                } else {
                    Text("Anzahl Rezepte: \(recipesCount)")
                        .foregroundStyle(recipesCount > 0 ? .primary : .secondary)
                }
            }
        }
        .navigationTitle("Koch-Session")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await reloadAll() }
                } label: {
                    if isLoadingMembers || isLoadingRecipes {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .accessibilityLabel("Aktualisieren")
            }
        }
        .onAppear {
            // Sicherstellen, dass wir nach ResultView nicht erneut in LeftRightView springen
            goToVoting = false

            // Notification abonnieren: wenn Rezepte erstellt wurden → Count neu laden
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
            // Im Preview keine Netzwerk-Calls starten
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                await reloadAll()
            }
        }
        .refreshable {
            await reloadAll()
        }
        .background(
            Group {
                // Navigation: Rezepte erstellen (nur Host)
                NavigationLink(
                    destination: destinationCreateRecipes,
                    isActive: $goToCreateRecipes,
                    label: { EmptyView() }
                )
                .hidden()

                // Navigation: Voten (alle)
                NavigationLink(
                    destination: destinationVoting,
                    isActive: $goToVoting,
                    label: { EmptyView() }
                )
                .hidden()
            }
        )
    }

    private var isCurrentUserHost: Bool {
        guard let me = currentUser else { return false }
        return me.id == lobby.hostId
    }

    @ViewBuilder
    private var destinationCreateRecipes: some View {
        if isCurrentUserHost {
            CreateRecipesView(api: api, lobby: lobby, host: host)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var destinationVoting: some View {
        if let me = currentUser {
            LeftRightView(api: api, lobby: lobby, currentUser: me)
        } else {
            Text("Unbekannter Nutzer – bitte erneut beitreten.")
        }
    }

    // MARK: - Loading

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
            // Host nicht doppelt anzeigen
            fetched.removeAll { $0.id == host.id }
            members = fetched
        } catch {
            errorText = "Mitglieder konnten nicht geladen werden: \(error.localizedDescription)"
            print("fetchLobbyMembers error:", error)
        }
    }

    @MainActor
    private func loadRecipesCount() async {
        recipesError = nil
        isLoadingRecipes = true
        defer { isLoadingRecipes = false }
        do {
            let list = try await api.fetchRecipes(lobbyId: lobby.id)
            recipesCount = list.count
        } catch {
            recipesError = "Rezepte konnten nicht geladen werden: \(error.localizedDescription)"
            recipesCount = 0
        }
    }
}

#Preview {
    let api = APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!)
    let lobby = Lobby(id: "261e27c7-2021-4046-8815-834d8e8828bd",
                      hostId: "34ee8891-4f8e-42ed-97e0-fded51d49c8e",
                      code: "pm683e",
                      createdAt: "2025-09-20T10:05:57.712Z")
    let host = User(id: lobby.hostId, name: "Emil", createdAt: "2025-09-20T10:05:57.698Z")
    let me = host // Host als aktueller Nutzer
    return NavigationStack {
        KochSessionView(api: api, lobby: lobby, host: host, currentUser: me)
    }
}
