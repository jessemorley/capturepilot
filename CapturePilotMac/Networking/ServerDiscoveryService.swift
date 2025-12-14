import Foundation
import Network

@MainActor
final class ServerDiscoveryService: ObservableObject {
    @Published private(set) var discoveredServers: [DiscoveredServer] = []
    @Published private(set) var isSearching = false

    private var browser: NWBrowser?
    private var resolvers: [NWConnection] = []

    // Capture Pilot uses this service type
    private let serviceType = "_lrswebserver._tcp"

    func startBrowsing() {
        guard browser == nil else { return }

        isSearching = true
        discoveredServers.removeAll()

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjour(type: serviceType, domain: "local."), using: parameters)

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor in
                self?.handleBrowseResults(results)
            }
        }

        browser?.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    break
                case .failed, .cancelled:
                    self?.isSearching = false
                default:
                    break
                }
            }
        }

        browser?.start(queue: .main)
    }

    func stopBrowsing() {
        browser?.cancel()
        browser = nil
        resolvers.forEach { $0.cancel() }
        resolvers.removeAll()
        isSearching = false
    }

    private func handleBrowseResults(_ results: Set<NWBrowser.Result>) {
        for result in results {
            if case .service(let name, let type, let domain, _) = result.endpoint {
                resolveService(name: name, type: type, domain: domain)
            }
        }
    }

    private func resolveService(name: String, type: String, domain: String) {
        // Skip if we already have this server
        guard !discoveredServers.contains(where: { $0.name == name }) else { return }

        let connection = NWConnection(
            to: .service(name: name, type: type, domain: domain, interface: nil),
            using: .tcp
        )

        resolvers.append(connection)

        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self, let connection else { return }

            Task { @MainActor in
                switch state {
                case .ready:
                    if let endpoint = connection.currentPath?.remoteEndpoint {
                        self.handleResolvedEndpoint(endpoint, name: name)
                    }
                    connection.cancel()
                    self.resolvers.removeAll { $0 === connection }
                case .failed, .cancelled:
                    self.resolvers.removeAll { $0 === connection }
                default:
                    break
                }
            }
        }

        connection.start(queue: .main)
    }

    private func handleResolvedEndpoint(_ endpoint: NWEndpoint, name: String) {
        guard case .hostPort(let host, let port) = endpoint else { return }

        let hostString: String
        switch host {
        case .ipv4(let addr):
            hostString = "\(addr)"
        case .ipv6(let addr):
            hostString = "\(addr)"
        case .name(let hostname, _):
            hostString = hostname
        @unknown default:
            hostString = "\(host)"
        }

        // Clean up the host string (remove scope ID for IPv6 if present)
        let cleanHost = hostString.components(separatedBy: "%").first ?? hostString

        let server = DiscoveredServer(
            name: name,
            host: cleanHost,
            port: Int(port.rawValue)
        )

        if !discoveredServers.contains(where: { $0.name == name }) {
            discoveredServers.append(server)
        }
    }

    deinit {
        browser?.cancel()
        resolvers.forEach { $0.cancel() }
    }
}
