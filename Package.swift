// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LuminaVault",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "LuminaVault",
            targets: ["LuminaVault"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LuminaVault",
            dependencies: [],
            path: "LuminaVault",
            exclude: ["Info.plist", "Resources/Assets.xcassets"]
        ),
    ]
)
