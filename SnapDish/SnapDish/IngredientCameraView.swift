import SwiftUI
import PhotosUI

struct IngredientCameraView: View {
    let api: APIClient
    let lobbyId: String
    // Callback mit erkannten Zutaten zurück an den Aufrufer
    let onIngredients: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selection: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var uiImage: UIImage?

    @State private var isExtracting = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let img = uiImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary))
                } else {
                    Text("Wähle ein Foto oder nimm eines mit der Kamera auf.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                    Label("Foto aufnehmen/auswählen", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    Task { await extract() }
                } label: {
                    if isExtracting {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Erkenne Zutaten…")
                        }
                    } else {
                        Text("Zutaten erkennen")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isExtracting || imageData == nil)

                if let err = errorText {
                    Text(err).foregroundStyle(.red).font(.footnote)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Zutaten scannen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schließen") { dismiss() }
                }
            }
            .onChange(of: selection) { _, newItem in
                Task { await loadSelected(newItem) }
            }
        }
    }

    private func loadSelected(_ item: PhotosPickerItem?) async {
        errorText = nil
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                imageData = data
                uiImage = UIImage(data: data)
            } else {
                errorText = "Konnte Bilddaten nicht laden."
            }
        } catch {
            errorText = "Fehler beim Laden des Bildes: \(error.localizedDescription)"
        }
    }

    private func extract() async {
        errorText = nil
        guard let data = imageData else { return }
        isExtracting = true
        defer { isExtracting = false }
        do {
            let ingredients = try await api.extractIngredientsFromImage(lobbyId: lobbyId, imageData: data)
            onIngredients(ingredients)
            dismiss()
        } catch {
            errorText = "Erkennung fehlgeschlagen: \(error.localizedDescription)"
        }
    }
}
