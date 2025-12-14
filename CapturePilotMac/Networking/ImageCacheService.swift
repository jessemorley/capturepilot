import Foundation
import AppKit

actor ImageCacheService {
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private let previewCache = NSCache<NSString, NSImage>()

    init() {
        thumbnailCache.countLimit = 300
        thumbnailCache.totalCostLimit = 100 * 1024 * 1024 // 100MB

        previewCache.countLimit = 10
        previewCache.totalCostLimit = 200 * 1024 * 1024 // 200MB
    }

    // MARK: - Thumbnail Loading

    func loadThumbnail(
        for variant: Variant,
        size: CGSize = CGSize(width: 160, height: 160),
        client: CapturePilotClient
    ) async -> NSImage? {
        let cacheKey = NSString(string: "thumb_\(variant.id.uuidString)")

        // Check cache
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }

        // Load from server
        do {
            let data = try await client.getImage(
                variantUUID: variant.encodedUUID,
                width: Int(size.width),
                height: Int(size.height)
            )

            if let image = NSImage.from(serverData: data) {
                let cost = Int(image.size.width * image.size.height * 4)
                thumbnailCache.setObject(image, forKey: cacheKey, cost: cost)
                return image
            }
        } catch {
            print("Failed to load thumbnail for \(variant.name): \(error)")
        }

        return nil
    }

    // MARK: - Preview Loading

    func loadPreview(
        for variant: Variant,
        size: CGSize,
        client: CapturePilotClient
    ) async -> NSImage? {
        let cacheKey = NSString(string: "preview_\(variant.id.uuidString)_\(Int(size.width))x\(Int(size.height))")

        // Check cache
        if let cached = previewCache.object(forKey: cacheKey) {
            return cached
        }

        // Load from server
        do {
            let data = try await client.getImage(
                variantUUID: variant.encodedUUID,
                width: Int(size.width),
                height: Int(size.height)
            )

            if let image = NSImage.from(serverData: data) {
                let cost = Int(image.size.width * image.size.height * 4)
                previewCache.setObject(image, forKey: cacheKey, cost: cost)
                return image
            }
        } catch {
            print("Failed to load preview for \(variant.name): \(error)")
        }

        return nil
    }

    // MARK: - Cache Retrieval

    func getCachedThumbnail(for variantID: UUID) -> NSImage? {
        let cacheKey = NSString(string: "thumb_\(variantID.uuidString)")
        return thumbnailCache.object(forKey: cacheKey)
    }

    // MARK: - Cache Management

    func invalidateThumbnail(for variantID: UUID) {
        let cacheKey = NSString(string: "thumb_\(variantID.uuidString)")
        thumbnailCache.removeObject(forKey: cacheKey)
    }

    func invalidatePreview(for variantID: UUID) {
        // Since NSCache doesn't support iteration, we can't remove all sizes
        // But the cache will naturally evict old entries
    }

    func invalidateAll(for variantID: UUID) {
        invalidateThumbnail(for: variantID)
        invalidatePreview(for: variantID)
    }

    func clearAllCaches() {
        thumbnailCache.removeAllObjects()
        previewCache.removeAllObjects()
    }

    // MARK: - Preloading

    func preloadThumbnails(
        for variants: [Variant],
        size: CGSize = CGSize(width: 160, height: 160),
        client: CapturePilotClient
    ) async {
        await withTaskGroup(of: Void.self) { group in
            for variant in variants {
                group.addTask {
                    _ = await self.loadThumbnail(for: variant, size: size, client: client)
                }
            }
        }
    }
}
