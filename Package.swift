// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DyteUiKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "DyteUiKit", targets: ["DyteUiKitTargets"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dyte-in/DyteMobileCoreiOS.git", branch: "main")
    ],
    targets: [
        .binaryTarget(name: "DyteUiKit", path: "Sources/ios-uikit-framework/DyteUiKit.xcframework.zip"),
        .target(
            name: "DyteUiKitTargets",
            dependencies: [
                .product(name: "DyteiOSCore", package: "DyteMobileCoreiOS"),
                "DyteUiKit"
            ],
            path: "Sources/ios-uikit-framework/"
        )
    ]
)
