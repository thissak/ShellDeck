import Foundation

struct SFTPItem: Identifiable, Hashable {
    let id: String
    var name: String
    var path: String
    var isDirectory: Bool
    var size: UInt64
    var modifiedAt: Date
    var permissions: UInt16
}
