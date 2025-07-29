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
    /// ## Local Environment File Format
    ///
    /// The local environment file should be a JSON file with string key-value pairs:
    ///
    /// ```json
    /// {
    ///     "API_KEY": "dev-api-key",
    ///     "DATABASE_URL": "sqlite:///dev.db",
    ///     "DEBUG": "true"
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - localEnvFile: Optional URL to a JSON file containing development environment variables
    ///   - requiredKeys: Set of keys that must be present in the final merged environment
    ///   - decoder: JSON decoder for parsing the local environment file (uses default if not specified)
    /// - Returns: A configured `EnvironmentVariables` instance
    /// - Throws: `LiveError.initializationFailed` if initialization fails, or
    ///           `EnvironmentVariables.Error.missingRequiredKeys` if required keys are missing
    public static func live(
        localEnvFile: URL? = nil,
        requiredKeys: Set<String> = [],
        decoder: JSONDecoder = .init()
    ) throws -> Self {
        do {
            let defaultEnvVarDict: [String: String] = [:]
            let localEnvVarDict = try getLocalEnvironment(from: localEnvFile, decoder: decoder)
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
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([String: String].self, from: data)
        } catch {
            logger.warning("Could not load local environment from \(url.path): \(error.localizedDescription)")
            return [:]
        }
    }
}
