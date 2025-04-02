// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MUNKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MUNKit",
            targets: ["MUNKit"]),
    ],
    dependencies: [
           .package(url: "https://github.com/Moya/Moya.git", exact: "15.0.3")
    ],
    targets: [
        .target(
            name: "MUNKit",
            dependencies: [
                .product(name: "Moya", package: "Moya")
            ]
        )
    ]
)
