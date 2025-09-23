import Foundation

// MARK: - Models für bestehende Routen
struct HealthResponse: Codable { let status: String }

struct ImproveRequest: Codable {
    let email_body: String
}

struct ImproveResponse: Codable {
    let email_improved: String?
    let error: String?
}

// MARK: - Lobby/Recipe/Vote Models
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
}

struct Vote: Codable, Identifiable {
    let id: String
    let recipeId: String
    let userId: String
    let direction: String
    let createdAt: String
}

// MARK: - Request/Response DTOs
struct CreateLobbyRequest: Codable { let hostName: String }
struct CreateLobbyResponse: Codable {
    let message: String
    let lobby: Lobby
    let host: User
}

struct JoinLobbyRequest: Codable {
    let name: String
    let code: String
}
struct JoinLobbyResponse: Codable {
    let message: String
    let lobby: Lobby
    let user: User
}

struct RecipesResponse: Codable {
    let recipes: [Recipe]
}

struct VoteRequest: Codable {
    let userId: String
    let recipeId: String
    let direction: String
}
struct VoteResponse: Codable { let message: String }

struct ResultsResponse: Codable { let votes: [Vote] }

struct LobbyMembersResponse: Codable { let members: [User] }

// NEU: Generate Recipes DTOs
struct GenerateRecipesRequest: Codable { let ingredients: [String] }
struct GenerateRecipesResponse: Codable { let recipes: [Recipe] }

// NEU: Vision Ingredients DTOs
struct VisionIngredientsRequest: Codable { let imageBase64: String }
struct VisionIngredientsResponse: Codable { let ingredients: [String] }

// NEU: Shared Ingredients DTOs
struct IngredientsPayload: Codable { let ingredients: [String] }
struct IngredientsResponse: Codable { let ingredients: [String] }

// MARK: - API Client
struct APIClient {
    let baseURL: URL

    // GET /health
    func health() async throws -> HealthResponse {
        let url = baseURL.appendingPathComponent("health")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "GET /health")
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }

    // POST /api/example/improve
    func improveEmail(text: String) async throws -> ImproveResponse {
        let url = baseURL.appendingPathComponent("api/example/improve")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(ImproveRequest(email_body: text))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "POST /api/example/improve")
        return try JSONDecoder().decode(ImproveResponse.self, from: data)
    }

    // MARK: - Lobby API

    func createLobby(hostName: String) async throws -> CreateLobbyResponse {
        let url = baseURL.appendingPathComponent("api/lobby/create")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(CreateLobbyRequest(hostName: hostName))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "POST /api/lobby/create")
        return try JSONDecoder().decode(CreateLobbyResponse.self, from: data)
    }

    func joinLobby(name: String, code: String) async throws -> JoinLobbyResponse {
        let url = baseURL.appendingPathComponent("api/lobby/join")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(JoinLobbyRequest(name: name, code: code))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "POST /api/lobby/join")
        return try JSONDecoder().decode(JoinLobbyResponse.self, from: data)
    }

    func fetchRecipes(lobbyId: String) async throws -> [Recipe] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("recipes")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "GET /api/lobby/\(lobbyId)/recipes")
        return try JSONDecoder().decode(RecipesResponse.self, from: data).recipes
    }

    func sendVote(lobbyId: String, userId: String, recipeId: String, direction: String) async throws -> VoteResponse {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("vote")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(VoteRequest(userId: userId, recipeId: recipeId, direction: direction))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "POST /api/lobby/\(lobbyId)/vote")
        return try JSONDecoder().decode(VoteResponse.self, from: data)
    }

    func fetchResults(lobbyId: String) async throws -> [Vote] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("results")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "GET /api/lobby/\(lobbyId)/results")
        return try JSONDecoder().decode(ResultsResponse.self, from: data).votes
    }

    func fetchLobbyMembers(lobbyId: String) async throws -> [User] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("members")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "GET /api/lobby/\(lobbyId)/members")
        return try JSONDecoder().decode(LobbyMembersResponse.self, from: data).members
    }

    func generateRecipes(lobbyId: String, ingredients: [String]) async throws -> [Recipe] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("recipes")
            .appendingPathComponent("generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(GenerateRecipesRequest(ingredients: ingredients))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "POST /api/lobby/\(lobbyId)/recipes/generate")
        return try JSONDecoder().decode(GenerateRecipesResponse.self, from: data).recipes
    }

    // NEU: POST /api/lobby/:id/ingredients/vision
    func extractIngredientsFromImage(lobbyId: String, imageData: Data) async throws -> [String] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("ingredients")
            .appendingPathComponent("vision")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64 = imageData.base64EncodedString()
        let payload = VisionIngredientsRequest(imageBase64: base64)
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "POST /api/lobby/\(lobbyId)/ingredients/vision")
        return try JSONDecoder().decode(VisionIngredientsResponse.self, from: data).ingredients
    }

    // NEU: Shared Ingredients API

    // GET /api/lobby/:id/ingredients
    func fetchLobbyIngredients(lobbyId: String) async throws -> [String] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("ingredients")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "GET /api/lobby/\(lobbyId)/ingredients")
        return try JSONDecoder().decode(IngredientsResponse.self, from: data).ingredients
    }

    // POST /api/lobby/:id/ingredients (merge)
    func addLobbyIngredients(lobbyId: String, ingredients: [String]) async throws -> [String] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("ingredients")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(IngredientsPayload(ingredients: ingredients))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "POST /api/lobby/\(lobbyId)/ingredients")
        return try JSONDecoder().decode(IngredientsResponse.self, from: data).ingredients
    }

    // DELETE /api/lobby/:id/ingredients
    func deleteLobbyIngredients(lobbyId: String, ingredients: [String]) async throws -> [String] {
        let url = baseURL
            .appendingPathComponent("api/lobby")
            .appendingPathComponent(lobbyId)
            .appendingPathComponent("ingredients")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(IngredientsPayload(ingredients: ingredients))

        let (data, resp) = try await URLSession.shared.data(for: req)
        try ensureOK(resp: resp, data: data, context: "DELETE /api/lobby/\(lobbyId)/ingredients")
        return try JSONDecoder().decode(IngredientsResponse.self, from: data).ingredients
    }

    // MARK: - Helpers
    private func ensureOK(resp: URLResponse, data: Data, context: String) throws {
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "HTTP",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "\(context) → HTTP \((resp as? HTTPURLResponse)?.statusCode ?? -1): \(body)"])
        }
    }
}
