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
        ScrollView {
            VStack(spacing: 16) {

                // MARK: - Header / Lobby-Info
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Lobby")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            // Code exakt anzeigen, nicht uppercased
                            StatusPill(
                                icon: "fork.knife",
                                text: "Code: \(lobby.code)"
                            )
                            .accessibilityLabel("Lobby Code \(lobby.code)")
                        }

                        HStack(spacing: 12) {
                            Label(host.name.isEmpty ? "Host" : host.name, systemImage: "crown.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.yellow, .primary)

                            if let me = currentUser {
                                Label(me.name, systemImage: "person.fill")
                                    .labelStyle(.titleAndIcon)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .lineLimit(1)

                        Text("Lobby-ID: \(lobby.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                // MARK: - Hauptaktionen (für alle)
                VStack(spacing: 12) {
                    Button {
                        goToCreateRecipes = true
                    } label: {
                        BigActionButtonLabel(
                            icon: "wand.and.stars",
                            title: "Rezepte erstellen",
                            subtitle: "Zutaten sammeln und AI starten – für alle"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .accessibilityIdentifier("createRecipesButton")

                    Button {
                        goToVoting = true
                    } label: {
                        BigActionButtonLabel(
                            icon: "hand.thumbsup.fill",
                            title: "Rezepte swipen/voten",
                            subtitle: recipesCount > 0 ? "Es gibt \(recipesCount) Rezepte" : "Noch keine Rezepte – erst erstellen"
                        )
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .accessibilityIdentifier("votingButton")
                }

                // MARK: - Status-Übersicht
                HStack(spacing: 12) {
                    StatCard(
                        icon: "list.bullet.rectangle",
                        title: "Rezepte",
                        value: "\(recipesCount)",
                        tint: recipesCount > 0 ? .green : .secondary
                    )
                    .frame(maxWidth: .infinity)

                    StatCard(
                        icon: "person.2.fill",
                        title: "Mitglieder",
                        value: "\(members.count + 1)", // + Host
                        tint: .blue
                    )
                    .frame(maxWidth: .infinity)
                }

                if isLoadingRecipes || isLoadingMembers {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Aktualisiere…")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                if let err = errorText {
                    InlineError(text: err)
                }
                if let rerr = recipesError {
                    InlineError(text: rerr)
                }

                // MARK: - Mitglieder
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Mitglieder")
                                .font(.headline)
                            Spacer()
                            Button {
                                Task { await reloadAll() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .accessibilityLabel("Mitglieder aktualisieren")
                        }

                        if isLoadingMembers && members.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Lade Mitglieder…")
                                    .foregroundStyle(.secondary)
                            }
                        } else if let err = errorText, members.isEmpty {
                            Text(err)
                                .foregroundStyle(.red)
                                .font(.subheadline)
                        } else if members.isEmpty {
                            Text("Noch keine Mitglieder beigetreten.")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // Host zuerst
                                    MemberChip(user: host, isHost: true)
                                    ForEach(members, id: \.id) { member in
                                        MemberChip(user: member, isHost: false)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal)
            .padding(.top, 12)
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
                // Navigation: Rezepte erstellen (jetzt für alle)
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
        CreateRecipesView(api: api, lobby: lobby, host: host)
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

// MARK: - Bausteine

private struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
    }
}

private struct StatusPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .fontDesign(.monospaced) // bessere Lesbarkeit bei Codes
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color(.tertiarySystemFill))
        )
    }
}

private struct BigActionButtonLabel: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
            Text(title)
                .font(.headline)
                .bold()
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(tint)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
    }
}

private struct MemberChip: View {
    let user: User
    var isHost: Bool

    var initials: String {
        let parts = user.name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        let combo = (first + last)
        return combo.isEmpty ? String(user.name.prefix(2)) : combo
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isHost ? Color.yellow.opacity(0.25) : Color.blue.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text(initials.uppercased())
                    .font(.caption)
                    .bold()
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.name.isEmpty ? "Mitglied" : user.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    if isHost {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                Text(user.id)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Color(.tertiarySystemFill))
        )
    }
}

private struct InlineError: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(text)
                .foregroundStyle(.red)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
}

#Preview {
    let api = APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!)
    let lobby = Lobby(id: "261e27c7-2021-4046-8815-834d8e8828bd",
                      hostId: "34ee8891-4f8e-42ed-97e0-fded51d49c8e",
                      code: "Iskto8",
                      createdAt: "2025-09-20T10:05:57.712Z")
    let host = User(id: lobby.hostId, name: "Emil", createdAt: "2025-09-20T10:05:57.698Z")
    let me = host
    return NavigationStack {
        KochSessionView(api: api, lobby: lobby, host: host, currentUser: me)
    }
}
