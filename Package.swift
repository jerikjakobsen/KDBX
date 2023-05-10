// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KDBX",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "KDBX",
            targets: ["KDBX"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/tmthecoder/Argon2Swift", branch: "main"),
        .package(url: "https://github.com/1024jp/GzipSwift", from: Version(6, 0, 0)),
        //.package(url: "https://github.com/jedisct1/swift-sodium", branch: "master"),
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "KDBX",
            dependencies: [
                .product(name: "Argon2Swift", package: "Argon2Swift"),
                .product(name: "Gzip", package: "GzipSwift"),
                //.product(name: "Sodium", package: "Swift-Sodium"),
                //.product(name: "Clibsodium", package: "Swift-Sodium"),
                .product(name: "SWXMLHash", package: "SWXMLHash")
                
            ]
        ),
        .testTarget(
            name: "KDBXTests",
            dependencies: ["KDBX"]),
    ]
)
