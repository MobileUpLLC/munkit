// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "munkit",
    platforms: [
        .iOS(.v16),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "munkit",
            targets: ["munkit"]),
    ],
    dependencies: [
           .package(url: "https://github.com/Moya/Moya.git", exact: "15.0.3")
    ],
    targets: [
        .target(
            name: "munkit",
            dependencies: [
                .product(name: "Moya", package: "Moya")
            ]
        )
    ]
)
