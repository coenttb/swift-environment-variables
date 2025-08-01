//
//  EnvironmentVariables.live.swift
//  swift-environment-variables
//
//  Created by Coen ten Thije Boonkkamp on 31/08/2024.
//

import Dependencies
import Foundation
import Logging

extension EnvironmentVariables {
    private static let logger = Logger(label: "EnvironmentVariables")

    /// Configuration for loading environment files.
    ///
    /// This enum defines different strategies for loading environment variables from local files,
    /// supporting both single-file and project-based (Vapor-like) approaches.
    public enum EnvironmentConfiguration {
        /// No local environment files will be loaded.
        ///
        /// Only default values and process environment variables will be used.
        case none

        /// Load environment files from a project root directory.
        ///
        /// This approach mimics Vapor's behavior:
        /// 1. Loads base `.env` file from the project root
        /// 2. If an environment is specified, loads `.env.{environment}` file
        /// 3. Environment-specific values override base `.env` values
        ///
        /// - Parameters:
        ///   - projectRoot: URL to the project root directory
        ///   - environment: Optional environment name (e.g., "development", "production")
        ///
        /// Example file loading for `environment: "development"`:
        /// - `projectRoot/.env` (base configuration)
        /// - `projectRoot/.env.development` (overrides base values)
        case projectRoot(URL, environment: String?)

        /// Load a single environment file (legacy approach).
        ///
        /// This maintains backward compatibility with the existing `localEnvFile` parameter.
        /// Use `projectRoot` for new projects to benefit from environment-specific configurations.
        ///
        /// - Parameter fileURL: URL to a single environment file
        case singleFile(URL)
    }

    /// Errors that can occur when creating a live environment variables instance.
    public enum LiveError: Swift.Error {
        /// Thrown when the initialization process fails due to an underlying error.
        ///
        /// This error wraps the original error that caused the initialization to fail,
        /// such as file system errors when reading local environment files.
        case initializationFailed(underlying: Swift.Error)

        /// Thrown when the environment configuration is invalid.
        ///
        /// This error is thrown when there are logical inconsistencies or
        /// validation issues with the environment configuration.
        case invalidEnvironment(reason: String)
    }

    /// Creates a live environment variables instance by merging multiple sources.
    ///
    /// This method loads environment variables from multiple sources with the following precedence:
    /// 1. **Default values** (lowest priority) - currently empty, but extensible
    /// 2. **Local development file** (medium priority) - JSON file for development
    /// 3. **Process environment** (highest priority) - system environment variables
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Basic usage with process environment only
    /// let env = try EnvironmentVariables.live()
    ///
    /// // With required keys validation
    /// let env = try EnvironmentVariables.live(
    ///     requiredKeys: ["API_KEY", "DATABASE_URL"]
    /// )
    ///
    /// // With local development file
    /// let env = try EnvironmentVariables.live(
    ///     localEnvFile: URL(fileURLWithPath: ".env.development"),
    ///     requiredKeys: ["API_KEY"]
    /// )
    /// ```
    ///
    /// ## Local Environment File Formats
    ///
    /// The local environment file supports two formats:
    ///
    /// ### JSON Format
    /// ```json
    /// {
    ///     "API_KEY": "dev-api-key",
    ///     "DATABASE_URL": "sqlite:///dev.db",
    ///     "DEBUG": "true"
    /// }
    /// ```
    ///
    /// ### KEY=VALUE Format (.env)
    /// ```
    /// # Comments are supported
    /// API_KEY=dev-api-key
    /// DATABASE_URL=sqlite:///dev.db
    /// DEBUG=true
    /// 
    /// # Quoted values for spaces
    /// COMPANY_NAME="My Company"
    /// DESCRIPTION='App description'
    /// ```
    ///
    /// The parser automatically detects the format, trying JSON first, then falling back to KEY=VALUE format.
    ///
    /// - Parameters:
    ///   - localEnvFile: Optional URL to a local environment file (JSON or KEY=VALUE format)
    ///   - requiredKeys: Set of keys that must be present in the final merged environment
    ///   - decoder: JSON decoder for parsing the local environment file (uses default if not specified)
    /// - Returns: A configured `EnvironmentVariables` instance
    /// - Throws: `LiveError.initializationFailed` if initialization fails, or
    ///           `EnvironmentVariables.Error.missingRequiredKeys` if required keys are missing
    @available(*, deprecated, message: "Use live(environmentConfiguration:requiredKeys:decoder:) instead.")
    public static func live(
        localEnvFile: URL? = nil,
        requiredKeys: Set<String> = [],
        decoder: JSONDecoder = .init()
    ) throws -> Self {
        let configuration: EnvironmentConfiguration = localEnvFile.map { .singleFile($0) } ?? .none
        return try live(environmentConfiguration: configuration, requiredKeys: requiredKeys, decoder: decoder)
    }

    /// Creates a live environment variables instance using the new configuration-based approach.
    ///
    /// This method supports multiple environment loading strategies including Vapor-like project-based
    /// configuration where base `.env` files are overridden by environment-specific files.
    ///
    /// ## Precedence Order (lowest to highest)
    /// 1. **Default values** (currently empty, but extensible)
    /// 2. **Base .env file** (when using `projectRoot` configuration)  
    /// 3. **Environment-specific file** (e.g., `.env.development` overrides `.env`)
    /// 4. **Process environment** (highest priority - system environment variables)
    ///
    /// ## Usage Examples
    ///
    /// ```swift
    /// // Vapor-like project-based loading
    /// let env = try EnvironmentVariables.live(
    ///     environmentConfiguration: .projectRoot(
    ///         URL(fileURLWithPath: "/path/to/project"),
    ///         environment: "development"
    ///     ),
    ///     requiredKeys: ["API_KEY"]
    /// )
    ///
    /// // Single file loading (legacy approach)
    /// let env = try EnvironmentVariables.live(
    ///     environmentConfiguration: .singleFile(URL(fileURLWithPath: ".env.development"))
    /// )
    ///
    /// // Process environment only
    /// let env = try EnvironmentVariables.live(
    ///     environmentConfiguration: .none
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - environmentConfiguration: Strategy for loading environment files
    ///   - requiredKeys: Set of keys that must be present in the final merged environment
    ///   - decoder: JSON decoder for parsing environment files (uses default if not specified)
    /// - Returns: A configured `EnvironmentVariables` instance
    /// - Throws: `LiveError.initializationFailed` if initialization fails, or
    ///           `EnvironmentVariables.Error.missingRequiredKeys` if required keys are missing
    public static func live(
        environmentConfiguration: EnvironmentConfiguration = .none,
        requiredKeys: Set<String> = [],
        decoder: JSONDecoder = .init()
    ) throws -> Self {
        do {
            let defaultEnvVarDict: [String: String] = [:]
            let localEnvVarDict = try loadEnvironmentFiles(configuration: environmentConfiguration, decoder: decoder)
            let processEnvVarDict = ProcessInfo.processInfo.environment

            let mergedEnvironment: [String: String] = defaultEnvVarDict
                .merging(localEnvVarDict, uniquingKeysWith: { $1 })
                .merging(processEnvVarDict, uniquingKeysWith: { $1 })

            return try EnvironmentVariables(dictionary: mergedEnvironment, requiredKeys: requiredKeys)
        } catch {
            logger.error("Failed to initialize EnvironmentVariables: \(error.localizedDescription)")
            throw LiveError.initializationFailed(underlying: error)
        }
    }

    /// Loads environment variables from a local JSON file.
    ///
    /// This private method attempts to read and parse a JSON file containing
    /// environment variables. If the file doesn't exist or can't be parsed,
    /// it logs a warning and returns an empty dictionary rather than failing.
    ///
    /// - Parameters:
    ///   - url: Optional URL to the local environment file
    ///   - decoder: JSON decoder to use for parsing the file
    /// - Returns: Dictionary of environment variables from the file, or empty dictionary if loading fails
    /// - Throws: This method catches and logs errors internally, returning an empty dictionary on failure
    private static func getLocalEnvironment(
        from url: URL?,
        decoder: JSONDecoder
    ) throws -> [String: String] {
        guard let url = url else { return [:] }

        // Check if file exists first - if not, silently return empty dictionary
        guard FileManager.default.fileExists(atPath: url.path) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)

            // Try JSON format first (existing behavior)
            do {
                return try decoder.decode([String: String].self, from: data)
            } catch {
                // If JSON parsing fails, try KEY=VALUE format
                return try parseKeyValueFormat(data)
            }
        } catch {
            // Actual error reading/parsing the file - worth warning about
            logger.warning("Could not load local environment from \(url.path): \(error.localizedDescription)")
            return [:]
        }
    }

    /// Parses environment variables from KEY=VALUE format.
    ///
    /// This method supports the standard .env file format with the following features:
    /// - KEY=VALUE pairs, one per line
    /// - Empty lines (ignored)
    /// - Comments starting with # (ignored)
    /// - Quoted values: KEY="value with spaces"
    /// - Unquoted values: KEY=simple_value
    /// - Whitespace trimming around keys and values
    ///
    /// - Parameter data: The file data to parse
    /// - Returns: Dictionary of environment variables
    /// - Throws: Parsing errors if the format is invalid
    private static func parseKeyValueFormat(_ data: Data) throws -> [String: String] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw LiveError.invalidEnvironment(reason: "File content is not valid UTF-8")
        }

        var result: [String: String] = [:]
        let lines = content.components(separatedBy: .newlines)

        for (lineNumber, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }

            // Find the first = sign
            guard let equalIndex = trimmedLine.firstIndex(of: "=") else {
                throw LiveError.invalidEnvironment(
                    reason: "Invalid KEY=VALUE format at line \(lineNumber + 1): '\(trimmedLine)'"
                )
            }

            let rawKey = String(trimmedLine[..<equalIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmedLine[trimmedLine.index(after: equalIndex)...])

            // Parse key, handling quotes (same logic as values)
            let key = parseValue(rawKey)

            // Validate key is not empty
            if key.isEmpty {
                throw LiveError.invalidEnvironment(
                    reason: "Empty key at line \(lineNumber + 1): '\(trimmedLine)'"
                )
            }

            // Parse value, handling quotes
            let parsedValue = parseValue(value)
            result[key] = parsedValue
        }

        return result
    }

    /// Parses a value from KEY=VALUE format, handling quoted and unquoted values.
    ///
    /// - Parameter value: The raw value string after the = sign
    /// - Returns: The parsed value with quotes removed and whitespace trimmed
    private static func parseValue(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespaces)

        // Handle quoted values
        if trimmedValue.count >= 2 {
            if (trimmedValue.hasPrefix("\"") && trimmedValue.hasSuffix("\"")) ||
               (trimmedValue.hasPrefix("'") && trimmedValue.hasSuffix("'")) {
                let startIndex = trimmedValue.index(after: trimmedValue.startIndex)
                let endIndex = trimmedValue.index(before: trimmedValue.endIndex)
                return String(trimmedValue[startIndex..<endIndex])
            }
        }

        // Return unquoted value as-is (already trimmed)
        return trimmedValue
    }

    /// Loads environment variables based on the provided configuration.
    ///
    /// This method orchestrates the loading of environment variables from different sources
    /// based on the `EnvironmentConfiguration` provided.
    ///
    /// - Parameters:
    ///   - configuration: The environment configuration strategy to use
    ///   - decoder: JSON decoder for parsing environment files
    /// - Returns: Dictionary of environment variables loaded from files
    /// - Throws: Errors from file loading operations
    private static func loadEnvironmentFiles(
        configuration: EnvironmentConfiguration,
        decoder: JSONDecoder
    ) throws -> [String: String] {
        switch configuration {
        case .none:
            return [:]

        case .singleFile(let url):
            return try getLocalEnvironment(from: url, decoder: decoder)

        case .projectRoot(let projectRoot, let environment):
            return try loadProjectEnvironment(
                projectRoot: projectRoot,
                environment: environment,
                decoder: decoder
            )
        }
    }

    /// Loads environment variables from project root using Vapor-like approach.
    ///
    /// This method implements the Vapor environment loading strategy:
    /// 1. Load base `.env` file from project root (if it exists)
    /// 2. Load environment-specific `.env.{environment}` file (if specified and exists)
    /// 3. Environment-specific values override base values
    ///
    /// Both JSON and KEY=VALUE formats are supported for each file.
    ///
    /// - Parameters:
    ///   - projectRoot: URL to the project root directory
    ///   - environment: Optional environment name (e.g., "development", "production")
    ///   - decoder: JSON decoder for parsing JSON environment files
    /// - Returns: Merged dictionary of environment variables with proper precedence
    /// - Throws: File system or parsing errors (non-existent files are silently ignored)
    private static func loadProjectEnvironment(
        projectRoot: URL,
        environment: String?,
        decoder: JSONDecoder
    ) throws -> [String: String] {
        var result: [String: String] = [:]

        // Load base .env file
        let baseEnvFile = projectRoot.appendingPathComponent(".env")
        let baseEnv = try getLocalEnvironment(from: baseEnvFile, decoder: decoder)
        result.merge(baseEnv, uniquingKeysWith: { $1 })

        // Load environment-specific file if specified
        if let environment = environment {
            let envSpecificFile = projectRoot.appendingPathComponent(".env.\(environment)")
            let envSpecificVars = try getLocalEnvironment(from: envSpecificFile, decoder: decoder)
            result.merge(envSpecificVars, uniquingKeysWith: { $1 })
        }

        return result
    }
}
