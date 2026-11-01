// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Velopaste",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Velopaste", targets: ["Velopaste"])],
    targets: [
        .executableTarget(name: "Velopaste"),
        .testTarget(name: "VelopasteTests", dependencies: ["Velopaste"])
    ]
)
