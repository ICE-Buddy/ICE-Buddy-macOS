// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TrainBuddyKit",
    platforms: [.iOS("26.0"), .macOS(.v12)],
    products: [.library(name: "TrainBuddyKit", targets: ["TrainBuddyKit"])],
    dependencies: [.package(path: "../DBConnect")],
    targets: [
        .target(name: "TrainBuddyKit", dependencies: [
            .product(name: "TrainConnect", package: "DBConnect"),
            .product(name: "DBConnect", package: "DBConnect"),
            .product(name: "SNCFConnect", package: "DBConnect"),
            .product(name: "OnboardConnect", package: "DBConnect")
        ]),
        .testTarget(name: "TrainBuddyKitTests", dependencies: ["TrainBuddyKit"])
    ]
)
