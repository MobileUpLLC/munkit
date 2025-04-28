// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "munkit-example-core",
    platforms: [
        .iOS(.v16),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "munkit-example-core",
            targets: ["munkit-example-core"]
        )
    ],
    dependencies: [
        .package(path: "../../munkit")
    ],
    targets: [
        .target(
            name: "munkit-example-core",
            dependencies: [
                .product(name: "munkit", package: "munkit")
            ]
        )
    ]
)
