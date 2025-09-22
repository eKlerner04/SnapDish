import SwiftUI
import UIKit

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
    @State private var errorText: String?
    @State private var infoText: String?

    @State private var showImagePicker = false
    @State private var capturedImages: [UIImage] = []
    @State private var isRecognizing = false

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
        VStack {
            Form {
                Section("Lobby") {
                    LabeledContent("Code", value: lobby.code)
                    LabeledContent("Lobby-ID", value: lobby.id)
                }

                Section("Zutaten hinzufügen") {
                    HStack {
                        TextField("z. B. Tomate, Mozzarella, Basilikum", text: $ingredientInput)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        Button {
                            addIngredient()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(ingredientInputTrimmed.isEmpty)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            if capturedImages.count < 3 {
                                showImagePicker = true
                            }
                        } label: {
                            Label("Foto aufnehmen", systemImage: "camera.fill")
                        }
                        .disabled(capturedImages.count >= 3)
                    }
                    .padding(.vertical, 4)

                    // Thumbnails aller aufgenommenen Bilder
                    if !capturedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(capturedImages.enumerated()), id: \.offset) { idx, img in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary, lineWidth: 1))
                                        Button {
                                            capturedImages.remove(at: idx)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .padding(2)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        Task { await recognizeIngredientsFromImages() }
                    } label: {
                        if isRecognizing {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Zutaten werden erkannt…")
                            }
                        } else {
                            Text("Zutaten erkennen (\(capturedImages.count))")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRecognizing || capturedImages.isEmpty)

                    if !ingredients.isEmpty {
                        ForEach(ingredients, id: \.self) { ing in
                            HStack {
                                Text(ing)
                                Spacer()
                                Button(role: .destructive) {
                                    removeIngredient(ing)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    } else {
                        Text("Füge Zutaten manuell hinzu oder nutze die Kamera.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        Task { await generate() }
                    } label: {
                        if isGenerating {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Generiere Rezepte…")
                            }
                        } else {
                            Text("Mit AI 8 Rezepte generieren")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating || ingredients.isEmpty)
                }

                if !generated.isEmpty {
                    Section("Generierte Rezepte") {
                        ForEach(generated) { r in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(r.title).font(.headline)
                                if !r.description.isEmpty {
                                    Text(r.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text(r.id).font(.caption2).foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                if let info = infoText {
                    Section { Text(info).foregroundStyle(.green) }
                }
                if let err = errorText {
                    Section { Text(err).foregroundStyle(.red) }
                }
            }
        }
        .navigationTitle("Rezepte erstellen (AI)")
        .sheet(isPresented: $showImagePicker) {
            imagePickerView
        }
    }

    private var ingredientInputTrimmed: String {
        ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addIngredient() {
        let parts = ingredientInputTrimmed
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        ingredients.append(contentsOf: parts)
        ingredients = Array(Set(ingredients)).sorted()
        ingredientInput = ""
    }

    private func removeIngredient(_ ing: String) {
        ingredients.removeAll { $0.caseInsensitiveCompare(ing) == .orderedSame }
    }

    private func generate() async {
        errorText = nil
        infoText = nil
        isGenerating = true
        defer { isGenerating = false }

        do {
            let res = try await api.generateRecipes(lobbyId: lobby.id, ingredients: ingredients)
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

        var allDetected: Set<String> = []
        do {
            for img in capturedImages {
                guard let data = img.jpegData(compressionQuality: 0.8) else { continue }
                let detected = try await api.extractIngredientsFromImage(lobbyId: lobby.id, imageData: data)
                allDetected.formUnion(detected.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            }
            ingredients = Array(Set(ingredients).union(allDetected)).sorted()
            infoText = "\(allDetected.count) Zutaten von \(capturedImages.count) Fotos erkannt."
            capturedImages = []
        } catch {
            errorText = "Zutaten konnten nicht erkannt werden: \(error.localizedDescription)"
        }
    }
}
