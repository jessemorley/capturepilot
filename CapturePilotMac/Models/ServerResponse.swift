import Foundation

// MARK: - Top-level Response

struct ServerResponse: Decodable, Sendable {
    let revision: Int?
    let objects: [ServerObject]?
    let variants: [VariantChange]?

    enum CodingKeys: String, CodingKey {
        case revision
        case objects
        case variants
    }
}

// MARK: - Server Objects (Collection Properties)

struct ServerObject: Decodable, Sendable {
    let objectType: String
    let changeType: String
    let properties: [ObjectProperty]?

    enum CodingKeys: String, CodingKey {
        case objectType = "kObjectKey_ObjectType"
        case changeType = "kObjectKey_ChangeType"
        case properties = "kObjectKey_Properties"
    }
}

struct ObjectProperty: Decodable, Sendable {
    let propertyID: String
    let currentValue: AnyCodableValue
    let permissions: String?
    let valueType: String?

    enum CodingKeys: String, CodingKey {
        case propertyID = "kObjectProperty_PropertyID"
        case currentValue = "kObjectProperty_CurrentValue"
        case permissions = "kObjectProperty_Permissions"
        case valueType = "kObjectProperty_ValueType"
    }

    var stringValue: String {
        currentValue.stringValue
    }
}

// MARK: - Variant Changes

struct VariantChange: Decodable, Sendable {
    let variantID: String
    let changeType: String
    let imageID: String?
    let variantName: String?
    let variantNo: Int?
    let properties: VariantProperties?

    enum CodingKeys: String, CodingKey {
        case variantID = "kVariantKey_VariantID"
        case changeType = "kVariantKey_ChangeType"
        case imageID = "kVariantKey_ImageID"
        case variantName = "kVariantKey_VariantName"
        case variantNo = "kVariantKey_VariantNo"
        case properties = "kVariantKey_Properties"
    }
}

struct VariantProperties: Decodable, Sendable {
    let height: Int?
    let width: Int?
    let aperture: String?
    let colorTag: Int?
    let editable: Bool?
    let focalLength: String?
    let iso: String?
    let rating: Int?
    let shutterSpeed: String?

    enum CodingKeys: String, CodingKey {
        case height = "kVariantProperty_Height"
        case width = "kVariantProperty_Width"
        case aperture = "kVariantProperty_Aperture"
        case colorTag = "kVariantProperty_Colortag"
        case editable = "kVariantProperty_Editable"
        case focalLength = "kVariantProperty_FocalLength"
        case iso = "kVariantProperty_ISO"
        case rating = "kVariantProperty_Rating"
        case shutterSpeed = "kVariantProperty_ShutterSpeed"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle height/width as either Int or Double (server sends floating-point)
        if let heightDouble = try? container.decode(Double.self, forKey: .height) {
            height = Int(heightDouble.rounded())
        } else {
            height = try? container.decode(Int.self, forKey: .height)
        }

        if let widthDouble = try? container.decode(Double.self, forKey: .width) {
            width = Int(widthDouble.rounded())
        } else {
            width = try? container.decode(Int.self, forKey: .width)
        }

        // Decode other properties normally
        aperture = try? container.decode(String.self, forKey: .aperture)
        colorTag = try? container.decode(Int.self, forKey: .colorTag)
        editable = try? container.decode(Bool.self, forKey: .editable)
        focalLength = try? container.decode(String.self, forKey: .focalLength)
        iso = try? container.decode(String.self, forKey: .iso)
        rating = try? container.decode(Int.self, forKey: .rating)
        shutterSpeed = try? container.decode(String.self, forKey: .shutterSpeed)
    }
}

// MARK: - Flexible Value Decoding

struct AnyCodableValue: Decodable, @unchecked Sendable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else {
            value = ""
        }
    }

    var stringValue: String {
        switch value {
        case let s as String: return s
        case let i as Int: return String(i)
        case let d as Double: return String(d)
        case let b as Bool: return b ? "true" : "false"
        default: return ""
        }
    }

    var intValue: Int? {
        switch value {
        case let i as Int: return i
        case let s as String: return Int(s)
        default: return nil
        }
    }

    var boolValue: Bool {
        switch value {
        case let b as Bool: return b
        case let s as String: return s.lowercased() == "true" || s == "1" || s.lowercased() == "enabled"
        case let i as Int: return i != 0
        default: return false
        }
    }
}
