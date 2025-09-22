import SwiftUI

struct CreateLobbyView: View {
    let api: APIClient

    @State private var hostName: String = "Emil"
    @State private var response: CreateLobbyResponse?
    @State private var isLoading = false
    @State private var errorText: String?

    // Navigation in KochSessionView
    @State private var startSession = false

    var body: some View {
        VStack {
            Form {
                Section("Host") {
                    TextField("Name", text: $hostName)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Button {
                        Task { await create() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Lobby erstellen")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || hostName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let res = response {
                    Section("Ergebnis") {
                        Text(res.message)
                        LabeledContent("Lobby-ID", value: res.lobby.id)
                        LabeledContent("Code", value: res.lobby.code)
                        LabeledContent("Host-ID", value: res.host.id)
                        LabeledContent("Host-Name", value: res.host.name)
                    }
                }

                if let err = errorText {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }

            // Button unten: erscheint erst, wenn Lobby erstellt wurde
            if response != nil {
                VStack(spacing: 12) {
                    Button {
                        startSession = true
                    } label: {
                        Text("KochLobby starten")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Lobby erstellen")
        // NavigationDestination zur KochSessionView
        .background(
            NavigationLink(
                destination: destinationView,
                isActive: $startSession,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    @ViewBuilder
    private var destinationView: some View {
        if let res = response {
            // Host ist der aktuelle Nutzer
            KochSessionView(api: api, lobby: res.lobby, host: res.host, currentUser: res.host)
        } else {
            EmptyView()
        }
    }

    private func create() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }
        do {
            response = try await api.createLobby(hostName: hostName)
        } catch {
            errorText = error.localizedDescription
        }
    }
}

#Preview {
    CreateLobbyView(api: APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!))
}
