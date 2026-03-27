// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShellDeck",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ShellDeck", targets: ["ShellDeck"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/orlandos-nl/Citadel.git", from: "0.12.0"),
    ],
    targets: [
        .target(
            name: "ShellDeck",
            dependencies: ["KeychainAccess", "Citadel"],
            path: "ShellDeck"
        ),
        .testTarget(
            name: "ShellDeckTests",
            dependencies: ["ShellDeck"],
            path: "ShellDeckTests"
        ),
    ]
)
