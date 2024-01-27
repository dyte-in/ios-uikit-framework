// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DyteUiKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "DyteUiKit", targets: ["DyteUiKit","DyteiOSCore", "WebRTC", "AmazonIVSPlayer"]),
    ],
    targets: [
        .target(name: "DyteUiKit",
                path: "DyteUiKit/",
                resources: [.process("Resources/notification_join.mp3"),
                            .process("Resources/notification_message.mp3")]),
        .binaryTarget(
            name: "WebRTC",
            url: "https://github.com/jitsi/webrtc/releases/download/v111.0.2/WebRTC.xcframework.zip",
            checksum: "5033f23040628e76baa3a9c83c28d89e86ce8127a5a83b5b7d077ede24182b07"
        ),
         .binaryTarget(
            name: "DyteiOSCore",
            url: "https://dyte-assets.s3.ap-south-1.amazonaws.com/sdk/ios_core/DyteiOSCore-1.30.2-ebffce74-83d4-44fa-87f7-4cce8b1a36af.xcframework.zip",
            checksum: "ab7b08cf7d50a18e6a66a8f8ddceab9d44540c132dbdc18c3742e228e1658058"
        ),
        .binaryTarget(
            name: "AmazonIVSPlayer",
            url: "https://github.com/dyte-in/AmazonIVSPlayer/archive/refs/tags/0.0.1.zip",
            checksum: "6476a3ecd74acac0a11b6b772c579326c9606028b1389dda0dfb21b5beb2d204"
        )
    ]
)

