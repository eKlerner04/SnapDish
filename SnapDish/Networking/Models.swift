import Foundation

struct Lobby: Codable, Identifiable {
    let id: String
    let hostId: String
    let code: String
    let createdAt: String
}

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let createdAt: String
}

struct Recipe: Codable, Identifiable {
    let id: String
    let lobbyId: String
    let title: String
    let description: String
    let createdAt: String
    let imageUrl: String?
    let ingredients: [String]
    let steps: [String]
}

struct Vote: Codable {
    let userId: String
    let recipeId: String
    let direction: String
}

struct CreateLobbyResponse: Codable {
    let message: String
    let lobby: Lobby
    let host: User
}

struct JoinLobbyResponse: Codable {
    let message: String
    let lobby: Lobby
    let user: User
}

struct ImproveEmailResponse: Codable {
    let email_improved: String?
    let error: String?
}


