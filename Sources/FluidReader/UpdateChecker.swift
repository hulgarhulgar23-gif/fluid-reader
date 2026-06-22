import Foundation

/// Manual update check against GitHub releases.
///
/// Fluid Reader is local-first: this never runs in the background. It only
/// performs a network request when the user picks "Check for Updates" from
/// the menu.
enum UpdateChecker {
    struct Release: Equatable {
        let version: String
        let pageURL: URL
    }

    enum UpdateError: Error, Equatable {
        case badResponse
        case badPayload
    }

    static let repositorySlug = "hulgarhulgar23-gif/fluid-reader"

    static var latestReleaseAPIURL: URL {
        URL(string: "https://api.github.com/repos/\(repositorySlug)/releases/latest")!
    }

    static var releasesPageURL: URL {
        URL(string: "https://github.com/\(repositorySlug)/releases")!
    }

    static func currentVersion(bundle: Bundle = .main) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let trimmed = version?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "0.0.0" : trimmed
    }

    /// Compares dotted numeric versions; ignores a leading `v` and any
    /// pre-release suffix after `-`. Returns true when `candidate` is newer.
    static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let lhs = numericComponents(of: candidate)
        let rhs = numericComponents(of: current)
        guard !lhs.isEmpty, !rhs.isEmpty else { return false }

        let count = max(lhs.count, rhs.count)
        for index in 0..<count {
            let lhsValue = index < lhs.count ? lhs[index] : 0
            let rhsValue = index < rhs.count ? rhs[index] : 0
            if lhsValue != rhsValue {
                return lhsValue > rhsValue
            }
        }
        return false
    }

    static func numericComponents(of version: String) -> [Int] {
        var core = version.trimmingCharacters(in: .whitespacesAndNewlines)
        if core.lowercased().hasPrefix("v") {
            core = String(core.dropFirst())
        }
        if let dash = core.firstIndex(of: "-") {
            core = String(core[..<dash])
        }
        let parts = core.split(separator: ".")
        var components: [Int] = []
        for part in parts {
            guard let value = Int(part), value >= 0 else { return [] }
            components.append(value)
        }
        return components
    }

    static func parseLatestRelease(from data: Data) throws -> Release {
        struct Payload: Decodable {
            let tagName: String
            let htmlUrl: String

            enum CodingKeys: String, CodingKey {
                case tagName = "tag_name"
                case htmlUrl = "html_url"
            }
        }

        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            throw UpdateError.badPayload
        }
        let version = payload.tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !version.isEmpty,
              !numericComponents(of: version).isEmpty,
              let pageURL = URL(string: payload.htmlUrl),
              pageURL.scheme == "https",
              pageURL.user == nil,
              pageURL.password == nil,
              pageURL.host?.lowercased() == "github.com",
              isTrustedReleasesPath(pageURL.path) else {
            throw UpdateError.badPayload
        }
        return Release(version: version, pageURL: pageURL)
    }

    private static func isTrustedReleasesPath(_ path: String) -> Bool {
        let expectedPrefix = repositorySlug
            .split(separator: "/")
            .map(String.init) + ["releases"]
        let segments = path.split(separator: "/").map(String.init)
        guard segments.count >= expectedPrefix.count,
              segments.starts(with: expectedPrefix) else {
            return false
        }

        for segment in segments {
            let decoded = segment.removingPercentEncoding ?? segment
            if decoded == "."
                || decoded == ".."
                || decoded.contains("\\")
                || decoded.contains("/") {
                return false
            }
        }

        return true
    }

    static func fetchLatestRelease(session: URLSession = .shared) async throws -> Release {
        var request = URLRequest(url: latestReleaseAPIURL)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.badResponse
        }
        return try parseLatestRelease(from: data)
    }
}
