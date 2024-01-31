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
            url: "https://dyte-assets.s3.ap-south-1.amazonaws.com/sdk/ios_core/DyteiOSCore-1.31.3-08f2b1f7-2a08-48d5-a698-eb381e9dc326.xcframework.zip",
            checksum: "91103336f6a8e6eb58daf6c0718dc6c8a1b23ea34d200972d584ef6c3cfaa0f3"
        ),
        .binaryTarget(
            name: "AmazonIVSPlayer",
            url: "https://github.com/dyte-in/AmazonIVSPlayer/archive/refs/tags/0.0.1.zip",
            checksum: "6476a3ecd74acac0a11b6b772c579326c9606028b1389dda0dfb21b5beb2d204"
        )
    ]
)

