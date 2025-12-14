import Foundation
import CryptoKit

enum SHA1Hasher {
    static func hash(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
