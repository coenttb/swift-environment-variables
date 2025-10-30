//
//  ReadmeVerificationTests.swift
//  swift-environment-variables
//
//  Created by automated README verification
//

import Dependencies
import EnvironmentVariables
import Foundation
import Logging
import Testing

// MARK: - Test Extensions

// Extension from README (lines 64-88)
private extension EnvironmentVariables {
    static func makeTestLiveValue(projectRoot: URL, environment: String?) throws -> Self {
        try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                projectRoot,
                environment: environment
            )
        )
    }
}

// Custom property extensions from README (lines 250-267)
private extension EnvironmentVariables {
    var appSecret: String {
        get { self["APP_SECRET"]! }
        set { self["APP_SECRET"] = newValue }
    }

    var baseUrl: URL {
        get { URL(string: self["BASE_URL"]!)! }
        set { self["BASE_URL"] = newValue.absoluteString }
    }

    var port: Int {
        get { Int(self["PORT"]!)! }
        set { self["PORT"] = String(newValue) }
    }
}

// Optional properties from README (lines 273-287)
private extension EnvironmentVariables {
    var logLevel: Logger.Level? {
        get { self["LOG_LEVEL"].flatMap { Logger.Level(rawValue: $0) } }
        set { self["LOG_LEVEL"] = newValue?.rawValue }
    }

    var httpsRedirect: Bool? {
        get { self.bool("HTTPS_REDIRECT") }
        set { self["HTTPS_REDIRECT"] = newValue.map { $0 ? "true" : "false" } }
    }
}

// Array variables from README (lines 293-304)
private extension EnvironmentVariables {
    var allowedHosts: [String]? {
        get {
            self["ALLOWED_HOSTS"]?
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set { self["ALLOWED_HOSTS"] = newValue?.joined(separator: ",") }
    }
}

@Suite("README Verification")
struct ReadmeVerificationTests {

    // MARK: - Quick Start Examples

    @Test("Using @Dependency Example (lines 93-110)")
    func testDependencyWrapperExample() throws {
        // Example from README
        struct MyFeature {
            @Dependency(\.envVars) var env

            func configure() throws {
                guard env["API_KEY"] != nil else {
                    throw ConfigError.missingApiKey
                }
                _ = env.int("PORT") ?? 8080
            }
        }

        enum ConfigError: Error {
            case missingApiKey
        }

        // Test with dependency override
        try withDependencies {
            $0.envVars = try EnvironmentVariables(
                dictionary: ["API_KEY": "test-key", "PORT": "9000"],
                requiredKeys: []
            )
        } operation: {
            let feature = MyFeature()
            try feature.configure()
        }
    }

    @Test("Standalone Usage Example (lines 114-129)")
    func testStandaloneUsageExample() throws {
        // Create temporary directory for test
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create test .env file
        let envContent = """
        APP_SECRET=test-secret
        DATABASE_URL=postgresql://localhost/testdb
        PORT=8080
        DEVELOPMENT=true
        """
        let envFile = tempDir.appendingPathComponent(".env")
        try envContent.write(to: envFile, atomically: true, encoding: .utf8)

        // Example from README
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                tempDir,
                environment: nil
            ),
            requiredKeys: ["APP_SECRET", "DATABASE_URL"]
        )

        let port: Int? = env.int("PORT")
        let isDevelopment: Bool? = env.bool("DEVELOPMENT")
        let databaseUrl: URL? = env.url("DATABASE_URL")
        let apiKey: String? = env["API_KEY"]

        #expect(port == 8080)
        #expect(isDevelopment == true)
        #expect(databaseUrl?.absoluteString == "postgresql://localhost/testdb")
        #expect(apiKey == nil)
    }

    // MARK: - Configuration Strategies

    @Test("Project Root Configuration Example (lines 155-162)")
    func testProjectRootConfigExample() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create base .env
        let baseEnv = """
        APP_NAME=My Application
        DEBUG=false
        DATABASE_HOST=localhost
        DATABASE_PORT=5432
        """
        try baseEnv.write(to: tempDir.appendingPathComponent(".env"), atomically: true, encoding: .utf8)

        // Create .env.development
        let devEnv = """
        DEBUG=true
        DATABASE_NAME=myapp_dev
        """
        try devEnv.write(to: tempDir.appendingPathComponent(".env.development"), atomically: true, encoding: .utf8)

        // Example from README
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                tempDir,
                environment: "development"  // Loads .env + .env.development
            )
        )

        // Verify precedence
        #expect(env["DEBUG"] == "true")  // Overridden by .env.development
        #expect(env["DATABASE_HOST"] == "localhost")  // From base .env
        #expect(env["DATABASE_NAME"] == "myapp_dev")  // From .env.development
    }

    @Test("Single File Configuration Example (lines 174-179)")
    func testSingleFileConfigExample() throws {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".env")
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let content = "TEST_KEY=test-value"
        try content.write(to: tempFile, atomically: true, encoding: .utf8)

        // Example from README
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .singleFile(tempFile)
        )

        #expect(env["TEST_KEY"] == "test-value")
    }

    @Test("Process Environment Only Example (lines 186-189)")
    func testProcessEnvironmentOnlyExample() throws {
        // Example from README
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .none
        )

        // Should load from process environment
        #expect(env["PATH"] != nil)  // PATH should exist in process environment
    }

    // MARK: - Type-Safe Access

    @Test("Built-in Type Conversion Example (lines 229-244)")
    func testTypeConversionExample() throws {
        let env = try EnvironmentVariables(
            dictionary: [
                "API_KEY": "test-key",
                "PORT": "8080",
                "MAX_CONNECTIONS": "100",
                "DEBUG": "true",
                "ENABLE_LOGGING": "false",
                "BASE_URL": "https://example.com",
                "DATABASE_URL": "postgresql://localhost/db"
            ],
            requiredKeys: []
        )

        // Example from README
        let apiKey: String? = env["API_KEY"]
        let port: Int? = env.int("PORT")
        let maxConnections: Int? = env.int("MAX_CONNECTIONS")
        let isDebug: Bool? = env.bool("DEBUG")
        let enableLogging: Bool? = env.bool("ENABLE_LOGGING")
        let baseUrl: URL? = env.url("BASE_URL")
        let databaseUrl: URL? = env.url("DATABASE_URL")

        #expect(apiKey == "test-key")
        #expect(port == 8080)
        #expect(maxConnections == 100)
        #expect(isDebug == true)
        #expect(enableLogging == false)
        #expect(baseUrl?.absoluteString == "https://example.com")
        #expect(databaseUrl?.absoluteString == "postgresql://localhost/db")
    }

    @Test("Custom Property Extensions Example (lines 250-267)")
    func testCustomPropertyExtensionsExample() throws {
        var env = try EnvironmentVariables(
            dictionary: [
                "APP_SECRET": "secret123",
                "BASE_URL": "https://api.example.com",
                "PORT": "3000"
            ],
            requiredKeys: []
        )

        #expect(env.appSecret == "secret123")
        #expect(env.baseUrl.absoluteString == "https://api.example.com")
        #expect(env.port == 3000)

        // Test setters
        env.appSecret = "new-secret"
        env.baseUrl = URL(string: "https://new.example.com")!
        env.port = 4000

        #expect(env["APP_SECRET"] == "new-secret")
        #expect(env["BASE_URL"] == "https://new.example.com")
        #expect(env["PORT"] == "4000")
    }

    @Test("Optional Properties Example (lines 273-287)")
    func testOptionalPropertiesExample() throws {
        var env = try EnvironmentVariables(
            dictionary: [
                "LOG_LEVEL": "debug",
                "HTTPS_REDIRECT": "true"
            ],
            requiredKeys: []
        )

        #expect(env.logLevel == .debug)
        #expect(env.httpsRedirect == true)

        // Test nil values
        env = try EnvironmentVariables(dictionary: [:], requiredKeys: [])
        #expect(env.logLevel == nil)
        #expect(env.httpsRedirect == nil)
    }

    @Test("Array Variables Example (lines 293-304)")
    func testArrayVariablesExample() throws {
        var env = try EnvironmentVariables(
            dictionary: ["ALLOWED_HOSTS": "localhost, example.com, api.example.com"],
            requiredKeys: []
        )

        #expect(env.allowedHosts == ["localhost", "example.com", "api.example.com"])

        // Test setter
        env.allowedHosts = ["host1.com", "host2.com"]
        #expect(env["ALLOWED_HOSTS"] == "host1.com,host2.com")
    }

    // MARK: - Required Keys Validation

    @Test("Required Keys Validation Example (lines 310-322)")
    func testRequiredKeysValidationExample() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let envContent = """
        API_KEY=test-key
        DATABASE_URL=postgresql://localhost/db
        APP_SECRET=secret123
        """
        try envContent.write(to: tempDir.appendingPathComponent(".env"), atomically: true, encoding: .utf8)

        // Example from README - should succeed
        do {
            let env = try EnvironmentVariables.live(
                environmentConfiguration: .projectRoot(
                    tempDir,
                    environment: nil
                ),
                requiredKeys: ["API_KEY", "DATABASE_URL", "APP_SECRET"]
            )
            #expect(env["API_KEY"] == "test-key")
        } catch EnvironmentVariables.Error.missingRequiredKeys(let keys) {
            Issue.record("Unexpected missing keys: \(keys)")
        }

        // Test with missing keys
        do {
            _ = try EnvironmentVariables.live(
                environmentConfiguration: .projectRoot(
                    tempDir,
                    environment: nil
                ),
                requiredKeys: ["API_KEY", "MISSING_KEY"]
            )
            Issue.record("Expected error for missing required key")
        } catch EnvironmentVariables.LiveError.initializationFailed(let underlying) {
            // Unwrap the LiveError to get the actual missing keys error
            if let missingKeysError = underlying as? EnvironmentVariables.Error,
               case .missingRequiredKeys(let keys) = missingKeysError {
                #expect(keys.contains("MISSING_KEY"))
            } else {
                Issue.record("Expected missingRequiredKeys error, got: \(underlying)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Error Handling

    @Test("Error Types Examples (lines 330-343)")
    func testErrorTypesExample() throws {
        // Test EnvironmentVariables.Error.missingRequiredKeys
        do {
            _ = try EnvironmentVariables(
                dictionary: [:],
                requiredKeys: ["REQUIRED_KEY"]
            )
            Issue.record("Expected error for missing required key")
        } catch EnvironmentVariables.Error.missingRequiredKeys(let keys) {
            #expect(keys == ["REQUIRED_KEY"])
        }

        // Verify error types exist as documented
        let _: EnvironmentVariables.Error = .missingRequiredKeys(["KEY1", "KEY2"])
        let _: EnvironmentVariables.LiveError = .initializationFailed(underlying: NSError(domain: "", code: 0))
        let _: EnvironmentVariables.LiveError = .invalidEnvironment(reason: "test")
    }
}
