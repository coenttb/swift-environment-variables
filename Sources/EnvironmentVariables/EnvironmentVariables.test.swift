//
//  EnvironmentVariables.test.swift
//  swift-environment-variables
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import Dependencies
import Foundation
import Logging

// MARK: - Test Support
extension EnvironmentVariables: TestDependencyKey {
  /// Provides a test instance of `EnvironmentVariables` for use in testing scenarios.
  ///
  /// This test value creates an empty environment variables instance with no required keys,
  /// making it safe to use in unit tests without any external dependencies or configuration.
  ///
  /// ## Usage in Tests
  ///
  /// The test value is automatically used when running tests with the Dependencies library:
  ///
  /// ```swift
  /// func testMyFeature() async throws {
  ///     await withDependencies {
  ///         // testValue is used automatically in test context
  ///     } operation: {
  ///         @Dependency(\.envVars) var env
  ///         // env is now the empty test instance
  ///     }
  /// }
  /// ```
  ///
  /// ## Custom Test Configuration
  ///
  /// You can override the test environment with custom values:
  ///
  /// ```swift
  /// await withDependencies {
  ///     $0.envVars = try! EnvironmentVariables(
  ///         dictionary: ["TEST_KEY": "test_value"],
  ///         requiredKeys: []
  ///     )
  /// } operation: {
  ///     @Dependency(\.envVars) var env
  ///     XCTAssertEqual(env["TEST_KEY"], "test_value")
  /// }
  /// ```
  ///
  /// - Returns: An empty `EnvironmentVariables` instance suitable for testing
  public static var testValue: EnvironmentVariables {
    try! .init(dictionary: [:], requiredKeys: [])
  }
}
