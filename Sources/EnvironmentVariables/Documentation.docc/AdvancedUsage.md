# Advanced Usage

Explore advanced patterns and techniques for using EnvironmentVariables in complex applications.

## Environment Configuration Strategies

### Built-in Multi-File Loading

Use the built-in environment configuration system for automatic file loading and precedence:

```swift
extension EnvironmentVariables {
    public static func configured() throws -> Self {
        let environment = ProcessInfo.processInfo.environment["APP_ENV"] ?? "development"
        
        return try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: environment
            ),
            requiredKeys: Self.requiredKeysForEnvironment(environment)
        )
    }
    
    private static func requiredKeysForEnvironment(_ environment: String) -> Set<String> {
        var keys: Set<String> = ["API_KEY", "DATABASE_URL"]
        
        if environment == "production" {
            keys.insert("SENTRY_DSN")
            keys.insert("ANALYTICS_KEY")
        }
        
        return keys
    }
}
```

### Configuration Options

Choose the appropriate configuration strategy for your needs:

```swift
// Process environment only
let env = try EnvironmentVariables.live(
    environmentConfiguration: .none
)

// Single file (legacy approach)
let env = try EnvironmentVariables.live(
    environmentConfiguration: .singleFile(URL(fileURLWithPath: ".env.local"))
)

// Project-based with environment-specific overrides
let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL.projectRoot,
        environment: "staging"  // Loads .env + .env.staging
    )
)
```

### Mixed File Formats

The system automatically detects and supports both KEY=VALUE and JSON formats:

```swift
// Base configuration in KEY=VALUE format (.env)
APP_NAME=My Application
DEBUG=false
DATABASE_HOST=localhost

// Environment-specific in JSON format (.env.testing)
{
    "DEBUG": "true",
    "DATABASE_NAME": "myapp_test",
    "TEST_MODE": "true"
}

// Automatic format detection and merging
let env = try EnvironmentVariables.live(
    environmentConfiguration: .projectRoot(
        URL.projectRoot,
        environment: "testing"
    )
)
// Result: Combines KEY=VALUE base with JSON overrides
```

### Environment Variable Validation

Add validation logic to ensure environment variables meet your requirements:

```swift
extension EnvironmentVariables {
    public func validate() throws {
        // Validate URLs
        if let dbURL = self["DATABASE_URL"], !dbURL.starts(with: "postgresql://") {
            throw ValidationError.invalidDatabaseURL
        }
        
        // Validate port range
        if let port = self.int("PORT"), !(1...65535).contains(port) {
            throw ValidationError.invalidPort(port)
        }
        
        // Validate API key format
        if let apiKey = self["API_KEY"], apiKey.count < 32 {
            throw ValidationError.weakAPIKey
        }
    }
    
    enum ValidationError: LocalizedError {
        case invalidDatabaseURL
        case invalidPort(Int)
        case weakAPIKey
        
        var errorDescription: String? {
            switch self {
            case .invalidDatabaseURL:
                return "DATABASE_URL must be a valid PostgreSQL URL"
            case .invalidPort(let port):
                return "PORT \(port) is outside valid range (1-65535)"
            case .weakAPIKey:
                return "API_KEY must be at least 32 characters long"
            }
        }
    }
}
```

## Complex Type Conversions

### Custom Type Support

Extend EnvironmentVariables to support custom types:

```swift
import Foundation

extension EnvironmentVariables {
    /// Parse comma-separated values into an array
    public func array(_ key: String, separator: String = ",") -> [String]? {
        self[key]?.components(separatedBy: separator)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Parse time intervals (e.g., "30s", "5m", "1h")
    public func timeInterval(_ key: String) -> TimeInterval? {
        guard let value = self[key] else { return nil }
        
        let scanner = Scanner(string: value)
        var number: Double = 0
        
        guard scanner.scanDouble(&number) else { return nil }
        
        let unit = value.trimmingCharacters(in: .decimalDigits + .whitespaces)
        
        switch unit.lowercased() {
        case "s", "sec", "second", "seconds":
            return number
        case "m", "min", "minute", "minutes":
            return number * 60
        case "h", "hr", "hour", "hours":
            return number * 3600
        default:
            return Double(value) // Assume seconds if no unit
        }
    }
    
    /// Parse data sizes (e.g., "100MB", "2GB")
    public func dataSize(_ key: String) -> Int? {
        guard let value = self[key] else { return nil }
        
        let scanner = Scanner(string: value)
        var number: Double = 0
        
        guard scanner.scanDouble(&number) else { return nil }
        
        let unit = value.trimmingCharacters(in: .decimalDigits + .whitespaces)
        
        switch unit.uppercased() {
        case "B", "":
            return Int(number)
        case "KB":
            return Int(number * 1024)
        case "MB":
            return Int(number * 1024 * 1024)
        case "GB":
            return Int(number * 1024 * 1024 * 1024)
        default:
            return nil
        }
    }
}
```

### Enum Support

Support environment variables that map to enum cases:

```swift
extension EnvironmentVariables {
    public func enumValue<T: RawRepresentable>(_ key: String, type: T.Type) -> T? 
    where T.RawValue == String {
        self[key].flatMap { T(rawValue: $0) }
    }
}

// Usage
enum LogLevel: String {
    case debug, info, warning, error
}

let logLevel = env.enumValue("LOG_LEVEL", type: LogLevel.self) ?? .info
```

## Integration Patterns

### Feature Flags

Use environment variables for feature flags:

```swift
struct FeatureFlags {
    @Dependency(\.envVars) var env
    
    var isNewDashboardEnabled: Bool {
        env.bool("FEATURE_NEW_DASHBOARD") ?? false
    }
    
    var maxUploadSize: Int {
        env.dataSize("MAX_UPLOAD_SIZE") ?? 10_485_760 // 10MB default
    }
    
    var apiRateLimit: Int {
        env.int("API_RATE_LIMIT") ?? 100
    }
    
    var maintenanceMode: Bool {
        env.bool("MAINTENANCE_MODE") ?? false
    }
}
```

### Database Configuration

Create structured configuration from environment variables:

```swift
struct DatabaseConfig {
    let url: URL
    let maxConnections: Int
    let connectionTimeout: TimeInterval
    let enableSSL: Bool
    
    init(env: EnvironmentVariables) throws {
        guard let urlString = env["DATABASE_URL"],
              let url = URL(string: urlString) else {
            throw ConfigError.missingDatabaseURL
        }
        
        self.url = url
        self.maxConnections = env.int("DB_MAX_CONNECTIONS") ?? 10
        self.connectionTimeout = env.timeInterval("DB_TIMEOUT") ?? 30
        self.enableSSL = env.bool("DB_SSL") ?? true
    }
}
```

## Security Considerations

### Secrets Management

Never log sensitive environment variables:

```swift
extension EnvironmentVariables {
    private static let sensitiveKeys: Set<String> = [
        "API_KEY", "DATABASE_URL", "JWT_SECRET", "AWS_SECRET_ACCESS_KEY"
    ]
    
    public var redactedDescription: String {
        dictionary.map { key, value in
            if Self.sensitiveKeys.contains(key) {
                return "\(key)=***REDACTED***"
            } else {
                return "\(key)=\(value)"
            }
        }.joined(separator: ", ")
    }
}
```

### Runtime Secret Rotation

Support dynamic secret updates:

```swift
extension EnvironmentVariables {
    public mutating func updateSecret(_ key: String, newValue: String) {
        self[key] = newValue
        Logger(label: "security").info("Secret \(key) was updated")
    }
    
    public func withTemporaryValue<T>(
        _ key: String, 
        value: String, 
        operation: () throws -> T
    ) rethrows -> T {
        var copy = self
        let original = copy[key]
        copy[key] = value
        defer { copy[key] = original }
        return try operation()
    }
}
```

## Performance Optimization

### Lazy Loading

Load environment variables on-demand:

```swift
extension EnvironmentVariables {
    private static var _shared: EnvironmentVariables?
    private static let lock = NSLock()
    
    public static var shared: EnvironmentVariables {
        get throws {
            lock.lock()
            defer { lock.unlock() }
            
            if let existing = _shared {
                return existing
            }
            
            let instance = try EnvironmentVariables.live()
            _shared = instance
            return instance
        }
    }
    
    public static func reload() throws {
        lock.lock()
        defer { lock.unlock() }
        
        _shared = try EnvironmentVariables.live()
    }
}
```