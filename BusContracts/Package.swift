// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BusContracts",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BusContracts", targets: ["BusContracts"])
    ],
    targets: [
        .target(name: "BusContracts", path: "Sources/BusContracts"),
        .testTarget(
            name: "BusContractsTests",
            dependencies: ["BusContracts"],
            path: "Tests/BusContractsTests"
        )
    ]
)
