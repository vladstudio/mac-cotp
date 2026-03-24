// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "COTP",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "COTP",
            path: "Sources"
        )
    ]
)
