import SwiftUI
import Combine

@MainActor
final class ConnectionViewModel: ObservableObject {
    @Published private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            print("🔄 ConnectionState changed from \(oldValue) to \(connectionState)")
        }
    }
    @Published var discoveredServers: [DiscoveredServer] = []
    @Published var manualHost: String = ""
    @Published var manualPort: String = "52505"
    @Published var password: String = ""
    @Published var showPasswordField: Bool = false

    let client: CapturePilotClient
    private let discoveryService = ServerDiscoveryService()
    private let preferencesVM: PreferencesViewModel

    private var cancellables = Set<AnyCancellable>()
    private var retryCount = 0
    private let maxRetries = 5
    private let retryDelay: TimeInterval = 1.0

    init(client: CapturePilotClient, preferencesVM: PreferencesViewModel) {
        self.client = client
        self.preferencesVM = preferencesVM

        // Load last server from preferences
        if !preferencesVM.lastServerHost.isEmpty {
            manualHost = preferencesVM.lastServerHost
            manualPort = String(preferencesVM.lastServerPort)
        }

        setupBindings()
    }

    private func setupBindings() {
        discoveryService.$discoveredServers
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredServers)
    }

    func startDiscovery() {
        connectionState = .discovering
        discoveryService.startBrowsing()
    }

    func stopDiscovery() {
        discoveryService.stopBrowsing()
    }

    func connect(to server: DiscoveredServer) {
        Task {
            await connect(host: server.host, port: server.port)
        }
    }

    func connectManually() {
        guard let port = Int(manualPort), !manualHost.isEmpty else {
            print("❌ Invalid input - host: '\(manualHost)', port: '\(manualPort)'")
            return
        }
        print("🔌 Starting manual connection to \(manualHost):\(port)")
        Task {
            await connect(host: manualHost, port: port)
        }
    }

    private func connect(host: String, port: Int) async {
        print("📡 Connecting to \(host):\(port)")
        connectionState = .connecting
        retryCount = 0

        await attemptConnection(host: host, port: port)
    }

    private func attemptConnection(host: String, port: Int) async {
        print("🔄 Attempt \(retryCount + 1)/\(maxRetries) to connect to \(host):\(port)")
        do {
            let sessionID = try await client.connect(
                host: host,
                port: port,
                password: password.isEmpty ? nil : password
            )

            print("✅ Received sessionID: \(sessionID)")

            if sessionID > 0 {
                // Save successful connection
                await MainActor.run {
                    preferencesVM.lastServerHost = host
                    preferencesVM.lastServerPort = port
                    connectionState = .connected(sessionID: sessionID)
                    print("✅ Successfully connected with sessionID: \(sessionID)")
                }
                stopDiscovery()
            } else {
                print("❌ Invalid sessionID: \(sessionID)")
                throw ConnectionError.connectionFailed
            }
        } catch let error as ConnectionError {
            print("❌ Connection error: \(error)")
            await MainActor.run {
                if error == .authenticationFailed {
                    connectionState = .error(.authenticationFailed)
                    showPasswordField = true
                }
            }
            if error != .authenticationFailed {
                await retryConnection(host: host, port: port)
            }
        } catch {
            print("❌ Unexpected error: \(error)")
            await retryConnection(host: host, port: port)
        }
    }

    private func retryConnection(host: String, port: Int) async {
        retryCount += 1

        if retryCount < maxRetries {
            try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            await attemptConnection(host: host, port: port)
        } else {
            await MainActor.run {
                connectionState = .error(.connectionFailed)
            }
        }
    }

    func disconnect() {
        Task {
            await client.disconnect()
        }
        connectionState = .disconnected
        retryCount = 0
    }

    func retryLastConnection() {
        guard !preferencesVM.lastServerHost.isEmpty else {
            startDiscovery()
            return
        }

        Task {
            await connect(host: preferencesVM.lastServerHost, port: preferencesVM.lastServerPort)
        }
    }

    var isConnecting: Bool {
        if case .connecting = connectionState { return true }
        return false
    }
}
