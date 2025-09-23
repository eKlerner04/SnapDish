import SwiftUI

struct JoinLobbyView: View {
    let api: APIClient

    @State private var name: String = ""
    @State private var code: String = ""
    @State private var response: JoinLobbyResponse?
    @State private var isLoading = false
    @State private var errorText: String?

    // Navigation in die Koch-Session
    @State private var goToSession = false

    var body: some View {
        VStack {
            Form {
                Section("Beitreten") {
                    TextField("Dein Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)

                    TextField("Lobby-Code", text: $code)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }

                Section {
                    Button {
                        Task { await join() }
                    } label: {
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Beitreten…")
                            }
                        } else {
                            Text("Beitreten")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || nameTrimmed.isEmpty || codeTrimmed.isEmpty)
                }

                if let res = response {
                    Section("Ergebnis") {
                        Text(res.message)
                        LabeledContent("Lobby-ID", value: res.lobby.id)
                        LabeledContent("Code", value: res.lobby.code)
                        LabeledContent("User-ID", value: res.user.id)
                        LabeledContent("Name", value: res.user.name)
                    }
                }

                if let err = errorText {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Lobby beitreten")
        // Unsichtbarer NavigationLink, der automatisch nach erfolgreichem Join aktiviert wird
        .background(
            NavigationLink(
                destination: destinationView,
                isActive: $goToSession,
                label: { EmptyView() }
            )
            .hidden()
        )
    }

    @ViewBuilder
    private var destinationView: some View {
        if let res = response {
            // Wir kennen den Host-User hier nicht, nur die hostId.
            // Für eine simple Lösung verwenden wir einen Platzhalter-Host.
            let hostPlaceholder = User(id: res.lobby.hostId, name: "Host", createdAt: "")
            KochSessionView(api: api, lobby: res.lobby, host: hostPlaceholder, currentUser: res.user)
        } else {
            EmptyView()
        }
    }

    private var nameTrimmed: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var codeTrimmed: String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func join() async {
        errorText = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let res = try await api.joinLobby(name: nameTrimmed, code: codeTrimmed)
            response = res
            goToSession = true
        } catch {
            errorText = error.localizedDescription
        }
    }
}

#Preview {
    JoinLobbyView(api: APIClient(baseURL: URL(string: "http://127.0.0.1:3000")!))
}
