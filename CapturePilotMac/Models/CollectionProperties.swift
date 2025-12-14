import Foundation

struct CollectionProperties {
    var selectedFolder: String = "No Collection"
    var canSetRating: Bool = false
    var canSetColorTag: Bool = false

    mutating func update(from objects: [ServerObject]) {
        for obj in objects where obj.objectType == "kObjectType_CPServer" {
            guard let properties = obj.properties else { continue }

            for prop in properties {
                let key = prop.propertyID.replacingOccurrences(of: "kServerProperty_", with: "")

                switch key {
                case "SelectedFolder":
                    selectedFolder = prop.stringValue
                case "Rating_Permission":
                    canSetRating = prop.stringValue.lowercased() == "enabled"
                case "ColorTag_Permission":
                    canSetColorTag = prop.stringValue.lowercased() == "enabled"
                default:
                    break
                }
            }
        }
    }

    mutating func reset() {
        selectedFolder = "No Collection"
        canSetRating = false
        canSetColorTag = false
    }
}
