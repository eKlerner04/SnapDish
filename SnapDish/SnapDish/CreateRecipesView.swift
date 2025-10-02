import SwiftUI
import UIKit
import Combine

// MARK: - UIKit-ImagePicker für Kamera
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .camera
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage?) -> Void

        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            completion(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Notification Helper
extension Notification.Name {
    static let recipesUpdated = Notification.Name("recipesUpdated")
}

// MARK: - Main View
struct CreateRecipesView: View {
    let api: APIClient
    let lobby: Lobby
    let host: User

    @State private var ingredientInput: String = ""
    @State private var ingredients: [String] = []
    @State private var generated: [Recipe] = []

    @State private var isGenerating = false
    @State private var isSyncing = false
    @State private var isRecognizing = false

    @State private var errorText: String?
    @State private var infoText: String?

    @State private var showImagePicker = false
    @State private var capturedImages: [UIImage] = []
    @State private var isRefreshing = false
    
    // Computed property für Button-Subtitle
    private var buttonSubtitle: String {
        if ingredients.isEmpty {
            return "Zuerst Zutaten hinzufügen"
        } else if ingredients.count < 4 {
            return "Mindestens 4 Zutaten erforderlich (\(ingredients.count)/4)"
        } else {
            return "Aus \(ingredients.count) Zutaten"
        }
    }

    private var imagePickerView: some View {
        ImagePicker(
            sourceType: .camera,
            completion: { image in
                if let image = image {
                    if capturedImages.count < 3 {
                        capturedImages.append(image)
                    }
                }
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                heroSection
                lobbyInfoCard
                ingredientInputSection
                ingredientsChipsSection
                actionButtons
                generatedRecipesSection
                errorSection
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 20)
        }
        .refreshable {
            await refreshIngredients()
        }
        .navigationTitle("Rezepte erstellen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Rezepte erstellen")
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
                    Task { await refreshIngredients() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.snapDishOrange)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(
                            isRefreshing 
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .easeOut(duration: 0.3),
                            value: isRefreshing
                        )
                }
                .disabled(isRefreshing)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            imagePickerView
        }
        .snapDishBackground()
        .task {
            await loadIngredients()
        }
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            Task { await refreshIngredients(silent: true) }
        }
    }

    // MARK: - View Components
    
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 12) {

            Text("Lass uns etwas Neues kochen!")
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
            
            Text("Sammle Zutaten und lass die AI zaubern")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var lobbyInfoCard: some View {
        VStack(spacing: 0) {
            // Lobby Code
            VStack(spacing: 8) {
                Text("LOBBY-CODE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary.opacity(0.5))
                
                HStack(spacing: 12) {                    
                    Text(lobby.code)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color.snapDishOrange.opacity(0.06))
            
            Divider()
            
            // Info Text
            Text("Diese Zutatenliste wird mit allen Mitgliedern geteilt")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.snapDishOrange.opacity(0.2), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var ingredientInputSection: some View {
        VStack(spacing: 16) {
            Text("Zutaten hinzufügen")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                TextField("z.B. Tomate, Mozzarella, Basilikum", text: $ingredientInput)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .font(.body)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white) // Vollständig opak
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.snapDishOrange.opacity(0.4), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                
                Button {
                    Task { await addIngredientFromInput() }
                } label: {
                    Image("zutatenAdd")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                }
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 56, height: 56)
                )
                .overlay(
                    Circle()
                        .stroke(Color.snapDishOrange.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
                .buttonStyle(.plain)
                .disabled(ingredientInputTrimmed.isEmpty)
                .opacity(ingredientInputTrimmed.isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var ingredientsChipsSection: some View {
        if !ingredients.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Deine Zutaten (\(ingredients.count))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary)
                    
                    // Warnung bei weniger als 4 Zutaten
                    if ingredients.count < 4 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("Min. 4 benötigt")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                    
                    Spacer()
                    
                    Button {
                        Task { await clearIngredients() }
                    } label: {
                        Text("Alle löschen")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Color.white.opacity(0.5))
                            )
                    }
                }
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 8)
                ], spacing: 8) {
                    ForEach(ingredients, id: \.self) { ingredient in
                        IngredientChip(
                            text: ingredient,
                            onDelete: {
                                Task { await removeIngredient(ingredient) }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Foto aufnehmen Button
            Button {
                showImagePicker = true
            } label: {
                RecipeActionCard(
                    imageName: "camera",
                    title: "Foto aufnehmen",
                    subtitle: capturedImages.isEmpty ? "Zutaten fotografieren" : "\(capturedImages.count) Foto(s) aufgenommen",
                    accentColor: Color.snapDishBlue,
                    isLoading: isRecognizing
                )
            }
            .buttonStyle(.plain)
            
            // Zutaten aus Bildern erkennen Button (nur anzeigen wenn Bilder vorhanden)
            if !capturedImages.isEmpty {
                Button {
                    Task { await recognizeIngredientsFromImages() }
                } label: {
                    RecipeActionCard(
                        imageName: "zutatenHinzufügen",
                        title: "Zutaten erkennen",
                        subtitle: "Aus \(capturedImages.count) Foto(s) Zutaten extrahieren",
                        accentColor: Color.snapDishGreen,
                        isLoading: isRecognizing
                    )
                }
                .buttonStyle(.plain)
            }
            
            // AI Rezepte generieren Button
            Button {
                Task { await generate() }
            } label: {
                RecipeActionCard(
                    imageName: "recipe", // Kochbuch-Icon
                    title: "AI-Rezepte generieren",
                    subtitle: buttonSubtitle,
                    accentColor: Color.snapDishOrange,
                    isLoading: isGenerating
                )
            }
            .buttonStyle(.plain)
            .disabled(ingredients.count < 4)
            .opacity(ingredients.count < 4 ? 0.6 : 1.0)
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var generatedRecipesSection: some View {
        if !generated.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Generierte Rezepte (\(generated.count))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
                
                ForEach(generated) { recipe in
                    RecipePreviewCard(recipe: recipe)
                }
            }
            .padding(.horizontal, 20)
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
        
        if let info = infoText {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.snapDishBlue)
                Text(info)
                    .font(.caption)
                    .foregroundStyle(Color.snapDishBlue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.snapDishBlue.opacity(0.1))
            )
            .padding(.horizontal, 20)
        }
    }

    private var ingredientInputTrimmed: String {
        ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Server Sync

    private func loadIngredients() async {
        errorText = nil
        infoText = nil
        isSyncing = true
        defer { isSyncing = false }
        do {
            let list = try await api.fetchLobbyIngredients(lobbyId: lobby.id)
            ingredients = list
        } catch {
            errorText = "Zutaten konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }
    
    private func refreshIngredients(silent: Bool = false) async {
        if !silent {
            isRefreshing = true
        }
        defer { 
            if !silent {
                isRefreshing = false
            }
        }
        
        do {
            let list = try await api.fetchLobbyIngredients(lobbyId: lobby.id)
            let oldCount = ingredients.count
            ingredients = list
            
            if !silent && list.count != oldCount {
                infoText = "Zutatenliste aktualisiert (\(list.count) Zutaten)"
            }
        } catch {
            if !silent {
                errorText = "Aktualisierung fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private func addIngredientFromInput() async {
        let parts = ingredientInputTrimmed
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else { return }
        ingredientInput = ""

        await addIngredients(parts)
    }

    private func addIngredients(_ list: [String]) async {
        errorText = nil
        infoText = nil
        isSyncing = true
        defer { isSyncing = false }
        do {
            let updated = try await api.addLobbyIngredients(lobbyId: lobby.id, ingredients: list)
            ingredients = updated
            infoText = "Zutatenliste aktualisiert (\(list.count) hinzugefügt)."
        } catch {
            errorText = "Zutaten konnten nicht hinzugefügt werden: \(error.localizedDescription)"
        }
    }

    private func removeIngredient(_ ing: String) async {
        errorText = nil
        infoText = nil
        isSyncing = true
        defer { isSyncing = false }
        do {
            let updated = try await api.deleteLobbyIngredients(lobbyId: lobby.id, ingredients: [ing])
            ingredients = updated
            infoText = "\"\(ing)\" entfernt."
        } catch {
            errorText = "Zutat konnte nicht entfernt werden: \(error.localizedDescription)"
        }
    }
    
    private func clearIngredients() async {
        errorText = nil
        infoText = nil
        isSyncing = true
        defer { isSyncing = false }
        do {
            let updated = try await api.deleteLobbyIngredients(lobbyId: lobby.id, ingredients: ingredients)
            ingredients = updated
            infoText = "Alle Zutaten entfernt."
        } catch {
            errorText = "Zutaten konnten nicht gelöscht werden: \(error.localizedDescription)"
        }
    }

    // MARK: - AI

    private func generate() async {
        errorText = nil
        infoText = nil
        isGenerating = true
        defer { isGenerating = false }

        do {
            // Sicherheits-Refresh, falls andere Mitglieder parallel editiert haben
            let latest = try await api.fetchLobbyIngredients(lobbyId: lobby.id)
            ingredients = latest

            // Prüfe Mindestanzahl von Zutaten
            if ingredients.count < 4 {
                errorText = "Mindestens 4 Zutaten erforderlich für Rezeptgenerierung. Aktuell: \(ingredients.count) Zutaten."
                return
            }

            let res = try await api.generateRecipes(lobbyId: lobby.id, ingredients: latest)
            generated = res
            infoText = "8 Rezepte generiert und gespeichert."
            NotificationCenter.default.post(name: .recipesUpdated, object: nil)
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func recognizeIngredientsFromImages() async {
        errorText = nil
        infoText = nil
        isRecognizing = true
        defer { isRecognizing = false }

        var allDetected: [String] = []
        do {
            for img in capturedImages {
                guard let data = img.jpegData(compressionQuality: 0.8) else { continue }
                let detected = try await api.extractIngredientsFromImage(lobbyId: lobby.id, imageData: data)
                allDetected.append(contentsOf: detected)
            }

            // Merge serverseitig (dedupe übernimmt der Server)
            if !allDetected.isEmpty {
                await addIngredients(allDetected)
            }
            infoText = "\(allDetected.count) Zutaten von \(capturedImages.count) Fotos erkannt."
            capturedImages = []
        } catch {
            errorText = "Zutaten konnten nicht erkannt werden: \(error.localizedDescription)"
        }
    }
}

// MARK: - Ingredient Chip
private struct IngredientChip: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white) // Vollständig opak
        )
        .overlay(
            Capsule()
                .stroke(Color.snapDishOrange.opacity(0.5), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Recipe Action Card
private struct RecipeActionCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let isLoading: Bool
    
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
            
            if isLoading {
                ProgressView()
                    .tint(accentColor)
            } else {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(accentColor)
            }
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

// MARK: - Recipe Preview Card
private struct RecipePreviewCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recipe.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("Neu")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.snapDishOrange)
                    )
            }
            
            Text(recipe.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            if !recipe.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Zutaten (\(recipe.ingredients.count))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(recipe.ingredients.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            if !recipe.steps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zubereitung (\(recipe.steps.count) Schritte)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("\(idx + 1).")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(step)
                                        .font(.caption2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 120) // Begrenzte Höhe mit Scroll
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.snapDishOrange.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
    }
}

#Preview {
    CreateRecipesView(api: APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!),
                      lobby: Lobby(id: "demo", hostId: "host", code: "Iskto8", createdAt: ""),
                      host: User(id: "host", name: "Emil", createdAt: ""))
}
