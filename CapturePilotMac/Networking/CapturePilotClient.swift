import Foundation

actor CapturePilotClient {
    private var baseURL: URL?
    private(set) var sessionID: Int = 0
    private let session: URLSession

    private let protocolVersion = "2.4"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Connection

    func connect(host: String, port: Int, password: String?) async throws -> Int {
        baseURL = URL(string: "http://\(host):\(port)")

        print("🌐 Creating connection URL: http://\(host):\(port)")

        guard let base = baseURL else {
            print("❌ Failed to create base URL")
            throw ConnectionError.connectionFailed
        }

        var components = URLComponents(url: base.appendingPathComponent("connectToService"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "protocolVersion", value: protocolVersion),
            URLQueryItem(name: "timestamp", value: timestamp)
        ]

        if let password, !password.isEmpty {
            let hashedPassword = SHA1Hasher.hash(password)
            queryItems.append(URLQueryItem(name: "password", value: hashedPassword))
            print("🔐 Including password in request")
        }

        components.queryItems = queryItems

        let finalURL = components.url!
        print("📤 Requesting: \(finalURL.absoluteString)")

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await session.data(for: request)

            print("📥 Received response")

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw ConnectionError.invalidResponse
            }

            print("📊 HTTP Status: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 401 {
                print("❌ Authentication failed (401)")
                throw ConnectionError.authenticationFailed
            }

            guard httpResponse.statusCode == 200 else {
                print("❌ Connection failed - status code: \(httpResponse.statusCode)")
                throw ConnectionError.connectionFailed
            }

            guard let responseString = String(data: data, encoding: .utf8) else {
                print("❌ Failed to decode response data")
                throw ConnectionError.invalidResponse
            }

            print("📄 Response body: '\(responseString)'")

            let trimmed = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let id = Int(trimmed), id > 0 else {
                print("❌ Invalid session ID: '\(trimmed)'")
                throw ConnectionError.connectionFailed
            }

            sessionID = id
            print("✅ Session ID obtained: \(id)")
            return id
        } catch {
            print("❌ Network error: \(error.localizedDescription)")
            throw error
        }
    }

    func disconnect() {
        sessionID = 0
        baseURL = nil
    }

    var isConnected: Bool {
        sessionID > 0 && baseURL != nil
    }

    // MARK: - Server State & Changes

    func getServerState() async throws -> ServerResponse {
        guard let url = buildURL(path: "getServerState") else {
            throw ConnectionError.connectionFailed
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        return try decoder.decode(ServerResponse.self, from: data)
    }

    func getServerChanges() async throws -> ServerResponse {
        guard let url = buildURL(path: "getServerChanges") else {
            throw ConnectionError.connectionFailed
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 90 // Long-poll timeout

        let (data, _) = try await session.data(for: request)

        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        return try decoder.decode(ServerResponse.self, from: data)
    }

    // MARK: - Image Loading

    func getImage(
        variantUUID: String,
        width: Int,
        height: Int,
        cropTop: Int = 0,
        cropBottom: Int = 0,
        cropLeft: Int = 0,
        cropRight: Int = 0
    ) async throws -> Data {
        guard let base = baseURL else {
            throw ConnectionError.connectionFailed
        }

        var components = URLComponents(url: base.appendingPathComponent("getImage"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "sessionID", value: String(sessionID)),
            URLQueryItem(name: "id", value: variantUUID),
            URLQueryItem(name: "width", value: String(width)),
            URLQueryItem(name: "height", value: String(height)),
            URLQueryItem(name: "top", value: String(cropTop)),
            URLQueryItem(name: "bottom", value: String(cropBottom)),
            URLQueryItem(name: "left", value: String(cropLeft)),
            URLQueryItem(name: "right", value: String(cropRight)),
            URLQueryItem(name: "timestamp", value: timestamp)
        ]

        var request = URLRequest(url: components.url!)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, _) = try await session.data(for: request)
        return data
    }

    // MARK: - Property Setting

    func setRating(for variant: Variant, rating: Int) async throws {
        try await setProperty(
            objectType: "kObjectType_ImageAdjustments",
            objectID: variant.encodedUUID,
            propertyID: "kImageAdjustmentProperty_Rating",
            value: String(rating)
        )
    }

    func setColorTag(for variant: Variant, colorTag: ColorTag) async throws {
        try await setProperty(
            objectType: "kObjectType_ImageAdjustments",
            objectID: variant.encodedUUID,
            propertyID: "kImageAdjustmentProperty_ColorTag",
            value: String(colorTag.rawValue)
        )
    }

    private func setProperty(objectType: String, objectID: String, propertyID: String, value: String) async throws {
        guard let base = baseURL else {
            throw ConnectionError.connectionFailed
        }

        var components = URLComponents(url: base.appendingPathComponent("setProperty"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "sessionID", value: String(sessionID)),
            URLQueryItem(name: "objectType", value: objectType),
            URLQueryItem(name: "objectID", value: objectID),
            URLQueryItem(name: "propertyID", value: propertyID),
            URLQueryItem(name: "propertyValue", value: value),
            URLQueryItem(name: "timestamp", value: timestamp)
        ]

        var request = URLRequest(url: components.url!)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        _ = try await session.data(for: request)
    }

    // MARK: - Helpers

    private func buildURL(path: String) -> URL? {
        guard let base = baseURL else { return nil }

        var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "sessionID", value: String(sessionID)),
            URLQueryItem(name: "timestamp", value: timestamp)
        ]

        return components.url
    }

    private var timestamp: String {
        String(Int(Date().timeIntervalSince1970 * 1000))
    }
}
