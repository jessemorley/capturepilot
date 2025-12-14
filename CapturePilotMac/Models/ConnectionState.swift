import Foundation

enum ConnectionState: Equatable, Hashable {
    case disconnected
    case discovering
    case connecting
    case connected(sessionID: Int)
    case error(ConnectionError)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var statusText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .discovering: return "Discovering servers..."
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let error): return error.localizedDescription
        }
    }
}

enum ConnectionError: Error, Equatable, Hashable, LocalizedError {
    case authenticationFailed
    case connectionFailed
    case serverDisconnected
    case timeout
    case syncError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .authenticationFailed: return "Authentication failed. Check your password."
        case .connectionFailed: return "Failed to connect to server."
        case .serverDisconnected: return "Server disconnected."
        case .timeout: return "Connection timed out."
        case .syncError: return "Synchronization error."
        case .invalidResponse: return "Invalid server response."
        }
    }
}

struct DiscoveredServer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let host: String
    let port: Int

    var address: String {
        "\(host):\(port)"
    }
}
