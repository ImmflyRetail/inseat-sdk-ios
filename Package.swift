// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Inseat",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Inseat", 
            targets: [
                "InseatWrapper"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/getditto/DittoSwiftPackage", exact: "4.10.2")
    ],
    targets: [
        .target(
            name: "InseatWrapper",
            dependencies: [
                .target(name: "InseatFramework"),
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ]
        ),
        .binaryTarget(
            name: "InseatFramework",
            url: "https://app-cdn.immflyretail.live/inseat-ios-sdk/0.1.3/Inseat.xcframework.zip",
            checksum: "4a2d40e68e1289ad03666c9e694432757e77857402c898596251640b814f4769"
        )
    ]
)
