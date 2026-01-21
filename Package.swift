// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TransactionsFeature",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "TransactionsFeature", targets: ["TransactionsFeature"])
    ],
    dependencies: [
        .package(path: "../SharedDomain"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CorePersistence")
    ],
    targets: [
        .target(
            name: "TransactionsFeature",
            dependencies: [
                "SharedDomain",
                "CoreNetworking",
                "CorePersistence"
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TransactionsFeatureTests",
            dependencies: ["TransactionsFeature"]
        )
    ]
)
