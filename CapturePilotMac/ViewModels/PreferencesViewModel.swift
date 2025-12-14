import SwiftUI

final class PreferencesViewModel: ObservableObject {
    @AppStorage("autoNavigateToNewImages") var autoNavigateToNewImages: Bool = true
    @AppStorage("lastServerHost") var lastServerHost: String = ""
    @AppStorage("lastServerPort") var lastServerPort: Int = 8080
    @AppStorage("thumbnailHeight") var thumbnailHeight: Double = 80

    enum ThumbnailSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"

        var height: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 80
            case .large: return 120
            }
        }
    }

    var thumbnailSize: ThumbnailSize {
        get {
            if thumbnailHeight <= 60 { return .small }
            if thumbnailHeight <= 90 { return .medium }
            return .large
        }
        set {
            thumbnailHeight = newValue.height
        }
    }
}
