import Foundation

// MARK: - Models
struct HealthResponse: Codable { let status: String }

struct ImproveRequest: Codable {
    /// Server erwartet dieses Feld
    let email_body: String
}

struct ImproveResponse: Codable {
    /// Server liefert dieses Feld
    let email_improved: String?
    /// Falls die Route Fehler als JSON schickt
    let error: String?
}

// MARK: - API Client
struct APIClient {
    let baseURL: URL

    // GET /health
    func health() async throws -> HealthResponse {
        let url = baseURL.appendingPathComponent("health")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "HTTP",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "GET /health → HTTP \((resp as? HTTPURLResponse)?.statusCode ?? -1): \(body)"])
        }
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }

    // POST /api/example/improve
    func improveEmail(text: String) async throws -> ImproveResponse {
        let url = baseURL.appendingPathComponent("api/example/improve")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // ⟵ wichtig: email_body
        let payload = ImproveRequest(email_body: text)
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "HTTP",
                          code: (resp as? HTTPURLResponse)?.statusCode ?? -1,
                          userInfo: [NSLocalizedDescriptionKey: "POST /api/example/improve → HTTP \((resp as? HTTPURLResponse)?.statusCode ?? -1): \(body)"])
        }
        return try JSONDecoder().decode(ImproveResponse.self, from: data)
    }
}
