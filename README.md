# swift-environment-variables

A type-safe environment variable management system for Swift applications.

![Version](https://img.shields.io/badge/version-0.1.3-green.svg)
![Swift](https://img.shields.io/badge/swift-6.0-orange.svg)
![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)

## Features

* **Type-safe environment access**: Access environment variables with type conversion support for Int, Bool, URL, and String
* **Multiple file format support**: Supports both JSON and standard KEY=VALUE (.env) file formats
* **Environment-aware loading**: Automatically loads base configuration and environment-specific overrides
* **Layered configuration**: Clear precedence order from defaults → base files → environment files → process environment
* **Required keys validation**: Specify and validate required environment variables at runtime
* **Dependencies integration**: Built-in support for the Dependencies package for clean dependency injection
* **Test support**: Includes test helpers and mock values for testing
* **Error handling**: Comprehensive error handling with custom error types
* **Logging integration**: Built-in logging support using Swift's Logger

## Quick Start

### Using with Dependencies

To use environment variables with [Dependencies](https://github.com/pointfreeco/swift-dependencies), conform to `DependencyKey`:

```swift
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

// Helper for finding the project root
extension URL {
    public static var projectRoot: URL {
        .init(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
```

This setup:
- Uses `@retroactive` to conform to `DependencyKey`
- Automatically loads `.env` + `.env.development` in DEBUG builds
- Loads only `.env` + process environment in production
- Supports environment-specific configuration overrides

Access environment variables using the `@Dependency` property wrapper:

```swift
import Dependencies

struct MyFeature {
    @Dependency(\.envVars) var env
    
    func configure() throws {
        guard let apiKey = env["API_KEY"] else {
            throw ConfigError.missingApiKey
        }
        // Use apiKey...
    }
}
```

### Standalone Usage

```swift
import EnvironmentVariables

// Initialize with environment-aware configuration
let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL(fileURLWithPath: "/path/to/project"),
        environment: "development"
    ),
    requiredKeys: ["APP_SECRET", "DATABASE_URL"]
)

// Access values with type safety
let port: Int? = env.int("PORT")
let isDevelopment: Bool? = env.bool("DEVELOPMENT")
let databaseUrl: URL? = env.url("DATABASE_URL")
let apiKey: String? = env["API_KEY"]
```

### Environment Configuration System

The package supports multiple configuration strategies with clear precedence:

#### Project-Based Loading (Recommended)

Create environment files in your project root:

**`.env` (Base configuration):**
```bash
# Base configuration for all environments
APP_NAME=My Application
DEBUG=false
DATABASE_HOST=localhost
DATABASE_PORT=5432
CACHE_TTL=3600
```

**`.env.development` (Development overrides):**
```bash
# Development-specific overrides
DEBUG=true
DATABASE_NAME=myapp_dev
CACHE_TTL=60
DEV_TOOLS_ENABLED=true
```

**`.env.production` (Production overrides):**
```bash
# Production-specific overrides
DEBUG=false
DATABASE_NAME=myapp_prod
CACHE_TTL=7200
ENABLE_METRICS=true
```

#### Loading with Precedence

```swift
let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL(fileURLWithPath: "/path/to/project"),
        environment: "development"  // Loads .env + .env.development
    )
)
```

**Precedence Order (lowest to highest):**
1. Default values (empty by default)
2. Base `.env` file
3. Environment-specific file (e.g., `.env.development`)
4. Process environment variables

#### Single File Loading

For simpler use cases, load a single environment file:

```swift
let env = try EnvironmentVariables.live(
    environmentConfiguration: .singleFile(
        URL(fileURLWithPath: ".env.development")
    )
)
```

#### Supported File Formats

Both **KEY=VALUE** (.env) and **JSON** formats are supported:

**KEY=VALUE format:**
```bash
API_KEY=my-secret-key
DEBUG=true
DATABASE_URL=postgresql://user:pass@localhost:5432/db
```

**JSON format:**
```json
{
    "API_KEY": "my-secret-key",
    "DEBUG": "true",
    "DATABASE_URL": "postgresql://user:pass@localhost:5432/db"
}
```

## Configuration Options

The `EnvironmentConfiguration` enum provides three loading strategies:

### `.none`
Load only from process environment variables:
```swift
let env = try EnvironmentVariables.live(
    environmentConfiguration: .none
)
```

### `.singleFile(URL)`
Load from a single environment file:
```swift
let env = try EnvironmentVariables.live(
    environmentConfiguration: .singleFile(
        URL(fileURLWithPath: "/path/to/.env.development")
    )
)
```

### `.projectRoot(URL, environment: String?)`
Load base configuration with optional environment-specific overrides:
```swift
// Load only .env
let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL(fileURLWithPath: "/path/to/project"),
        environment: nil
    )
)

// Load .env + .env.staging
let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL(fileURLWithPath: "/path/to/project"),
        environment: "staging"
    )
)
```

## Advanced Usage

### Adding Type-Safe Property Access

While dictionary-style access (`env["KEY"]`) is always available, you can add strongly-typed property access by extending `EnvironmentVariables`:

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

### Optional Variables

For optional environment variables, use optional types:

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

For environment variables that contain comma-separated values:

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

This approach provides:
- Type safety: Variables are converted to their proper Swift types
- Auto-completion: Access environment variables using dot syntax
- Default values: Can specify defaults for optional variables
- Validation: Add validation logic in the getter if needed

## Installation

You can add `swift-environment-variables` to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Add Packages...**
2. Enter "https://github.com/coenttb/swift-environment-variables" into the package repository URL text field
3. Link the package to your target

For a Swift Package Manager project, add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-environment-variables", from: "0.0.1")
]
```

## Related projects

* [coenttb/swift-web](https://www.github.com/coenttb/swift-web): Modular tools to simplify web development in Swift
* [coenttb/coenttb-com-server](https://www.github.com/coenttb/coenttb-com-server): The backend server for coenttb.com that uses EnvironmentVariables.

## Feedback is much appreciated!

If you're working on your own Swift project, feel free to learn, fork, and contribute.

Got thoughts? Found something you love? Something you hate? Let me know! Your feedback helps make this project better for everyone. Open an issue or start a discussion—I'm all ears.

> [Subscribe to my newsletter](http://coenttb.com/en/newsletter/subscribe)
>
> [Follow me on X](http://x.com/coenttb)
> 
> [Link on Linkedin](https://www.linkedin.com/in/tenthijeboonkkamp)

## Acknowledgements
This project builds upon foundational work by Point-Free (Brandon Williams and Stephen Celis). This package is inspired by their approach on `pointfreeco`.

## License

This project is licensed by coenttb under the **Apache 2.0 License**.
See [LICENSE](LICENSE) for details.
