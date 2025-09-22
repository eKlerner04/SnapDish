//
//  ResultView.swift
//  SnapDish
//
//  Created by Emil Klerner on 20.09.25.
//

import SwiftUI

struct ResultView: View {
    let api: APIClient
    let lobby: Lobby

    @State private var votes: [Vote] = []
    @State private var recipes: [Recipe] = []

    @State private var isLoading = false
    @State private var errorText: String?

    var body: some View {
        VStack {
            if isLoading && votes.isEmpty && recipes.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Lade Ergebnisse…")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorText {
                VStack(spacing: 12) {
                    Text("Fehler").font(.headline)
                    Text(err).multilineTextAlignment(.center)
                    Button("Erneut laden") {
                        Task { await loadData() }
                    }
                }
                .padding()
            } else {
                let tally = tallyVotes(votes: votes)
                let sorted = tally.sorted { $0.value > $1.value }
                let winnerId = sorted.first?.key
                let recipeById = Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, $0) })

                List {
                    if let winnerId, let winner = recipeById[winnerId] {
                        Section("Gewinner") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(winner.title)
                                    .font(.title3)
                                    .bold()
                                if !winner.description.isEmpty {
                                    Text(winner.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Stimmen: \(tally[winnerId] ?? 0)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Section("Gewinner") {
                            Text("Noch kein eindeutiger Gewinner")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Alle Ergebnisse") {
                        if sorted.isEmpty {
                            Text("Noch keine Votes vorhanden.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sorted, id: \.key) { pair in
                                let rid = pair.key
                                let count = pair.value
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipeById[rid]?.title ?? rid)
                                        .font(.headline)
                                    Text("Stimmen: \(count)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ergebnis")
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
    }

    // Zählt aktuell nur "right" als Zustimmung
    private func tallyVotes(votes: [Vote]) -> [String: Int] {
        var dict: [String: Int] = [:]
        for v in votes {
            guard v.direction.lowercased() == "right" else { continue }
            dict[v.recipeId, default: 0] += 1
        }
        return dict
    }

    @MainActor
    private func loadData() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }
        do {
            async let votesTask = api.fetchResults(lobbyId: lobby.id)
            async let recipesTask = api.fetchRecipes(lobbyId: lobby.id)
            let (allVotes, allRecipes) = try await (votesTask, recipesTask)
            votes = allVotes
            recipes = allRecipes
        } catch {
            errorText = "Ergebnisse konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let api = APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!)
    let lobby = Lobby(id: "261e27c7-2021-4046-8815-834d8e8828bd",
                      hostId: "34ee8891-4f8e-42ed-97e0-fded51d49c8e",
                      code: "pm683e",
                      createdAt: "2025-09-20T10:05:57.712Z")
    return NavigationStack {
        ResultView(api: api, lobby: lobby)
    }
}
