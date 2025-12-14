import AppKit

extension NSImage {
    convenience init?(base64String: String) {
        // Remove data URL prefix if present
        var base64 = base64String
        if base64.hasPrefix("data:") {
            if let commaIndex = base64.firstIndex(of: ",") {
                base64 = String(base64[base64.index(after: commaIndex)...])
            }
        }

        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
            return nil
        }

        self.init(data: data)
    }

    static func from(serverData data: Data) -> NSImage? {
        // Server returns base64-encoded JPEG string
        if let string = String(data: data, encoding: .utf8) {
            // Check if it's an error response
            if string.hasPrefix("HTTP/") {
                return nil
            }
            return NSImage(base64String: string)
        }
        // Fallback: try as raw image data
        return NSImage(data: data)
    }
}
