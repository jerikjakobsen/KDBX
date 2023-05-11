// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KDBX",
    products: [
        .library(
            name: "KDBX",
            targets: ["KDBX"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tmthecoder/Argon2Swift", branch: "main"),
        .package(url: "https://github.com/1024jp/GzipSwift", from: Version(6, 0, 0)),
        //.package(url: "https://github.com/jedisct1/swift-sodium", branch: "master"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.7.1")),
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "KDBX",
            dependencies: [
                .product(name: "Gzip", package: "GzipSwift"),
                .product(name: "SWXMLHash", package: "SWXMLHash"),
                "StreamCiphers",
                "Encryption"
            ]
        ),
        .target(
            name: "StreamCiphers",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift"),
            ]
        ),
        .target(
            name: "Encryption",
            dependencies: [
                .product(name: "Argon2Swift", package: "Argon2Swift"),
            ]
        ),
        .testTarget(
            name: "KDBXTests",
            dependencies: ["KDBX"]),
    ]
)
