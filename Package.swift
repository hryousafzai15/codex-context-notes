// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexContextNotes",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CodexContextNotes", targets: ["CodexContextNotes"])
    ],
    targets: [
        .executableTarget(
            name: "CodexContextNotes",
            path: "Sources/CodexContextNotes",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CodexContextNotesTests",
            dependencies: ["CodexContextNotes"],
            path: "Tests/CodexContextNotesTests"
        )
    ]
)
