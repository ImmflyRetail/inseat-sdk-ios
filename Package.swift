// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Inseat",
    products: [
        .library(
            name: "Inseat", 
            targets: [
                "Inseat"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/getditto/DittoSwiftPackage", exact: "4.10.2")
    ],
    targets: [
        .target(
            name: "Inseat",
            dependencies: [
                .target(name: "InseatFramework"),
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ]
        ),
        .binaryTarget(
            name: "InseatFramework",
            url: "https://app-cdn.immflyretail.link/inseat-ios-sdk/1.0.0/Inseat.xcframework.zip",
            checksum: "43f2418bf2acded2311b37f95782ce0bdcfd64b443c2b610d06f3d79b54b0246"
        )
    ]
)
