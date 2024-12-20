// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let envVars: Self = "EnvVars"
    static let environmentVariables: Self = "EnvironmentVariables"
}

extension Target.Dependency {
    static var environmentVariables: Self { .target(name: .environmentVariables) }
}

extension Target.Dependency {
    static var dependencies: Self { .product(name: "Dependencies", package: "swift-dependencies") }
    static var dependenciesMacros: Self { .product(name: "DependenciesMacros", package: "swift-dependencies") }
    static var logging: Self { .product(name: "Logging", package: "swift-log") }
}

let package = Package(
    name: "swift-environment-variables",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: .envVars, targets: [.environmentVariables]),
        .library(name: .environmentVariables, targets: [.environmentVariables]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.1.5"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: .environmentVariables,
            dependencies: [
                .dependencies,
                .logging,
            ]
        ),
        .testTarget(
            name: .environmentVariables + " Tests",
            dependencies: [.environmentVariables]
        )
    ],
    swiftLanguageModes: [.v6]
)
