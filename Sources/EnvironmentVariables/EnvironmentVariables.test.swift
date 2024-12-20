//
//  File.swift
//  swift-environment-variables
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import Dependencies
import Foundation
import Logging

// MARK: - Test Support
extension EnvironmentVariables: TestDependencyKey {
    public static var testValue: EnvironmentVariables {
        do {
            return try EnvironmentVariables.live(localDevelopment: URL.projectRoot.appendingPathComponent(".env.example"), requiredKeys: [], decoder: .init())
        } catch {
            print(error)
            fatalError()
        }
    }
}



