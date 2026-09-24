// swift-tools-version: 5.9
import Foundation
import PackageDescription

let rustLibrary = ProcessInfo.processInfo.environment["RUST_LIB_DIR"] ?? "../../target/release"

let package = Package(
    name: "ChabotBackgrounder",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "ChabotBackgrounder", targets: ["ChabotBackgrounder"])],
    targets: [
        .systemLibrary(name: "CBackgrounder", path: "Sources/CBackgrounder"),
        .executableTarget(
            name: "ChabotBackgrounder",
            dependencies: ["CBackgrounder"],
            path: "Sources/ChabotBackgrounder",
            linkerSettings: [
                .unsafeFlags(["-L", rustLibrary, "-lbackgrounder_core", "-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
                .linkedFramework("AppKit"),
                .linkedFramework("UserNotifications")
            ]
        )
    ]
)
