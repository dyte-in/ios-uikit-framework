// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "DyteUiKit",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "DyteUiKit",
            targets: ["DyteUiKit"]
        ),
    ],
    dependencies: [.package(url: "https://github.com/dyte-in/DyteMobileCoreiOS.git", from: "0.4.2"),],
    targets: [
        .binaryTarget(
            name: "DyteUiKit",
            url: "https://github.com/dyte-in/ios-uikit-framework/archive/refs/tags/0.2.1.zip",
            checksum: "489ce2e06b09f85027c0d194a44e0a92e43dc822f8c56ffee3aa3730db44ae0b"
        ),
    ]
)
