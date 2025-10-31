//
//  EnvironmentVariables.swift
//  swift-environment-variables
//
//  Created by Coen ten Thije Boonkkamp on 03/06/2022.
//

import Dependencies
import Foundation
import Logging

/// A type-safe environment variable container that provides secure access to system environment variables.
///
/// `EnvironmentVariables` offers a robust solution for managing environment variables in Swift applications,
/// with support for required key validation, type-safe accessors, and seamless integration with the Dependencies library.
///
/// ## Overview
///
/// Environment variables are loaded from multiple sources with a clear precedence order:
/// 1. Default values (lowest priority)
/// 2. Local development files (JSON format)
/// 3. Process environment variables (highest priority)
///
/// ## Basic Usage
///
/// ```swift
/// // Create with required keys validation
/// let env = try EnvironmentVariables.live(requiredKeys: ["API_KEY", "DATABASE_URL"])
///
/// // Access values with type safety
/// let apiKey: String? = env["API_KEY"]
/// let port: Int? = env.int("PORT")
/// let isDebug: Bool? = env.bool("DEBUG_MODE")
/// let baseUrl: URL? = env.url("BASE_URL")
/// ```
///
/// ## Dependencies Integration
///
/// ```swift
/// extension EnvironmentVariables: @retroactive DependencyKey {
///     public static var liveValue: Self {
///         try! EnvironmentVariables.live(
///             localDevelopment: URL(fileURLWithPath: ".env.development")
///         )
///     }
/// }
///
/// struct MyFeature {
///     @Dependency(\.envVars) var env
///
///     func configure() throws {
///         guard let apiKey = env["API_KEY"] else {
///             throw ConfigError.missingApiKey
///         }
///     }
/// }
/// ```
public struct EnvironmentVariables: Codable, Sendable {
  private var dictionary: [String: String]
  private let requiredKeys: Set<String>

  /// Creates a new environment variables instance with the specified dictionary and required keys.
  ///
  /// - Parameters:
  ///   - dictionary: A dictionary containing environment variable key-value pairs
  ///   - requiredKeys: A set of keys that must be present in the dictionary
  /// - Throws: `EnvironmentVariables.Error.missingRequiredKeys` if any required keys are missing
  public init(
    dictionary: [String: String],
    requiredKeys: Set<String>
  ) throws {
    self.dictionary = dictionary
    self.requiredKeys = requiredKeys

    try self.validateRequiredKeys()
  }

  private func validateRequiredKeys() throws {
    let missingKeys = requiredKeys.subtracting(dictionary.keys)
    if !missingKeys.isEmpty {
      throw EnvironmentVariables.Error.missingRequiredKeys(Array(missingKeys))
    }
  }

  /// Accesses the environment variable value for the given key.
  ///
  /// Use subscript syntax to get and set environment variable values:
  ///
  /// ```swift
  /// let apiKey = env["API_KEY"]
  /// env["NEW_KEY"] = "new_value"
  /// ```
  ///
  /// - Parameter key: The environment variable key
  /// - Returns: The string value for the key, or `nil` if the key doesn't exist
  public subscript(key: String) -> String? {
    get { dictionary[key] }
    set { dictionary[key] = newValue }
  }
}

/// A convenient type alias for `EnvironmentVariables`.
///
/// Use `EnvVars` as a shorter alternative to `EnvironmentVariables` throughout your codebase:
///
/// ```swift
/// let env: EnvVars = try .live()
/// @Dependency(\.envVars) var env: EnvVars
/// ```
public typealias EnvVars = EnvironmentVariables

// MARK: - Codable Implementation
extension EnvironmentVariables {
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    var dictionary = [String: String]()

    for key in container.allKeys {
      if let value = try container.decodeIfPresent(String.self, forKey: key) {
        dictionary[key.stringValue] = value
      }
    }

    try self.init(dictionary: dictionary, requiredKeys: Set())
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    for (key, value) in dictionary {
      try container.encode(value, forKey: CodingKeys(stringValue: key)!)
    }
  }

  private struct CodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
      self.stringValue = stringValue
    }

    init?(intValue: Int) {
      return nil
    }
  }
}

// MARK: - Type Safe Accessors
extension EnvironmentVariables {
  /// Returns the environment variable value converted to an integer.
  ///
  /// This method safely converts string environment variables to integers,
  /// returning `nil` if the value doesn't exist or can't be converted.
  ///
  /// ```swift
  /// let port = env.int("PORT") ?? 8080
  /// let maxConnections = env.int("MAX_CONNECTIONS")
  /// ```
  ///
  /// - Parameter key: The environment variable key
  /// - Returns: The integer value, or `nil` if the key doesn't exist or conversion fails
  public func int(_ key: String) -> Int? {
    self[key].flatMap(Int.init)
  }

  /// Returns the environment variable value converted to a boolean.
  ///
  /// This method converts common string representations to boolean values:
  /// - `true`: "true", "yes", "1" (case-insensitive)
  /// - `false`: "false", "no", "0" (case-insensitive)
  /// - `nil`: any other value or missing key
  ///
  /// ```swift
  /// let isDebugMode = env.bool("DEBUG") ?? false
  /// let enableLogging = env.bool("ENABLE_LOGGING")
  /// ```
  ///
  /// - Parameter key: The environment variable key
  /// - Returns: The boolean value, or `nil` if the key doesn't exist or can't be converted
  public func bool(_ key: String) -> Bool? {
    self[key].flatMap { value in
      switch value.lowercased() {
      case "true", "yes", "1": return true
      case "false", "no", "0": return false
      default: return nil
      }
    }
  }

  /// Returns the environment variable value converted to a URL.
  ///
  /// This method safely converts string environment variables to URL objects,
  /// returning `nil` if the value doesn't exist or isn't a valid URL.
  ///
  /// ```swift
  /// let baseUrl = env.url("BASE_URL")
  /// let databaseUrl = env.url("DATABASE_URL")
  /// ```
  ///
  /// - Parameter key: The environment variable key
  /// - Returns: The URL value, or `nil` if the key doesn't exist or conversion fails
  public func url(_ key: String) -> URL? {
    self[key].flatMap(URL.init(string:))
  }
}

// MARK: - Error Handling
extension EnvironmentVariables {
  /// Errors that can occur when working with environment variables.
  public enum Error: Equatable, Swift.Error {
    /// Thrown when one or more required environment variable keys are missing.
    ///
    /// The associated value contains an array of the missing key names.
    /// This error is thrown during initialization when required keys are not found
    /// in the provided dictionary.
    ///
    /// ```swift
    /// do {
    ///     let env = try EnvironmentVariables(
    ///         dictionary: [:],
    ///         requiredKeys: ["API_KEY", "DATABASE_URL"]
    ///     )
    /// } catch EnvironmentVariables.Error.missingRequiredKeys(let keys) {
    ///     print("Missing required keys: \(keys)")
    /// }
    /// ```
    case missingRequiredKeys([String])
  }
}

// MARK: - Dependency Integration
extension DependencyValues {
  /// Provides access to environment variables through the Dependencies system.
  ///
  /// Use this property with the `@Dependency` property wrapper to access
  /// environment variables in your application:
  ///
  /// ```swift
  /// struct MyFeature {
  ///     @Dependency(\.envVars) var env
  ///
  ///     func configure() {
  ///         let apiKey = env["API_KEY"]
  ///         let port = env.int("PORT") ?? 8080
  ///     }
  /// }
  /// ```
  ///
  /// Make sure to configure the dependency by conforming `EnvironmentVariables`
  /// to `DependencyKey` in your application code.
  public var envVars: EnvironmentVariables {
    get { self[EnvironmentVariables.self] }
    set { self[EnvironmentVariables.self] = newValue }
  }
}

// MARK: - Convenience Access
extension EnvironmentVariables {
  /// A convenience property that provides access to the test environment variables.
  ///
  /// This property returns the same instance as `testValue`, providing a more
  /// descriptive name for local development and testing scenarios.
  ///
  /// ```swift
  /// let env = EnvironmentVariables.local
  /// env["TEST_KEY"] = "test_value"
  /// ```
  public static let local: EnvironmentVariables = Self.testValue
}
