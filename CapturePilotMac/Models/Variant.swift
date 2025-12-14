import Foundation

struct Variant: Identifiable, Equatable, Hashable {
    let id: UUID
    let imageUUID: UUID
    let originalVariantID: String  // Store original composite ID like "920/11935784-7C0B-426F-ABD6-F92D72E857AE"
    let originalImageID: String     // Store original composite imageID

    var name: String
    var variantNumber: Int
    var imageVariantCount: Int = 1

    // Metadata
    var rating: Int
    var colorTag: ColorTag
    var isEditable: Bool

    // EXIF Data
    var aperture: String
    var iso: String
    var shutterSpeed: String
    var focalLength: String

    // Dimensions
    var width: Int
    var height: Int

    var displayName: String {
        if imageVariantCount > 1 {
            return "\(name) (\(variantNumber + 1))"
        }
        return name
    }

    var encodedUUID: String {
        // Use original composite ID for API calls
        originalVariantID
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .replacingOccurrences(of: "'", with: "%27") ?? originalVariantID
    }

    var aspectRatio: CGFloat {
        guard width > 0 else { return 1.0 }
        return CGFloat(width) / CGFloat(height)
    }

    var exifSummary: String {
        var parts: [String] = []
        if !aperture.isEmpty { parts.append(aperture) }
        if !shutterSpeed.isEmpty { parts.append(shutterSpeed) }
        if !iso.isEmpty { parts.append("ISO \(iso)") }
        if !focalLength.isEmpty { parts.append(focalLength) }
        return parts.joined(separator: " · ")
    }

    init(
        id: UUID,
        imageUUID: UUID,
        originalVariantID: String,
        originalImageID: String,
        name: String = "",
        variantNumber: Int = 0,
        rating: Int = 0,
        colorTag: ColorTag = .none,
        isEditable: Bool = false,
        aperture: String = "",
        iso: String = "",
        shutterSpeed: String = "",
        focalLength: String = "",
        width: Int = 0,
        height: Int = 0
    ) {
        self.id = id
        self.imageUUID = imageUUID
        self.originalVariantID = originalVariantID
        self.originalImageID = originalImageID
        self.name = name
        self.variantNumber = variantNumber
        self.rating = rating
        self.colorTag = colorTag
        self.isEditable = isEditable
        self.aperture = aperture
        self.iso = iso
        self.shutterSpeed = shutterSpeed
        self.focalLength = focalLength
        self.width = width
        self.height = height
    }
}
