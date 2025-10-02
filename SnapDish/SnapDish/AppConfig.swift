import Foundation
import SwiftUI

@Observable
final class AppConfig {
    var serverBaseURL: String = {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:3000"
        #else
        // Auf echtem Gerät bitte IP des Macs eintragen (z. B. "http://172.31.129.105:3000")
        return "http://172.17.224.85:3000"  // Deine aktuelle Mac-IP
        #endif
    }()

    var resolvedBaseURL: URL? {
        URL(string: serverBaseURL.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

@MainActor
enum APIProvider {
    static func makeClient(config: AppConfig) throws -> APIClient {
        guard let url = config.resolvedBaseURL else {
            throw URLError(.badURL)
        }
        return APIClient(baseURL: url)
    }
}
