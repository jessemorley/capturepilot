import SwiftUI
import Combine

@MainActor
final class ImageViewerViewModel: ObservableObject {
    @Published private(set) var currentVariant: Variant?
    @Published private(set) var currentImage: NSImage?
    @Published private(set) var isLoadingImage = false

    private let client: CapturePilotClient
    private let imageCache: ImageCacheService
    private weak var galleryVM: GalleryViewModel?

    private var loadingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(client: CapturePilotClient, imageCache: ImageCacheService) {
        self.client = client
        self.imageCache = imageCache
    }

    func setGalleryViewModel(_ galleryVM: GalleryViewModel) {
        self.galleryVM = galleryVM
        setupBindings()
    }

    private func setupBindings() {
        guard let galleryVM else { return }

        // Sync with activeVariantID changes from GalleryViewModel
        galleryVM.$activeVariantID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeID in
                guard let self, let activeID, let galleryVM = self.galleryVM else { return }

                // If in multi-select mode (more than 1 selected), don't load full image
                // Just update currentVariant without loading
                if galleryVM.selectedVariantIDs.count > 1 {
                    if let variant = galleryVM.variant(for: activeID) {
                        self.currentVariant = variant
                    }
                } else {
                    // Single select - load the full image
                    if activeID != self.currentVariant?.id {
                        self.selectVariantByID(activeID)
                    }
                }
            }
            .store(in: &cancellables)

        // Handle modified variants - refresh current image if affected
        galleryVM.variantsModified
            .receive(on: DispatchQueue.main)
            .sink { [weak self] modifiedIDs in
                guard let self, let current = currentVariant else { return }

                if modifiedIDs.contains(current.id) {
                    // Update currentVariant with latest metadata from GalleryViewModel
                    if let updatedVariant = galleryVM.variant(for: current.id) {
                        self.currentVariant = updatedVariant
                    }
                    refreshCurrentImage()
                }
            }
            .store(in: &cancellables)

        // Handle removed variants - deselect if current is removed
        galleryVM.variantsRemoved
            .receive(on: DispatchQueue.main)
            .sink { [weak self] removedIDs in
                guard let self, let current = currentVariant else { return }
                if removedIDs.contains(current.id) {
                    // Select adjacent variant or clear
                    if let variants = self.galleryVM?.variants, !variants.isEmpty {
                        selectVariant(variants.first!)
                    } else {
                        currentVariant = nil
                        currentImage = nil
                    }
                }
            }
            .store(in: &cancellables)
    }

    func selectVariant(_ variant: Variant) {
        guard variant.id != currentVariant?.id else { return }

        currentVariant = variant
        loadFullImage(for: variant)

        // Also update galleryVM selection to stay in sync
        if let galleryVM {
            // When navigating, clear multi-select and set single selection
            galleryVM.selectedVariantIDs = [variant.id]
            galleryVM.activeVariantID = variant.id
        }
    }

    func loadImage(for variant: Variant) async -> NSImage? {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0

        let requestSize = CGSize(
            width: screenSize.width * scale,
            height: screenSize.height * scale
        )

        return await imageCache.loadPreview(for: variant, size: requestSize, client: client)
    }

    func selectVariantByID(_ id: UUID) {
        guard let galleryVM, let variant = galleryVM.variant(for: id) else { return }
        selectVariant(variant)
    }

    private func loadFullImage(for variant: Variant) {
        loadingTask?.cancel()
        isLoadingImage = true

        loadingTask = Task {
            // Get screen size for optimal resolution
            let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
            let scale = NSScreen.main?.backingScaleFactor ?? 2.0

            let requestSize = CGSize(
                width: screenSize.width * scale,
                height: screenSize.height * scale
            )

            if let image = await imageCache.loadPreview(for: variant, size: requestSize, client: client) {
                if !Task.isCancelled {
                    currentImage = image
                }
            }

            if !Task.isCancelled {
                isLoadingImage = false
            }
        }
    }

    func refreshCurrentImage() {
        guard let variant = currentVariant else { return }

        // Invalidate cache and reload
        Task {
            await imageCache.invalidateAll(for: variant.id)
        }
        loadFullImage(for: variant)
    }

    // MARK: - Navigation

    func navigateToNext() {
        guard let current = currentVariant,
              let variants = galleryVM?.variants,
              let currentIndex = variants.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        let nextIndex = (currentIndex + 1) % variants.count
        selectVariant(variants[nextIndex])
    }

    func navigateToPrevious() {
        guard let current = currentVariant,
              let variants = galleryVM?.variants,
              let currentIndex = variants.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        let prevIndex = currentIndex == 0 ? variants.count - 1 : currentIndex - 1
        selectVariant(variants[prevIndex])
    }

    func navigateToFirst() {
        guard let variants = galleryVM?.variants, let first = variants.first else { return }
        selectVariant(first)
    }

    func navigateToLast() {
        guard let variants = galleryVM?.variants, let last = variants.last else { return }
        selectVariant(last)
    }

    // MARK: - Rating and Color Tag

    func setRating(_ rating: Int) {
        guard rating >= 0 && rating <= 5,
              let variant = currentVariant,
              galleryVM?.canSetRating == true else { return }

        Task {
            try? await client.setRating(for: variant, rating: rating)
        }
    }

    func setColorTag(_ colorTag: ColorTag) {
        guard let variant = currentVariant,
              galleryVM?.canSetColorTag == true else { return }

        Task {
            try? await client.setColorTag(for: variant, colorTag: colorTag)
        }
    }

    // MARK: - State

    var hasSelection: Bool {
        currentVariant != nil
    }

    var currentIndex: Int? {
        guard let current = currentVariant,
              let variants = galleryVM?.variants else { return nil }
        return variants.firstIndex(where: { $0.id == current.id })
    }

    var totalCount: Int {
        galleryVM?.variants.count ?? 0
    }

    var positionText: String {
        guard let index = currentIndex else { return "" }
        return "\(index + 1) / \(totalCount)"
    }
}
