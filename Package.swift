// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Fastboard",
    defaultLocalization: "en",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "Fastboard",
            targets: ["Fastboard", "FastboardDynamic"]
        ),
    ],
    dependencies: [
        .package(name: "Whiteboard", url: "https://github.com/netless-io/Whiteboard-iOS.git", from: .init(2, 16, 81)),
    ],
    targets: [
        .target(
            name: "Fastboard",
            dependencies: ["Whiteboard", "FastboardDynamic"],
            path: "Fastboard",
            exclude: [
                "Classes/Load.m",
                "Classes/Proxy/FastProxy.m",
            ],
            sources: ["Classes"],
            resources: [
                .process("Assets"),
            ]
        ),
        .target(name: "FastboardDynamic",
                path: "Fastboard",
                sources: [
                    "Classes/Load.m",
                    "Classes/Proxy/FastProxy.m",
                ],
                publicHeadersPath: "Classes/include",
                cSettings: .headers),
    ]
)

extension Array where Element == CSetting {
    static var headers: [Element] {
        [
            .headerSearchPath("Classes/Proxy"),
        ]
    }
}
