// swift-tools-version:5.9

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
    static var dependenciesTestSupport: Self { .product(name: "DependenciesTestSupport", package: "swift-dependencies") }
    static var logging: Self { .product(name: "Logging", package: "swift-log") }
}

let package = Package(
    name: "swift-environment-variables",
    platforms: [
      .iOS(.v13),
      .macOS(.v10_15),
      .tvOS(.v13),
      .watchOS(.v6),
    ],
    products: [
        .library(name: .envVars, targets: [.environmentVariables]),
        .library(name: .environmentVariables, targets: [.environmentVariables]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.2"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.4"),
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
            name: .environmentVariables.tests,
            dependencies: [
                .environmentVariables,
                .dependenciesTestSupport
            ]
        )
    ]
)

extension String { var tests: Self { self + " Tests" } }
