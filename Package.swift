// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DyteUiKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "DyteUiKit", targets: ["DyteUiKit", "AmazonIVSPlayer","DyteiOSCore", "WebRTC"]),
    ],
    targets: [
        .binaryTarget(
            name: "DyteUiKit",
            url: "https://github.com/dyte-in/ios-uikit-framework/archive/refs/tags/0.4.2.zip",
            checksum: "59a70befeb000013494138bfa4bf7462d88fb31ae0a1fa7df6efee014c5747c8"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/jitsi/webrtc/releases/download/v111.0.2/WebRTC.xcframework.zip",
            checksum: "5033f23040628e76baa3a9c83c28d89e86ce8127a5a83b5b7d077ede24182b07"
        ),
        .binaryTarget(
            name: "DyteiOSCore",
            url: "https://dyte-assets.s3.ap-south-1.amazonaws.com/sdk/ios_core/DyteiOSCore-1.27.0-b76e4b82-5f18-4e8d-8537-b163afb9312e.xcframework.zip",
            checksum: "3b3ebf7736472122db875935f6f08a6c8f2acde71401c697075d63248f2daa8a"
        ),
        .binaryTarget(
            name: "AmazonIVSPlayer",
            url: "https://github.com/dyte-in/AmazonIVSPlayer/archive/refs/tags/0.0.1.zip",
            checksum: "6476a3ecd74acac0a11b6b772c579326c9606028b1389dda0dfb21b5beb2d204"
        )
    ]
)

