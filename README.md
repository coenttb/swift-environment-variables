# swift-environment-variables

[![CI](https://github.com/coenttb/swift-environment-variables/workflows/CI/badge.svg)](https://github.com/coenttb/swift-environment-variables/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

A type-safe environment variable management system for Swift applications with support for multiple file formats and environment-aware configuration.

## Overview

`swift-environment-variables` provides type-safe access to environment variables with:
- Automatic type conversion for Int, Bool, URL, and String
- Support for both JSON and KEY=VALUE (.env) file formats
- Environment-aware loading with clear precedence rules
- Integration with the Dependencies library for dependency injection
- Required key validation at runtime
- Error handling and logging

## Features

- **Type-safe access**: Dedicated methods for Int, Bool, URL conversions with automatic validation
- **Multiple file formats**: Supports both JSON and standard KEY=VALUE (.env) file formats
- **Environment-aware loading**: Base configuration with environment-specific overrides (.env + .env.development)
- **Clear precedence**: Default values → base .env → environment .env → process environment
- **Required keys validation**: Specify and validate required environment variables at initialization
- **Dependencies integration**: Built-in DependencyKey conformance for clean dependency injection
- **Test support**: Test values and mocking capabilities
- **Error handling**: Custom error types with detailed failure information
- **Logging**: Built-in logging using Swift's Logger

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-environment-variables", from: "0.1.3")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "EnvironmentVariables", package: "swift-environment-variables")
    ]
)
```

## Quick Start

### Using with Dependencies

Extend `EnvironmentVariables` to conform to `DependencyKey`:

```swift
import Dependencies
import EnvironmentVariables
import Foundation

extension EnvironmentVariables: @retroactive DependencyKey {
    public static var liveValue: Self {
        #if DEBUG
        let environment = "development"
        #else
        let environment: String? = nil
        #endif

        return try! EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: environment
            )
        )
    }
}

extension URL {
    public static var projectRoot: URL {
        .init(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
```

Access environment variables using the `@Dependency` property wrapper:

```swift
import Dependencies

struct MyFeature {
    @Dependency(\.envVars) var env

    func configure() throws {
        guard let apiKey = env["API_KEY"] else {
            throw ConfigError.missingApiKey
        }
        let port = env.int("PORT") ?? 8080
    }
}

enum ConfigError: Error {
    case missingApiKey
}
```

### Standalone Usage

```swift
import EnvironmentVariables

let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL(fileURLWithPath: "/path/to/project"),
        environment: "development"
    ),
    requiredKeys: ["APP_SECRET", "DATABASE_URL"]
)

let port: Int? = env.int("PORT")
let isDevelopment: Bool? = env.bool("DEVELOPMENT")
let databaseUrl: URL? = env.url("DATABASE_URL")
let apiKey: String? = env["API_KEY"]
```

## Configuration Strategies

### Project Root Configuration (Recommended)

Create environment files in your project root:

**`.env` (Base configuration):**
```bash
# Base configuration for all environments
APP_NAME=My Application
DEBUG=false
DATABASE_HOST=localhost
DATABASE_PORT=5432
```

**`.env.development` (Development overrides):**
```bash
# Development-specific overrides
DEBUG=true
DATABASE_NAME=myapp_dev
```

Load with environment-specific overrides:

```swift
let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL(fileURLWithPath: "/path/to/project"),
        environment: "development"  // Loads .env + .env.development
    )
)
```

**Precedence order (lowest to highest):**
1. Default values (empty by default)
2. Base `.env` file
3. Environment-specific file (e.g., `.env.development`)
4. Process environment variables

### Single File Configuration

For simpler use cases:

```swift
let env = try EnvironmentVariables.live(
    environmentConfiguration: .singleFile(
        URL(fileURLWithPath: ".env.development")
    )
)
```

### Process Environment Only

Load only from system environment:

```swift
let env = try EnvironmentVariables.live(
    environmentConfiguration: .none
)
```

## File Formats

### KEY=VALUE Format

Standard .env file format with comments and quoted values:

```bash
# API Configuration
API_KEY=my-secret-key
DEBUG=true
DATABASE_URL=postgresql://user:pass@localhost:5432/db

# Inline comments for unquoted values
TIMEOUT=30              # seconds
MAX_RETRIES=5          # number of attempts

# Quoted values for spaces
COMPANY_NAME="My Company"
MESSAGE="Use # in quotes"  # This comment is stripped
```

### JSON Format

```json
{
    "API_KEY": "my-secret-key",
    "DEBUG": "true",
    "DATABASE_URL": "postgresql://user:pass@localhost:5432/db"
}
```

The parser automatically detects the format, trying JSON first, then falling back to KEY=VALUE format.

## Type-Safe Access

### Built-in Type Conversion

```swift
// String access (default)
let apiKey: String? = env["API_KEY"]

// Integer conversion
let port: Int? = env.int("PORT")
let maxConnections: Int? = env.int("MAX_CONNECTIONS")

// Boolean conversion (supports true/false, yes/no, 1/0)
let isDebug: Bool? = env.bool("DEBUG")
let enableLogging: Bool? = env.bool("ENABLE_LOGGING")

// URL conversion
let baseUrl: URL? = env.url("BASE_URL")
let databaseUrl: URL? = env.url("DATABASE_URL")
```

### Custom Property Extensions

Add strongly-typed property access by extending `EnvironmentVariables`:

```swift
extension EnvironmentVariables {
    public var appSecret: String {
        get { self["APP_SECRET"]! }
        set { self["APP_SECRET"] = newValue }
    }

    public var baseUrl: URL {
        get { URL(string: self["BASE_URL"]!)! }
        set { self["BASE_URL"] = newValue.absoluteString }
    }

    public var port: Int {
        get { Int(self["PORT"]!)! }
        set { self["PORT"] = String(newValue) }
    }
}
```

### Optional Properties

For optional environment variables:

```swift
import Logging

extension EnvironmentVariables {
    public var logLevel: Logger.Level? {
        get { self["LOG_LEVEL"].flatMap { Logger.Level(rawValue: $0) } }
        set { self["LOG_LEVEL"] = newValue?.rawValue }
    }

    public var httpsRedirect: Bool? {
        get { self.bool("HTTPS_REDIRECT") }
        set { self["HTTPS_REDIRECT"] = newValue.map { $0 ? "true" : "false" } }
    }
}
```

### Array Variables

For comma-separated values:

```swift
extension EnvironmentVariables {
    public var allowedHosts: [String]? {
        get {
            self["ALLOWED_HOSTS"]?
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set { self["ALLOWED_HOSTS"] = newValue?.joined(separator: ",") }
    }
}
```

## Required Keys Validation

Specify required keys that must be present:

```swift
do {
    let env = try EnvironmentVariables.live(
        environmentConfiguration: .projectRoot(
            URL(fileURLWithPath: "/path/to/project"),
            environment: "production"
        ),
        requiredKeys: ["API_KEY", "DATABASE_URL", "APP_SECRET"]
    )
} catch EnvironmentVariables.Error.missingRequiredKeys(let keys) {
    print("Missing required keys: \(keys)")
}
```

## Error Handling

The library provides two error types:

### EnvironmentVariables.Error

```swift
public enum Error: Swift.Error {
    case missingRequiredKeys([String])
}
```

### EnvironmentVariables.LiveError

```swift
public enum LiveError: Swift.Error {
    case initializationFailed(underlying: Swift.Error)
    case invalidEnvironment(reason: String)
}
```

## Related Packages

### Used By

- [coenttb-web](https://github.com/coenttb/coenttb-web): A Swift package with tools for web development building on swift-web.
- [swift-mailgun-live](https://github.com/coenttb/swift-mailgun-live): A Swift package with live implementations for Mailgun.
- [swift-records](https://github.com/coenttb/swift-records): The Swift library for PostgreSQL database operations.
- [swift-server-foundation](https://github.com/coenttb/swift-server-foundation): A Swift package with tools to simplify server development.
- [swift-stripe-live](https://github.com/coenttb/swift-stripe-live): A Swift package with live implementations for the Stripe API.

### Third-Party Dependencies

- [pointfreeco/swift-dependencies](https://github.com/pointfreeco/swift-dependencies): A dependency management library for controlling dependencies in Swift.
- [apple/swift-log](https://github.com/apple/swift-log): A Logging API for Swift.

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
