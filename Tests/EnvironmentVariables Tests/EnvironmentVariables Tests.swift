//
//  File.swift
//  coenttb-web
//
//  Created by Coen ten Thije Boonkkamp on 13/12/2024.
//

import DependenciesTestSupport
@testable import EnvironmentVariables
import Foundation
import Testing

@Suite(
    .dependency(\.envVars, try! .live(localEnvFile: URL.projectRoot.appendingPathComponent(".env.json")))
)
struct LiveTest {
    @Test
    func testJSONFormatVariables() async throws {
        @Dependency(\.envVars) var envVars

        #expect(envVars["STRING"] == "comprehensive_test_value")
        #expect(envVars["URL"] == "https://coenttb.com")
        #expect(envVars["BOOL"] == "true")
        #expect(envVars["APP_NAME"] == "Swift Environment Variables")
        #expect(envVars["APP_ENV"] == "json-demo")
        #expect(envVars["DEBUG"] == "true")
    }

    @Test
    func testCustomEnvironment() async throws {
        try withDependencies {
            $0.envVars = try EnvironmentVariables(
                dictionary: [
                    "COMPANY_NAME": "Custom Company",
                    "COMPANY_INFO_EMAIL_ADDRESS": "custom@example.com"
                ],
                requiredKeys: []
            )
        } operation: {
            @Dependency(\.envVars) var envVars

            #expect(envVars["COMPANY_NAME"] == "Custom Company")
            #expect(envVars["COMPANY_INFO_EMAIL_ADDRESS"] == "custom@example.com")
        }
    }

    @Test
    func testMissingRequiredKeys() async throws {
        #expect(throws: EnvironmentVariables.Error.missingRequiredKeys(["REQUIRED_KEY"])) {
            _ = try EnvironmentVariables(dictionary: [:], requiredKeys: ["REQUIRED_KEY"])
        }
    }

    @Test
    func testUrlTypeConversion() async throws {
        @Dependency(\.envVars) var envVars

        guard let url = envVars.url("URL") else {
            #expect(Bool(false), "Expected URL to be a valid URL")
            return
        }

        #expect(url.scheme == "https")
        #expect(url.host == "coenttb.com")
    }

    @Test
    func testComprehensiveJSONVariables() async throws {
        @Dependency(\.envVars) var envVars

        // Test various categories of variables from .env.json
        #expect(envVars["APP_NAME"] == "Swift Environment Variables")
        #expect(envVars["APP_VERSION"] == "1.0.0")
        #expect(envVars["APP_ENV"] == "json-demo")

        #expect(envVars["SERVER_HOST"] == "localhost")
        #expect(envVars.int("SERVER_PORT") == 8080)

        #expect(envVars["DATABASE_URL"] == "postgresql://json:password@localhost:5432/myapp_json")
        #expect(envVars["DATABASE_NAME"] == "myapp_json")
        #expect(envVars.int("CONNECTION_POOL_SIZE") == 15)

        #expect(envVars["REDIS_URL"] == "redis://localhost:6379/2")
        #expect(envVars.int("CACHE_TTL") == 1800)

        #expect(envVars.bool("DEBUG") == true)
        #expect(envVars.bool("ENABLE_LOGGING") == true)
        #expect(envVars.bool("FEATURE_FLAG_NEW_UI") == true)
        #expect(envVars.bool("FEATURE_FLAG_BETA_FEATURES") == true)

        #expect(envVars.int("NUMBER") == 42)

        // Test URL parsing
        let baseUrl = envVars.url("BASE_URL")
        #expect(baseUrl?.scheme == "https")
        #expect(baseUrl?.host == "api.example.com")
    }

}

@Suite
struct KeyValueFormatTest {
    @Test
    func testKeyValueFormatParsing() async throws {
        let env = try EnvironmentVariables.live(
            localEnvFile: URL.projectRoot.appendingPathComponent(".env.keyvalue.example")
        )

        #expect(env["STRING"] == "hello_world")
        #expect(env["BOOL"] == "true")
        #expect(env["PORT"] == "8080")
        #expect(env["URL"] == "https://coenttb.com")
        #expect(env["DATABASE_URL"] == "postgresql://kv:password@localhost:5432/myapp_keyvalue")
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["APP_ENV"] == "keyvalue-demo")
    }

    @Test
    func testQuotedValues() async throws {
        let env = try EnvironmentVariables.live(
            localEnvFile: URL.projectRoot.appendingPathComponent(".env.keyvalue.example")
        )

        #expect(env["COMPANY_NAME"] == "Coen ten Thije Boonkkamp")
        #expect(env["DESCRIPTION"] == "A Swift environment variables package")
        #expect(env["API_VERSION"] == "v2.0")
        #expect(env["ENVIRONMENT"] == "keyvalue-demo")
    }

    @Test
    func testSpecialCasesInKeyValueFormat() async throws {
        let env = try EnvironmentVariables.live(
            localEnvFile: URL.projectRoot.appendingPathComponent(".env.keyvalue.example")
        )

        #expect(env["EMPTY_VAR"] == "")
        #expect(env["SPECIAL_CHARS"] == "key@#$%^&*()")
        #expect(env["JSON_LIKE"] == "{\"key\":\"value\"}")
        #expect(env["ARRAY_LIKE"] == "[1,2,3]")
    }

    @Test
    func testKeyValueFormatWithTypeConversions() async throws {
        let env = try EnvironmentVariables.live(
            localEnvFile: URL.projectRoot.appendingPathComponent(".env.keyvalue.example")
        )

        #expect(env.int("PORT") == 8080)
        #expect(env.bool("BOOL") == true)
        #expect(env.url("URL")?.absoluteString == "https://coenttb.com")
    }

    @Test
    func testInvalidKeyValueFormat() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("invalid.env")

        let invalidContent = """
        VALID_KEY=value
        INVALID_LINE_WITHOUT_EQUALS
        ANOTHER_VALID=value
        """

        try invalidContent.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let env = try EnvironmentVariables.live(localEnvFile: testFile)

        // Should return empty dictionary when parsing fails and log warning
        #expect(env["VALID_KEY"] == nil)
        #expect(env["ANOTHER_VALID"] == nil)
    }

    @Test
    func testKeyValueFormatWithComments() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("comments.env")

        let contentWithComments = """
        # This is a comment
        KEY1=value1

        # Another comment
        KEY2=value2

        # Inline comment handling - this key should work
        KEY3=value3
        """

        try contentWithComments.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let env = try EnvironmentVariables.live(localEnvFile: testFile)

        #expect(env["KEY1"] == "value1")
        #expect(env["KEY2"] == "value2")
        #expect(env["KEY3"] == "value3")
    }

    @Test
    func testKeyValueFormatWithWhitespace() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("whitespace.env")

        let contentWithWhitespace = """
           KEY1   =   value1
        KEY2="  quoted value with spaces  "
          KEY3='single quoted'
        """

        try contentWithWhitespace.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let env = try EnvironmentVariables.live(localEnvFile: testFile)

        #expect(env["KEY1"] == "value1")
        #expect(env["KEY2"] == "  quoted value with spaces  ")
        #expect(env["KEY3"] == "single quoted")
    }

    @Test
    func testFallbackFromJSONToKeyValue() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("fallback.env")

        // Create a file that's not valid JSON but is valid KEY=VALUE
        let keyValueContent = "API_KEY=secret123\nDEBUG=true"

        try keyValueContent.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let env = try EnvironmentVariables.live(localEnvFile: testFile)

        #expect(env["API_KEY"] == "secret123")
        #expect(env["DEBUG"] == "true")
    }

    @Test
    func testJSONFormatStillWorks() async throws {
        // Ensure existing JSON format continues to work
        let env = try EnvironmentVariables.live(
            localEnvFile: URL.projectRoot.appendingPathComponent(".env.json")
        )

        #expect(env["STRING"] == "comprehensive_test_value")
        #expect(env["URL"] == "https://coenttb.com")
        #expect(env["BOOL"] == "true")
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["APP_ENV"] == "json-demo")
    }

    @Test
    func testQuotedKeysHandling() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("quoted_keys.env")

        let contentWithQuotedKeys = """
        # Regular key
        NORMAL_KEY=normal_value

        # Quoted keys - should be stored without quotes
        "ENV"=development
        'API_KEY'=secret123
        "DATABASE_URL"=postgresql://user:pass@localhost/db

        # Mixed quotes and values
        "PORT"="8080"
        'HOST'='localhost'
        """

        try contentWithQuotedKeys.write(to: testFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: testFile) }

        let env = try EnvironmentVariables.live(localEnvFile: testFile)

        // Keys should be accessible without quotes
        #expect(env["NORMAL_KEY"] == "normal_value")
        #expect(env["ENV"] == "development")
        #expect(env["API_KEY"] == "secret123")
        #expect(env["DATABASE_URL"] == "postgresql://user:pass@localhost/db")
        #expect(env["PORT"] == "8080")
        #expect(env["HOST"] == "localhost")

        // Quoted versions should NOT work
        #expect(env["\"ENV\""] == nil)
        #expect(env["'API_KEY'"] == nil)
        #expect(env["\"DATABASE_URL\""] == nil)
    }
}

@Suite
struct EnvironmentConfigurationTest {
    @Test
    func testNoneConfiguration() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .none
        )

        // Should only have process environment variables, no local files loaded
        // We can't test specific values since they depend on the system
        // But we can test that it doesn't fail and basic functionality works
        let testValue = env["NON_EXISTENT_KEY"]
        #expect(testValue == nil)
    }

    @Test
    func testSingleFileConfiguration() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .singleFile(
                URL.projectRoot.appendingPathComponent(".env.json")
            )
        )

        #expect(env["STRING"] == "comprehensive_test_value")
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["APP_ENV"] == "json-demo")
        #expect(env["DEBUG"] == "true")
    }

    @Test
    func testProjectRootNoEnvironment() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: nil
            )
        )

        // Should load only base .env file
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["APP_VERSION"] == "1.0.0")
        #expect(env["APP_ENV"] == "base")
        #expect(env["DEBUG"] == "false") // Base .env has DEBUG=false
        #expect(env["SERVER_HOST"] == "localhost")
        #expect(env["DATABASE_NAME"] == "myapp")
        #expect(env["API_KEY"] == "base-api-key")
    }

    @Test
    func testProjectRootWithDevelopmentEnvironment() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: "development"
            )
        )

        // Base values should be loaded
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["APP_VERSION"] == "1.0.0")
        #expect(env["SERVER_HOST"] == "localhost")

        // Development overrides should take precedence
        #expect(env["APP_ENV"] == "development") // Overridden in .env.development
        #expect(env["DEBUG"] == "true") // Overridden in .env.development
        #expect(env["LOG_LEVEL"] == "debug") // Overridden in .env.development
        #expect(env["DATABASE_NAME"] == "myapp_dev") // Overridden in .env.development
        #expect(env["BASE_URL"] == "http://localhost:3000") // Overridden in .env.development
        #expect(env["API_KEY"] == "dev-api-key-12345") // Overridden in .env.development

        // Development-specific values should be present
        #expect(env["HOT_RELOAD"] == "true")
        #expect(env["DEV_TOOLS_ENABLED"] == "true")
        #expect(env["MOCK_EXTERNAL_APIS"] == "true")
    }

    @Test
    func testProjectRootWithProductionEnvironment() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: "production"
            )
        )

        // Base values should be loaded
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["SERVER_HOST"] == "localhost")

        // Production overrides should take precedence
        #expect(env["APP_ENV"] == "production") // Overridden in .env.production
        #expect(env["DEBUG"] == "false") // Explicitly set in .env.production
        #expect(env["LOG_LEVEL"] == "error") // Overridden in .env.production
        #expect(env["DATABASE_NAME"] == "myapp_prod") // Overridden in .env.production
        #expect(env["BASE_URL"] == "https://api.myapp.com") // Overridden in .env.production
        #expect(env["API_KEY"] == "prod-api-key-secure") // Overridden in .env.production

        // Production-specific values should be present
        #expect(env["FORCE_HTTPS"] == "true")
        #expect(env["SECURE_COOKIES"] == "true")
        #expect(env["HEALTH_CHECK_ENABLED"] == "true")
    }

    @Test
    func testProjectRootWithJSONEnvironment() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: "testing"
            )
        )

        // Base values should be loaded from .env (KEY=VALUE format)
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["SERVER_HOST"] == "localhost")

        // Testing overrides should take precedence from .env.testing (JSON format)
        #expect(env["DEBUG"] == "true") // Overridden in .env.testing (JSON)
        #expect(env["LOG_LEVEL"] == "debug") // Overridden in .env.testing (JSON)
        #expect(env["DATABASE_NAME"] == "myapp_test") // Overridden in .env.testing (JSON)
        #expect(env["BASE_URL"] == "http://localhost:9999") // Overridden in .env.testing (JSON)

        // Testing-specific values should be present
        #expect(env["TEST_MODE"] == "true")
        #expect(env["PARALLEL_TESTS"] == "false")
        #expect(env["TEST_TIMEOUT"] == "30")
    }

    @Test
    func testPrecedenceOverridesWithTypeConversions() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: "development"
            )
        )

        // Test that type conversions work with overridden values
        #expect(env.bool("DEBUG") == true) // Overridden from false to true
        #expect(env.bool("FEATURE_FLAG_BETA_FEATURES") == true) // Overridden from false to true
        #expect(env.int("CACHE_TTL") == 60) // Overridden from 3600 to 60
        #expect(env.url("BASE_URL")?.absoluteString == "http://localhost:3000")
        #expect(env.int("SERVER_PORT") == 3000) // Overridden from 8080 to 3000
    }

    @Test
    func testNonExistentEnvironment() async throws {
        let env = try EnvironmentVariables.live(
            environmentConfiguration: .projectRoot(
                URL.projectRoot,
                environment: "nonexistent"
            )
        )

        // Should load only base .env file since .env.nonexistent doesn't exist
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["DEBUG"] == "false") // Should be base value, not overridden
        #expect(env["LOG_LEVEL"] == "info") // Should be base value

        // Environment-specific values should not be present
        #expect(env["HOT_RELOAD"] == nil)
        #expect(env["DEV_TOOLS_ENABLED"] == nil)
        #expect(env["FORCE_HTTPS"] == nil)
    }

    @Test
    func testBackwardCompatibilityWithDeprecatedAPI() async throws {
        // Test that the deprecated API still works
        let env = try EnvironmentVariables.live(
            localEnvFile: URL.projectRoot.appendingPathComponent(".env.json")
        )

        #expect(env["STRING"] == "comprehensive_test_value")
        #expect(env["APP_NAME"] == "Swift Environment Variables")
        #expect(env["APP_ENV"] == "json-demo")
        #expect(env["DEBUG"] == "true")
    }

    @Test
    func testRequiredKeysWithEnvironmentConfiguration() async throws {
        #expect(throws: EnvironmentVariables.LiveError.self) {
            _ = try EnvironmentVariables.live(
                environmentConfiguration: .projectRoot(
                    URL.projectRoot,
                    environment: "development"
                ),
                requiredKeys: ["APP_NAME", "MISSING_KEY"]
            )
        }
    }
}
