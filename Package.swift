// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Granite",
    platforms: [.iOS(.v14), .macOS(.v12)], //Deployment set to v11, for ARM Big Sur+ usage only
    products: [
        .library(
            name: "Granite",
            targets: ["Granite"]),
        .library(
            name: "GraniteUI",
            targets: ["GraniteUI"]),
        
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Granite",
            dependencies: []),
        .testTarget(
            name: "GraniteTests",
            dependencies: ["Granite"]),
        .target(
            name: "GraniteUI",
            dependencies: []),
        .testTarget(
            name: "GraniteUITests",
            dependencies: ["GraniteUI"]),
    ]
)
