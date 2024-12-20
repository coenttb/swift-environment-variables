//
//  File.swift
//  coenttb-web
//
//  Created by Coen ten Thije Boonkkamp on 31/08/2024.
//

import Foundation
import Dependencies
import Logging

extension EnvironmentVariables {
    private static let logger = Logger(label: "EnvironmentVariables")
    
    public enum LiveError: Swift.Error {
        case initializationFailed(underlying: Swift.Error)
        case invalidEnvironment(reason: String)
    }

    public static func live(
        localDevelopment: URL? = nil,
        requiredKeys: Set<String> = [],
        decoder: JSONDecoder = .init()
    ) throws -> Self {
        do {
            let defaultEnvVarDict: [String:String] = [:]
            let localEnvVarDict = try getLocalEnvironment(from: localDevelopment, decoder: decoder)
            let processEnvVarDict = ProcessInfo.processInfo.environment
            
            let mergedEnvironment: [String : String] = defaultEnvVarDict
                .merging(localEnvVarDict, uniquingKeysWith: { $1 })
                .merging(processEnvVarDict, uniquingKeysWith: { $1 })
            
            return try EnvironmentVariables(dictionary: mergedEnvironment, requiredKeys: requiredKeys)
        } catch {
            logger.error("Failed to initialize EnvironmentVariables: \(error.localizedDescription)")
            throw LiveError.initializationFailed(underlying: error)
        }
    }
    
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
