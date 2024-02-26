// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DyteUiKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "DyteUiKit", targets: ["DyteUiKit","DyteiOSCore", "DyteWebRTC", "AmazonIVSPlayer"]),
    ],
    targets: [
        .target(name: "DyteUiKit",
                path: "DyteUiKit/",
                resources: [.process("Resources/notification_join.mp3"),
                            .process("Resources/notification_message.mp3")]),
        .binaryTarget(
            name: "DyteWebRTC",
            url: "https://dyte-assets.s3.ap-south-1.amazonaws.com/sdk/ios_core/DyteWebRTC_v0.0.4.zip",
            checksum: "25318dfb4bd018fde6ed7fd3337d9aa1c62fc8b39ab985c60fa530eb3819e68a"
        ),
        .binaryTarget(
            name: "DyteiOSCore",
            url: "https://dyte-assets.s3.ap-south-1.amazonaws.com/sdk/ios_core/DyteiOSCore-1.32.2-e709b5d3-524b-4ad9-b7dd-a9c241f952a7.xcframework.zip",
            checksum: "e23c4eb3f2374177dc382524ab80a60f21465059e9a7e98a4046f5e04604d22b"
        ),
        .binaryTarget(
            name: "AmazonIVSPlayer",
            url: "https://github.com/dyte-in/AmazonIVSPlayer/archive/refs/tags/0.0.1.zip",
            checksum: "6476a3ecd74acac0a11b6b772c579326c9606028b1389dda0dfb21b5beb2d204"
        )
    ]
)

