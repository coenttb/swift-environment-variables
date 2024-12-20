
# swift-environment-variables

A type-safe environment variable management system for Swift applications, built with [Dependencies](https://github.com/pointfreeco/swift-dependencies).

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

This package is currently in active development and is subject to frequent changes. Features and APIs may change without prior notice until a stable release is available.

## Features

* **Type-safe environment access**: Access environment variables with type conversion support for Int, Bool, URL, and String
* **Required keys validation**: Specify and validate required environment variables at runtime
* **Layered configuration**: Load from process environment, local development files, and defaults with clear precedence
* **Dependencies integration**: Built-in support for the Dependencies package for clean dependency injection
* **Test support**: Includes test helpers and mock values for testing
* **Error handling**: Comprehensive error handling with custom error types
* **Logging integration**: Built-in logging support using Swift's Logger

## Basic Usage

```swift
import EnvironmentVariables

// Initialize with process environment variables
let env = try EnvVars.live(requiredKeys: ["APP_SECRET", "DATABASE_URL"])

// Access values with type safety
let port: Int? = env.int("PORT")
let isDevelopment: Bool? = env.bool("DEVELOPMENT")
let databaseUrl: URL? = env.url("DATABASE_URL")
let apiKey: String? = env["API_KEY"]
```

### Local Development Support

```swift
// Load from a local JSON file for development
let env = try EnvVars.live(
    localDevelopment: URL(fileURLWithPath: "config.local.json"),
    requiredKeys: ["APP_SECRET"]
)
```

### Dependencies Integration

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

## Adding Type-Safe Property Access

While dictionary-style access (`env["KEY"]`) is always available, you can add strongly-typed property access by extending `EnvVars`:

```swift
extension EnvVars {
    public var appSecret: AppSecret {
        get { AppSecret(self["APP_SECRET"]!)! }
        set { self["APP_SECRET"] = newValue.rawValue }
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
extension EnvVars {
    public var logLevel: Logger.Level? {
        get { self["LOG_LEVEL"].flatMap { Logger.Level(rawValue: $0) } }
        set { self["LOG_LEVEL"] = newValue?.rawValue }
    }
    
    public var httpsRedirect: Bool? {
        get { self["HTTPS_REDIRECT"].map { $0 == "true" } }
        set { self["HTTPS_REDIRECT"] = newValue.map { $0 ? "true" : "false" } }
    }
}
```

### Array Variables

For environment variables that contain comma-separated values:

```swift
extension EnvVars {
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
    .package(url: "https://github.com/coenttb/swift-environment-variables", branch: "main")
]
```

## Related projects

* [coenttb/swift-web](https://www.github.com/coenttb/swift-web): Modular tools to simplify web development in Swift
* [coenttb/coenttb-web](https://www.github.com/coenttb/coenttb-web): A collection of features for your Swift server
* [coenttb/coenttb-com-server](https://www.github.com/coenttb/coenttb-com-server): The backend server for coenttb.com

## Feedback is much appreciated!

If you're working on your own Swift project, feel free to learn, fork, and contribute.

Got thoughts? Found something you love? Something you hate? Let me know! Your feedback helps make this project better for everyone. Open an issue or start a discussion—I'm all ears.

> [Subscribe to my newsletter](http://coenttb.com/en/newsletter/subscribe)
>
> [Follow me on X](http://x.com/coenttb)
> 
> [Link on Linkedin](https://www.linkedin.com/in/tenthijeboonkkamp)

## License

This project is licensed by coenttb under the **Apache 2.0 License**.
See [LICENSE](LICENSE) for details.
