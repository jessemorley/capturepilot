import SwiftUI
import Combine

@MainActor
final class GalleryViewModel: ObservableObject {
    @Published private(set) var variants: [Variant] = []
    @Published private(set) var collectionProperties = CollectionProperties()
    @Published private(set) var isPolling = false
    @Published var thumbnails: [UUID: NSImage] = [:]
    @Published var showSelectsOnly = false
    @Published var selectedVariantIDs: Set<UUID> = []
    @Published var activeVariantID: UUID?


    /// Variants to display (filtered by rating if showSelectsOnly is true)
    var displayedVariants: [Variant] {
        if showSelectsOnly {
            return variants.filter { $0.rating >= 3 }
        }
        return variants
    }

    /// Count of images with 3+ star rating
    var selectsCount: Int {
        variants.filter { $0.rating >= 3 }.count
    }

    /// Toggle the Selects filter (show only 3+ star images)
    func toggleSelectsFilter() {
        showSelectsOnly.toggle()
    }

    private let client: CapturePilotClient
    private let imageCache: ImageCacheService
    private let pollingService: LongPollingService

    private var cancellables = Set<AnyCancellable>()
    private var thumbnailLoadingTasks: [UUID: Task<Void, Never>] = [:]

    // Events for other view models
    let variantsAdded = PassthroughSubject<[Variant], Never>()
    let variantsRemoved = PassthroughSubject<[UUID], Never>()
    let variantsModified = PassthroughSubject<[UUID], Never>()

    init(client: CapturePilotClient, imageCache: ImageCacheService) {
        self.client = client
        self.imageCache = imageCache
        self.pollingService = LongPollingService(client: client)

        setupBindings()
    }

    private func setupBindings() {
        pollingService.serverChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] response in
                self?.handleServerResponse(response)
            }
            .store(in: &cancellables)

        pollingService.syncErrors
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.handleSyncError()
            }
            .store(in: &cancellables)
    }

    func startPolling() {
        guard !isPolling else { return }
        isPolling = true
        pollingService.startPolling()
    }

    func stopPolling() {
        isPolling = false
        pollingService.stopPolling()

        // Clear state
        variants.removeAll()
        thumbnails.removeAll()
        collectionProperties.reset()
        thumbnailLoadingTasks.values.forEach { $0.cancel() }
        thumbnailLoadingTasks.removeAll()
    }

    private func handleServerResponse(_ response: ServerResponse) {
        print("📨 [GalleryVM] handleServerResponse called")

        // Update collection properties
        if let objects = response.objects {
            print("📦 [GalleryVM] Processing \(objects.count) objects")
            collectionProperties.update(from: objects)
        } else {
            print("📦 [GalleryVM] No objects in response")
        }

        // Process variant changes
        guard let variantChanges = response.variants else {
            print("📸 [GalleryVM] No variants in response - current count: \(variants.count)")
            return
        }

        print("📸 [GalleryVM] Processing \(variantChanges.count) variant changes")

        var added: [Variant] = []
        var modified: [UUID] = []
        var metadataModified: [UUID] = []
        var deleted: [UUID] = []

        for change in variantChanges {
            print("🔍 [GalleryVM] Processing variant change - ID: \(change.variantID), type: \(change.changeType)")

            // Extract UUID from composite ID format "920/11935784-7C0B-426F-ABD6-F92D72E857AE"
            let uuidString = change.variantID.components(separatedBy: "/").last ?? change.variantID

            guard let uuid = UUID(uuidString: uuidString) else {
                print("❌ [GalleryVM] Failed to parse UUID from: \(change.variantID) (extracted: \(uuidString))")
                continue
            }

            switch change.changeType {
            case "new":
                print("➕ [GalleryVM] Creating new variant from change")
                if let variant = createVariant(from: change) {
                    print("✅ [GalleryVM] Successfully created variant: \(variant.displayName)")
                    added.append(variant)
                } else {
                    print("❌ [GalleryVM] Failed to create variant from change")
                    print("   - variantID: \(change.variantID)")
                    print("   - imageID: \(change.imageID ?? "nil")")
                    print("   - variantName: \(change.variantName ?? "nil")")
                }
            case "modified":
                print("✏️ [GalleryVM] Marking variant as modified")
                modified.append(uuid)
                // Invalidate cache for modified images
                Task {
                    await imageCache.invalidateAll(for: uuid)
                }
            case "metadata":
                print("📝 [GalleryVM] Updating variant metadata")
                updateVariantMetadata(uuid: uuid, from: change)
                metadataModified.append(uuid)
            case "deleted":
                print("🗑️ [GalleryVM] Marking variant for deletion")
                deleted.append(uuid)
            default:
                print("⚠️ [GalleryVM] Unknown change type: \(change.changeType)")
                break
            }
        }

        // Apply changes
        if !deleted.isEmpty {
            print("🗑️ [GalleryVM] Deleting \(deleted.count) variants")
            variants.removeAll { deleted.contains($0.id) }
            deleted.forEach { thumbnails.removeValue(forKey: $0) }
            variantsRemoved.send(deleted)
        }

        if !added.isEmpty {
            print("➕ [GalleryVM] Adding \(added.count) new variants")
            variants.append(contentsOf: added)
            updateImageVariantCounts()
            print("📊 [GalleryVM] Total variants now: \(variants.count)")
            variantsAdded.send(added)

            // Don't load thumbnails immediately - let the view trigger lazy loading
            // Thumbnails will be loaded when ThumbnailItemView appears via .onAppear
        }

        if !modified.isEmpty {
            print("✏️ [GalleryVM] Modified \(modified.count) variants")
            variantsModified.send(modified)

            // Reload thumbnails for modified variants
            for uuid in modified {
                if let variant = variants.first(where: { $0.id == uuid }) {
                    loadThumbnail(for: variant)
                }
            }
        }

        if !metadataModified.isEmpty {
            print("📝 [GalleryVM] Metadata modified for \(metadataModified.count) variants")
            variantsModified.send(metadataModified)
        }

        print("✅ [GalleryVM] handleServerResponse complete - total variants: \(variants.count)")
    }

    private func createVariant(from change: VariantChange) -> Variant? {
        // Extract UUID from composite ID format "920/11935784-7C0B-426F-ABD6-F92D72E857AE"
        let variantUUIDString = change.variantID.components(separatedBy: "/").last ?? change.variantID

        guard let uuid = UUID(uuidString: variantUUIDString),
              let imageID = change.imageID else {
            print("❌ [GalleryVM] createVariant failed - variantID: \(change.variantID), imageID: \(change.imageID ?? "nil")")
            return nil
        }

        // Extract UUID from imageID (which may also be in composite format)
        let imageUUIDString = imageID.components(separatedBy: "/").last ?? imageID

        guard let imageUUID = UUID(uuidString: imageUUIDString) else {
            print("❌ [GalleryVM] createVariant failed - couldn't parse imageUUID from: \(imageID)")
            return nil
        }

        let props = change.properties
        return Variant(
            id: uuid,
            imageUUID: imageUUID,
            originalVariantID: change.variantID,
            originalImageID: imageID,
            name: change.variantName ?? "",
            variantNumber: change.variantNo ?? 0,
            rating: props?.rating ?? 0,
            colorTag: ColorTag(rawValue: props?.colorTag ?? 0) ?? .none,
            isEditable: props?.editable ?? false,
            aperture: props?.aperture ?? "",
            iso: props?.iso ?? "",
            shutterSpeed: props?.shutterSpeed ?? "",
            focalLength: props?.focalLength ?? "",
            width: props?.width ?? 0,
            height: props?.height ?? 0
        )
    }

    private func updateVariantMetadata(uuid: UUID, from change: VariantChange) {
        guard let index = variants.firstIndex(where: { $0.id == uuid }) else { return }

        if let name = change.variantName {
            variants[index].name = name
        }
        if let variantNo = change.variantNo {
            variants[index].variantNumber = variantNo
        }
        if let props = change.properties {
            if let rating = props.rating {
                variants[index].rating = rating
            }
            if let colorTag = props.colorTag {
                variants[index].colorTag = ColorTag(rawValue: colorTag) ?? .none
            }
        }

        updateImageVariantCounts()
    }

    private func updateImageVariantCounts() {
        var imageCounts: [UUID: Int] = [:]
        for variant in variants {
            imageCounts[variant.imageUUID, default: 0] += 1
        }

        for i in variants.indices {
            variants[i].imageVariantCount = imageCounts[variants[i].imageUUID] ?? 1
        }
    }

    func loadThumbnail(for variant: Variant) {
        // Skip if already loaded or loading
        if thumbnails[variant.id] != nil || thumbnailLoadingTasks[variant.id] != nil {
            return
        }

        thumbnailLoadingTasks[variant.id] = Task {
            if let image = await imageCache.loadThumbnail(for: variant, client: client) {
                if !Task.isCancelled {
                    thumbnails[variant.id] = image
                }
            }
            thumbnailLoadingTasks.removeValue(forKey: variant.id)
        }
    }

    private func handleSyncError() {
        // Could trigger reconnection or notify user
        print("Sync error occurred")
    }

    // MARK: - Public Accessors

    var isEmpty: Bool {
        variants.isEmpty
    }

    var collectionName: String {
        collectionProperties.selectedFolder
    }

    var canSetRating: Bool {
        collectionProperties.canSetRating
    }

    var canSetColorTag: Bool {
        collectionProperties.canSetColorTag
    }

    func variant(for id: UUID) -> Variant? {
        variants.first { $0.id == id }
    }
    
    // MARK: - Selection Handling

    func selectVariant(_ variant: Variant, isCommandPressed: Bool) {
        if isCommandPressed {
            if selectedVariantIDs.contains(variant.id) {
                selectedVariantIDs.remove(variant.id)
            } else {
                selectedVariantIDs.insert(variant.id)
            }
        } else {
            selectedVariantIDs = [variant.id]
        }
        activeVariantID = variant.id
    }
}
