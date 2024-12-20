//
//  CoenttbEnvironmentVariables.swift
//
//  Created by Coen ten Thije Boonkkamp on 03/06/2022.
//

import Dependencies
import Foundation
import Logging

/// A type-safe environment variable container that supports required keys and dynamic access
public struct EnvironmentVariables: Codable, Sendable {
    private var dictionary: [String: String]
    private let requiredKeys: Set<String>
    
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
    
    public subscript(key: String) -> String? {
        get { dictionary[key] }
        set { dictionary[key] = newValue }
    }
}

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
    /// Returns the value associated with the given key as an Integer
    public func int(_ key: String) -> Int? {
        self[key].flatMap(Int.init)
    }
    
    /// Returns the value associated with the given key as a Boolean
    public func bool(_ key: String) -> Bool? {
        self[key].flatMap { value in
            switch value.lowercased() {
            case "true", "yes", "1": return true
            case "false", "no", "0": return false
            default: return nil
            }
        }
    }
    
    /// Returns the value associated with the given key as a URL
    public func url(_ key: String) -> URL? {
        self[key].flatMap(URL.init(string:))
    }
}

// MARK: - Error Handling
extension EnvironmentVariables {
    public enum Error: Equatable, Swift.Error {
        case missingRequiredKeys([String])
    }
}



extension URL {
    static var projectRoot: URL {
        let url: URL = .init(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        print(url)
        
        return url
    }
}


// MARK: - Dependency Integration
extension DependencyValues {
    public var envVars: EnvironmentVariables {
        get { self[EnvironmentVariables.self] }
        set { self[EnvironmentVariables.self] = newValue }
    }
}

// MARK: - Convenience Access
extension EnvironmentVariables {
    public static let local: EnvironmentVariables = Self.testValue
}
