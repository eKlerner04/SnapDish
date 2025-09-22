import SwiftUI

struct LeftRightView: View {
    let api: APIClient
    let lobby: Lobby
    let currentUser: User

    @State private var recipes: [Recipe] = []
    @State private var index: Int = 0

    @State private var isLoading = false
    @State private var isVoting = false
    @State private var errorText: String?
    @State private var infoText: String?

    // Navigation zur ResultView
    @State private var goToResults = false

    var body: some View {
        VStack(spacing: 16) {
            if isLoading && recipes.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Lade Rezepte…")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorText, recipes.isEmpty {
                VStack(spacing: 12) {
                    Text("Fehler").font(.headline)
                    Text(err).multilineTextAlignment(.center)
                    Button("Erneut laden") {
                        Task { await loadRecipes() }
                    }
                }
                .padding()
            } else if recipes.isEmpty {
                VStack(spacing: 12) {
                    Text("Keine Rezepte verfügbar")
                        .foregroundStyle(.secondary)
                    Button("Aktualisieren") {
                        Task { await loadRecipes() }
                    }
                }
                .padding()
            } else if index >= recipes.count {
                // Ende erreicht
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Du hast alle Rezepte bewertet.")
                        .font(.headline)
                    if let info = infoText {
                        Text(info).foregroundStyle(.secondary)
                    }
                    Button("Ergebnis ansehen") {
                        goToResults = true
                    }
                    Button("Nochmal laden") {
                        Task {
                            index = 0
                            await loadRecipes()
                        }
                    }
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    Text("Rezept \(index + 1) von \(recipes.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom)

                    // Voll greifbare Tinder-Style Swipe-Card
                    RecipeSwipeCard(recipe: recipes[index], disabled: isVoting) { direction in
                        Task { await vote(direction: direction, recipe: recipes[index]) }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 420)

                    if let err = errorText {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
                .padding(.horizontal)
                .animation(.default, value: index)
            }
        }
        .navigationTitle("Rezepte voten")
        .task {
            await loadRecipes()
        }
        .refreshable {
            await loadRecipes()
        }
        .background(
            NavigationLink(
                destination: ResultView(api: api, lobby: lobby),
                isActive: $goToResults,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    @MainActor
    private func loadRecipes() async {
        errorText = nil
        infoText = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let list = try await api.fetchRecipes(lobbyId: lobby.id)
            recipes = list
            index = 0
            if list.isEmpty {
                infoText = "Noch keine Rezepte – der Host kann welche erstellen."
            }
        } catch {
            errorText = "Rezepte konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func vote(direction: String, recipe: Recipe) async {
        errorText = nil
        isVoting = true
        defer { isVoting = false }

        do {
            _ = try await api.sendVote(lobbyId: lobby.id, userId: currentUser.id, recipeId: recipe.id, direction: direction)
            // Zum nächsten Rezept
            index += 1
            if index >= recipes.count {
                infoText = "Danke! Deine Votes wurden gespeichert."
                try? await Task.sleep(nanoseconds: 600_000_000)
                goToResults = true
            }
        } catch {
            errorText = "Vote fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}

// MARK: - Greifbare SwipeCard mit Farbhintergrund und Symbolen
struct RecipeSwipeCard: View {
    let recipe: Recipe
    var disabled: Bool = false
    var onVote: (String) -> Void

    @State private var offset: CGSize = .zero
    @GestureState private var isPressed = false

    private var swipeColor: Color {
        if offset.width > 0 {
            return Color.green.opacity(Double(min(abs(offset.width / 180), 0.6)))
        } else if offset.width < 0 {
            return Color.red.opacity(Double(min(abs(offset.width / 180), 0.6)))
        } else {
            return Color(.systemBackground)
        }
    }

    private var overlaySymbol: some View {
        Group {
            if offset.width > 50 {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.green)
                        .opacity(Double(min(abs(offset.width / 120), 0.9)))
                    Spacer()
                }
                .padding()
            } else if offset.width < -50 {
                HStack {
                    Spacer()
                    Image(systemName: "hand.thumbsdown.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.red)
                        .opacity(Double(min(abs(offset.width / 120), 0.9)))
                }
                .padding()
            }
        }
    }

    var body: some View {
        ZStack {
            // Farbhintergrund
            RoundedRectangle(cornerRadius: 24)
                .fill(swipeColor)
                .shadow(radius: 8)

            VStack(alignment: .leading, spacing: 12) {
                Text(recipe.title)
                    .font(.title2)
                    .bold()
                if !recipe.description.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        Text(recipe.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 120, maxHeight: 220)
                    .allowsHitTesting(false) // <-- GANZE Karte bleibt dragbar!
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
            .overlay(
                overlaySymbol
            )
            .scaleEffect(isPressed ? 1.04 : 1.0)
        }
        .contentShape(Rectangle()) // GANZE Karte, inkl. Text, dragbar!
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            DragGesture(minimumDistance: 8)
                .updating($isPressed) { _, pressed, _ in pressed = true }
                .onChanged { value in
                    if !disabled {
                        offset = value.translation
                    }
                }
                .onEnded { value in
                    let dragThreshold: CGFloat = 120
                    if offset.width > dragThreshold {
                        withAnimation { offset = CGSize(width: 1000, height: 0) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            onVote("right")
                            offset = .zero
                        }
                    } else if offset.width < -dragThreshold {
                        withAnimation { offset = CGSize(width: -1000, height: 0) }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            onVote("left")
                            offset = .zero
                        }
                    } else {
                        withAnimation { offset = .zero }
                    }
                }
        )
        .animation(.spring(), value: offset)
        .allowsHitTesting(!disabled)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(recipe.title)
        .accessibilityHint("Nach rechts für Daumen hoch, nach links für Daumen runter")
    }
}

#Preview {
    let api = APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!)
    let lobby = Lobby(id: "261e27c7-2021-4046-8815-834d8e8828bd",
                      hostId: "34ee8891-4f8e-42ed-97e0-fded51d49c8e",
                      code: "pm683e",
                      createdAt: "2025-09-20T10:05:57.712Z")
    let me = User(id: "ab12cd34-5678-90ef-gh12-ijk345lmno67", name: "Tom", createdAt: "2025-09-20T10:07:22.001Z")
    return NavigationStack {
        LeftRightView(api: api, lobby: lobby, currentUser: me)
    }
}
