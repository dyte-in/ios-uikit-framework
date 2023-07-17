// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DyteUiKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "DyteUiKit", targets: ["DyteUiKit", "AmazonIVSPlayer","DyteiOSCore", "WebRTC", "DyteiOSSocketIO", "Starscream"]),
    ],
    targets: [
        .binaryTarget(
            name: "DyteUiKit",
            url: "https://github.com/dyte-in/ios-uikit-framework/archive/refs/tags/0.2.7.zip",
            checksum: "7999f86c140cf8a99f4646f91a3d44bf8d4ed74e58c12162c0beb58697abbcb0"
        ),
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/jitsi/webrtc/releases/download/v111.0.2/WebRTC.xcframework.zip",
            checksum: "5033f23040628e76baa3a9c83c28d89e86ce8127a5a83b5b7d077ede24182b07"
        ),
        .binaryTarget(
            name: "DyteiOSCore",
            url: "https://github.com/dyte-in/DyteMobileCoreiOS/archive/refs/tags/0.6.6.zip",
            checksum: "55324513161e431d25e0fa93897b83beb1ce4852e6cf4e5038797d539f0195fe"
        ),
        .binaryTarget(
            name: "DyteiOSSocketIO",
            url: "https://github.com/dyte-in/DyteiOSSocketIO/archive/refs/tags/0.1.3.zip",
            checksum: "ca0ffe1930f5d5f472abb4966b2b814489b463399fb7aa757b2ab8bd3570048e"
        ),
        .binaryTarget(
            name: "Starscream",
            url: "https://github.com/dyte-in/DyteStarscream/archive/refs/tags/0.0.1.zip",
            checksum: "8aa8a8078b74aa4dcb86bf27ce2b46ef51b5e5f731226cd30fbd83ac5d1e633f"
        ),
        .binaryTarget(
            name: "AmazonIVSPlayer",
            url: "https://github.com/Video-io/AmazonIVSPlayer.swift/raw/main/AmazonIVSPlayer.xcframework.zip",
            checksum: "7ae52c6e33b1c7faf2e6bccf9df0206ac9e2608355cfa76f2d8363146b500c49"
        )
    ]
)

