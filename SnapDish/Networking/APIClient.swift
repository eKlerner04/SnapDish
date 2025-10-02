import Foundation

struct HealthResponse: Codable {
    let status: String
}

struct APIClient {
    let baseURL: URL

    func health() async throws -> HealthResponse {
        let url = baseURL.appendingPathComponent("health")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }

    // MARK: - Demo: Improve Email
    func improveEmail(text: String) async throws -> ImproveEmailResponse {
        let url = baseURL.appendingPathComponent("api/example/improve-email")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["text": text]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(ImproveEmailResponse.self, from: data)
    }

    // MARK: - Lobbies
    func createLobby(hostName: String) async throws -> CreateLobbyResponse {
        let url = baseURL.appendingPathComponent("api/lobby/create")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["hostName": hostName]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(CreateLobbyResponse.self, from: data)
    }

    func joinLobby(name: String, code: String) async throws -> JoinLobbyResponse {
        let url = baseURL.appendingPathComponent("api/lobby/join")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["name": name, "code": code]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(JoinLobbyResponse.self, from: data)
    }

    func fetchLobbyMembers(lobbyId: String) async throws -> [User] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/members")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: req)
        struct MembersEnvelope: Codable { let members: [User] }
        return try JSONDecoder().decode(MembersEnvelope.self, from: data).members
    }

    // MARK: - Ingredients
    func fetchLobbyIngredients(lobbyId: String) async throws -> [String] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/ingredients")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: req)
        struct IngredientsEnvelope: Codable { let ingredients: [String] }
        return try JSONDecoder().decode(IngredientsEnvelope.self, from: data).ingredients
    }

    func addLobbyIngredients(lobbyId: String, ingredients: [String]) async throws -> [String] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/ingredients")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["ingredients": ingredients]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        struct IngredientsEnvelope: Codable { let ingredients: [String] }
        return try JSONDecoder().decode(IngredientsEnvelope.self, from: data).ingredients
    }

    func deleteLobbyIngredients(lobbyId: String, ingredients: [String]) async throws -> [String] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/ingredients")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["ingredients": ingredients]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        struct IngredientsEnvelope: Codable { let ingredients: [String] }
        return try JSONDecoder().decode(IngredientsEnvelope.self, from: data).ingredients
    }

    // MARK: - Recipes
    func generateRecipes(lobbyId: String, ingredients: [String]) async throws -> [Recipe] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/recipes/generate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["ingredients": ingredients]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        struct RecipesEnvelope: Codable { let recipes: [Recipe] }
        return try JSONDecoder().decode(RecipesEnvelope.self, from: data).recipes
    }

    func fetchRecipes(lobbyId: String) async throws -> [Recipe] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/recipes")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: req)
        struct RecipesEnvelope: Codable { let recipes: [Recipe] }
        return try JSONDecoder().decode(RecipesEnvelope.self, from: data).recipes
    }

    // MARK: - Votes
    func sendVote(lobbyId: String, userId: String, recipeId: String, direction: String) async throws {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/vote")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "userId": userId,
            "recipeId": recipeId,
            "direction": direction
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 200 && http.statusCode < 300 {
            return
        }
        throw URLError(.badServerResponse)
    }

    func fetchResults(lobbyId: String) async throws -> [Vote] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/results")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: req)
        struct VotesEnvelope: Codable { let votes: [Vote] }
        return try JSONDecoder().decode(VotesEnvelope.self, from: data).votes
    }

    // MARK: - OCR Ingredients from image
    func extractIngredientsFromImage(lobbyId: String, imageData: Data) async throws -> [String] {
        let url = baseURL.appendingPathComponent("api/lobby/\(lobbyId)/ingredients/vision")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let base64 = imageData.base64EncodedString()
        let payload = ["imageBase64": base64]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        struct IngredientsEnvelope: Codable { let ingredients: [String] }
        return try JSONDecoder().decode(IngredientsEnvelope.self, from: data).ingredients
    }
}
