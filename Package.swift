// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tappy",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Tappy", targets: ["Tappy"])
    ],
    targets: [
        .executableTarget(
            name: "Tappy",
            path: "Sources"
        )
    ]
)
