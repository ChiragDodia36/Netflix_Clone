//
//  VimeoService.swift
//  Netflix
//

import Foundation

class VimeoService {
    static let shared = VimeoService()

    private let baseURL = "https://api.vimeo.com"

    private var accessToken: String {
        Bundle.main.object(forInfoDictionaryKey: "VimeoAccessToken") as? String ?? ""
    }

    private init() {}

    // MARK: - Search for a trailer by movie title
    // Returns a Vimeo embed URL: https://player.vimeo.com/video/{id}

    func searchTrailer(for title: String) async -> URL? {
        let query = "\(title) official trailer"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        guard let url = URL(string: "\(baseURL)/videos?query=\(query)&per_page=5&sort=relevant&filter=playable") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }

            let result = try JSONDecoder().decode(VimeoSearchResponse.self, from: data)

            // Pick best match — prefer videos with "trailer" or title in name
            let best = result.data.first(where: {
                let name = $0.name.lowercased()
                return name.contains("trailer") && name.contains(title.lowercased())
            }) ?? result.data.first(where: {
                $0.name.lowercased().contains("trailer")
            }) ?? result.data.first

            guard let videoId = best?.id else { return nil }

            return URL(string: "https://player.vimeo.com/video/\(videoId)?autoplay=1&color=E50914&title=0&byline=0&portrait=0")

        } catch {
            return nil
        }
    }
}

// MARK: - Vimeo API response models

private struct VimeoSearchResponse: Codable {
    let data: [VimeoVideo]
}

private struct VimeoVideo: Codable {
    let uri: String  // e.g. "/videos/123456789"
    let name: String

    var id: String? {
        uri.components(separatedBy: "/").last
    }
}
