import SwiftUI
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    // Child ViewModels
    @Published var connectionVM: ConnectionViewModel
    @Published var galleryVM: GalleryViewModel
    @Published var viewerVM: ImageViewerViewModel
    @Published var preferencesVM: PreferencesViewModel

    // UI State
    @Published var showingPreferences = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        let client = CapturePilotClient()
        let imageCache = ImageCacheService()
        let preferencesVM = PreferencesViewModel()

        self.preferencesVM = preferencesVM
        self.connectionVM = ConnectionViewModel(client: client, preferencesVM: preferencesVM)
        self.galleryVM = GalleryViewModel(client: client, imageCache: imageCache)
        self.viewerVM = ImageViewerViewModel(client: client, imageCache: imageCache)

        // Wire up viewer to gallery
        viewerVM.setGalleryViewModel(galleryVM)

        setupBindings()
    }

    private func setupBindings() {
        // Forward connectionVM changes to AppViewModel's objectWillChange
        connectionVM.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Start/stop polling based on connection state
        connectionVM.$connectionState
            .sink { [weak self] state in
                guard let self else { return }

                switch state {
                case .connected:
                    galleryVM.startPolling()
                case .disconnected, .error:
                    galleryVM.stopPolling()
                    viewerVM.selectVariant(Variant(id: UUID(), imageUUID: UUID(), originalVariantID: "", originalImageID: "")) // Clear selection hack
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Auto-navigate to new images when enabled
        galleryVM.variantsAdded
            .sink { [weak self] variants in
                guard let self, preferencesVM.autoNavigateToNewImages, let last = variants.last else { return }
                // Defer to next run loop to avoid "Publishing changes from within view updates"
                Task { @MainActor in
                    self.viewerVM.selectVariant(last)
                }
            }
            .store(in: &cancellables)

        // Select first image when gallery first loads (if nothing selected)
        galleryVM.$variants
            .filter { !$0.isEmpty }
            .first()
            .sink { [weak self] variants in
                guard let self, !viewerVM.hasSelection, let first = variants.first else { return }
                // Defer to next run loop to avoid "Publishing changes from within view updates"
                Task { @MainActor in
                    self.viewerVM.selectVariant(first)
                }
            }
            .store(in: &cancellables)
    }

    func disconnect() {
        connectionVM.disconnect()
    }
}
