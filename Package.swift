// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TocaDesk",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TocaDesk", targets: ["TocaDesk"])],
    dependencies: [.package(url: "https://github.com/migueldeicaza/SwiftTerm.git", exact: "1.20.0")],
    targets: [
        .executableTarget(name: "TocaDesk", dependencies: ["SwiftTerm"]),
        .testTarget(name: "TocaDeskTests", dependencies: ["TocaDesk"])
    ]
)
