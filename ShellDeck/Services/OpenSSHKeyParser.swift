import Foundation
import Crypto

enum OpenSSHKeyError: Error {
    case invalidBase64
    case invalidMagic
    case unsupportedKeyType(String)
    case encryptedKeyNotSupported
    case invalidKeyData
}

enum OpenSSHKeyParser {

    /// Parses an OpenSSH ed25519 private key file and returns a Curve25519.Signing.PrivateKey
    static func parseEd25519(from fileContent: String) throws -> Curve25519.Signing.PrivateKey {
        let lines = fileContent.components(separatedBy: "\n")
            .filter { !$0.hasPrefix("-----") && !$0.isEmpty }
        let base64Str = lines.joined()
        guard let data = Data(base64Encoded: base64Str) else {
            throw OpenSSHKeyError.invalidBase64
        }
        let bytes = [UInt8](data)

        let magic = "openssh-key-v1\0"
        guard bytes.count > magic.count,
              String(bytes: bytes.prefix(magic.count), encoding: .utf8) == magic else {
            throw OpenSSHKeyError.invalidMagic
        }

        var offset = magic.count

        let cipherName = try readString(bytes, at: &offset)
        if cipherName != "none" {
            throw OpenSSHKeyError.encryptedKeyNotSupported
        }

        _ = try readString(bytes, at: &offset) // kdf
        _ = try readString(bytes, at: &offset) // kdfoptions
        offset += 4 // numkeys

        _ = try readBytes(bytes, at: &offset) // public key section

        // Private section
        _ = try readUInt32(bytes, at: &offset) // private section length
        offset += 8 // check1 + check2

        let keyType = try readString(bytes, at: &offset)
        guard keyType == "ssh-ed25519" else {
            throw OpenSSHKeyError.unsupportedKeyType(keyType)
        }

        _ = try readBytes(bytes, at: &offset) // public key in private section

        // Private key: 64 bytes (32 seed + 32 public)
        let privKeyBytes = try readBytes(bytes, at: &offset)
        guard privKeyBytes.count == 64 else {
            throw OpenSSHKeyError.invalidKeyData
        }
        let seed = Array(privKeyBytes.prefix(32))

        return try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
    }

    private static func readUInt32(_ bytes: [UInt8], at offset: inout Int) throws -> UInt32 {
        guard offset + 4 <= bytes.count else { throw OpenSSHKeyError.invalidKeyData }
        let v = UInt32(bytes[offset]) << 24 | UInt32(bytes[offset+1]) << 16 |
                UInt32(bytes[offset+2]) << 8 | UInt32(bytes[offset+3])
        offset += 4
        return v
    }

    private static func readBytes(_ bytes: [UInt8], at offset: inout Int) throws -> [UInt8] {
        let len = Int(try readUInt32(bytes, at: &offset))
        guard offset + len <= bytes.count else { throw OpenSSHKeyError.invalidKeyData }
        let result = Array(bytes[offset..<(offset + len)])
        offset += len
        return result
    }

    private static func readString(_ bytes: [UInt8], at offset: inout Int) throws -> String {
        let data = try readBytes(bytes, at: &offset)
        return String(bytes: data, encoding: .utf8) ?? ""
    }
}
