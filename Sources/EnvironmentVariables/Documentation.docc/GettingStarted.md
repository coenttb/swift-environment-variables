# Getting Started with EnvironmentVariables

Learn how to integrate and use EnvironmentVariables in your Swift application.

## Installation

Add EnvironmentVariables to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-environment-variables", from: "0.0.1")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "EnvironmentVariables", package: "swift-environment-variables")
        ]
    )
]
```

## Basic Usage

### Standalone Usage

Create an environment variables instance and access values:

```swift
import EnvironmentVariables

// Initialize with required keys
let env = try EnvironmentVariables.live(requiredKeys: ["API_KEY", "DATABASE_URL"])

// Access values with type safety
let apiKey: String? = env["API_KEY"]
let port: Int? = env.int("PORT")
let isDebug: Bool? = env.bool("DEBUG_MODE")
let baseUrl: URL? = env.url("BASE_URL")
```

### Local Development Configuration

Create a `.env.development` JSON file for local development:

```json
{
    "API_KEY": "dev-api-key-12345",
    "DATABASE_URL": "postgresql://localhost:5432/myapp_dev",
    "DEBUG_MODE": "true",
    "PORT": "3000"
}
```

Load it in your application:

```swift
let env = try EnvironmentVariables.live(
    localEnvFile: URL(fileURLWithPath: ".env.development"),
    requiredKeys: ["API_KEY", "DATABASE_URL"]
)
```

## Using with Dependencies

### Setting Up the Dependency

First, conform EnvironmentVariables to `DependencyKey`:

```swift
import Dependencies
import EnvironmentVariables

extension EnvironmentVariables: @retroactive DependencyKey {
    public static var liveValue: Self {
        let localDevelopment: URL? = {
            #if DEBUG
                return URL.projectRoot.appendingPathComponent(".env.development")
            #else
                return nil
            #endif
        }()
        
        return try! EnvironmentVariables.live(
            localEnvFile: localDevelopment,
            requiredKeys: ["API_KEY", "DATABASE_URL"]
        )
    }
}

// Helper for finding the project root
extension URL {
    public static var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
```

### Using in Your Features

Access environment variables using the `@Dependency` property wrapper:

```swift
import Dependencies

struct APIClient {
    @Dependency(\.envVars) var env
    
    func makeRequest() async throws {
        guard let apiKey = env["API_KEY"] else {
            throw APIError.missingAPIKey
        }
        
        let baseURL = env.url("BASE_URL") ?? URL(string: "https://api.example.com")!
        // Make your API request...
    }
}
```

## Type-Safe Extensions

Create type-safe properties for commonly used environment variables:

```swift
extension EnvironmentVariables {
    public var apiKey: String {
        get { self["API_KEY"]! }
        set { self["API_KEY"] = newValue }
    }
    
    public var databaseURL: URL {
        get { URL(string: self["DATABASE_URL"]!)! }
        set { self["DATABASE_URL"] = newValue.absoluteString }
    }
    
    public var port: Int {
        get { self.int("PORT") ?? 3000 }
        set { self["PORT"] = String(newValue) }
    }
    
    public var isDebugMode: Bool {
        get { self.bool("DEBUG_MODE") ?? false }
        set { self["DEBUG_MODE"] = newValue ? "true" : "false" }
    }
}
```

Now you can access environment variables with dot syntax:

```swift
@Dependency(\.envVars) var env

let apiKey = env.apiKey
let port = env.port
let debugMode = env.isDebugMode
```

## Testing

In your tests, use the test value or provide custom values:

```swift
import XCTest
import Dependencies
@testable import YourApp

final class APIClientTests: XCTestCase {
    func testAPIRequest() async throws {
        await withDependencies {
            $0.envVars["API_KEY"] = "test-api-key"
            $0.envVars["BASE_URL"] = "https://test.example.com"
        } operation: {
            let client = APIClient()
            // Test your client...
        }
    }
}
```

## Best Practices

1. **Required Keys**: Always specify required environment variables to catch configuration errors early
2. **Type Safety**: Use the typed accessors (`int`, `bool`, `url`) for better type safety
3. **Local Development**: Use local environment files for development to avoid hardcoding values
4. **Testing**: Override environment variables in tests to ensure predictable test behavior
5. **Security**: Never commit `.env.development` files containing sensitive data to version control