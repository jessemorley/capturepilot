import Foundation
import Combine

final class LongPollingService {
    private let client: CapturePilotClient
    private var isPolling = false
    private var pollingTask: Task<Void, Never>?

    let serverChangesSubject = PassthroughSubject<ServerResponse, Never>()
    let errorSubject = PassthroughSubject<Error, Never>()
    let syncErrorSubject = PassthroughSubject<Void, Never>()

    var serverChanges: AnyPublisher<ServerResponse, Never> {
        serverChangesSubject.eraseToAnyPublisher()
    }

    var errors: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    var syncErrors: AnyPublisher<Void, Never> {
        syncErrorSubject.eraseToAnyPublisher()
    }

    private var revision: Int = -1
    private var resyncRetryCount = 0
    private let maxResyncRetries = 5

    init(client: CapturePilotClient) {
        self.client = client
    }

    func startPolling() {
        guard !isPolling else { return }
        isPolling = true
        revision = -1
        resyncRetryCount = 0

        pollingTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    func stopPolling() {
        isPolling = false
        pollingTask?.cancel()
        pollingTask = nil
        revision = -1
    }

    private func pollLoop() async {
        print("🔄 [LongPolling] Starting poll loop (revision: \(revision))")

        // Start with getServerChanges() for initial load (like web client)
        // This returns the full initial state on first call
        while isPolling && !Task.isCancelled {
            do {
                print("📡 [LongPolling] Calling getServerChanges() (current revision: \(revision))")
                let response = try await client.getServerChanges()

                // Log what we received
                if let rev = response.revision {
                    print("📥 [LongPolling] Received response with revision: \(rev)")
                } else {
                    print("📥 [LongPolling] Received response with no revision (timeout/empty)")
                }

                if let variantCount = response.variants?.count {
                    print("📸 [LongPolling] Response contains \(variantCount) variant changes")
                } else {
                    print("📸 [LongPolling] Response contains no variant changes (nil)")
                }

                if let objectCount = response.objects?.count {
                    print("📦 [LongPolling] Response contains \(objectCount) objects")
                } else {
                    print("📦 [LongPolling] Response contains no objects (nil)")
                }

                // Check revision for sync
                if let responseRevision = response.revision {
                    let expectedRevision = revision + 1

                    if revision == -1 || responseRevision == expectedRevision {
                        // In sync
                        print("✅ [LongPolling] In sync - updating revision from \(revision) to \(responseRevision)")
                        revision = responseRevision
                        resyncRetryCount = 0
                        serverChangesSubject.send(response)
                    } else {
                        // Out of sync - attempt resync
                        print("⚠️ [LongPolling] Out of sync - expected \(expectedRevision), got \(responseRevision)")
                        await attemptResync()
                    }
                } else {
                    // No revision in response (timeout/empty), still send it
                    print("📤 [LongPolling] Sending response without revision")
                    serverChangesSubject.send(response)
                }
            } catch is CancellationError {
                print("🛑 [LongPolling] Polling cancelled")
                break
            } catch {
                // On error, log it, notify, wait briefly then retry (don't exit loop)
                print("❌ [LongPolling] Error during polling: \(error)")
                if isPolling {
                    errorSubject.send(error)
                    print("⏳ [LongPolling] Waiting 1s before retry...")
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }

        print("🛑 [LongPolling] Poll loop ended")
    }

    private func attemptResync() async {
        resyncRetryCount += 1
        print("🔄 [LongPolling] Attempting resync (attempt \(resyncRetryCount)/\(maxResyncRetries))")

        if resyncRetryCount > maxResyncRetries {
            print("❌ [LongPolling] Max resync retries exceeded - stopping polling")
            syncErrorSubject.send(())
            stopPolling()
            return
        }

        // Wait before retry
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        do {
            print("📡 [LongPolling] Calling getServerState() for resync")
            let state = try await client.getServerState()
            if let rev = state.revision {
                print("✅ [LongPolling] Resync successful - revision: \(rev)")
                revision = rev
            }
            serverChangesSubject.send(state)
        } catch {
            print("❌ [LongPolling] Resync failed: \(error)")
            errorSubject.send(error)
        }
    }

    func requestFullState() async {
        do {
            let state = try await client.getServerState()
            if let rev = state.revision {
                revision = rev
            }
            serverChangesSubject.send(state)
        } catch {
            errorSubject.send(error)
        }
    }
}
