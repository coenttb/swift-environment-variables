//
//  File.swift
//  swift-environment-package variables
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import EnvironmentVariables
import Foundation

extension URL {
    static var projectRoot: URL {
        return .init(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
extension EnvVars {
    package var string: String? {
        get { self["STRING"] }
        set { self["STRING"] = newValue }
    }
    
    package var url: URL? {
        get { self["URL"].flatMap(URL.init(string:)) }
        set { self["URL"] = newValue?.absoluteString }
    }
    
    package var bool: Bool? {
        get { self["BOOL"].map { $0 == "true" } }
        set { self["BOOL"] = newValue.map { $0 ? "true" : "false" } }
    }
}
