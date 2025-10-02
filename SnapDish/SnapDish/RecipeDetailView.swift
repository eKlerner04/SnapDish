import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        List {
            Section("Beschreibung") {
                Text(recipe.description)
            }
            Section("Zutaten") {
                ForEach(recipe.ingredients, id: \.self) { ing in
                    Text(ing)
                }
            }
            Section("Zubereitung") {
                ForEach(recipe.steps.indices, id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(idx + 1). \(recipe.steps[idx])")
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(recipe.title)
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(
        id: "1",
        lobbyId: "1",
        title: "Spaghetti Carbonara",
        description: "Ein klassisches italienisches Gericht.",
        createdAt: "2025-09-30T16:00:00Z",
        imageUrl: nil,
        ingredients: [
            "200g Spaghetti",
            "100g Pancetta",
            "2 Eier",
            "50g Parmesan",
            "Salz, Pfeffer"
        ],
        steps: [
            "Spaghetti kochen.",
            "Pancetta anbraten.",
            "Eier und Parmesan verrühren.",
            "Alles vermengen und würzen."
        ]
    ))
}
