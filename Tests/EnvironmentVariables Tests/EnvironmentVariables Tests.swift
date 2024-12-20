//
//  File.swift
//  coenttb-web
//
//  Created by Coen ten Thije Boonkkamp on 13/12/2024.
//

import Foundation
import Testing
@testable import EnvironmentVariables

@Test
func testRequiredVariables() async throws {
    @Dependency(\.envVars) var envVars
    
    #expect(envVars["APP_ENV"] != nil)
    #expect(envVars["APP_SECRET"] != nil)
    #expect(envVars["BASE_URL"] != nil)
    #expect(envVars["PORT"] != nil)
}

@Test
func testAnalyticsConfiguration() async throws {
    @Dependency(\.envVars) var envVars
    
    #expect(envVars.googleAnalyticsId != nil)
    #expect(envVars.hotjarAnalyticsId != nil)
}

@Test
func testCompanyInformation() async throws {
    @Dependency(\.envVars) var envVars
    
    #expect(envVars.companyName != nil)
    #expect(envVars.companyInfoEmailAddress != nil)
    #expect(envVars.companyXComHandle != nil)
    #expect(envVars.companyGithubHandle != nil)
    #expect(envVars.companyLinkedinHandle != nil)
}

@Test
func testMailgunConfiguration() async throws {
    @Dependency(\.envVars) var envVars
    
    #expect(envVars.mailgunBaseUrl != nil)
    #expect(envVars.mailgunPrivateApiKey != nil)
    #expect(envVars.mailgunDomain != nil)
    #expect(envVars.mailgunWebhookSigningKey != nil)
    #expect(envVars.mailgunCompanyEmail != nil)
}

@Test
func testStripeConfiguration() async throws {
    @Dependency(\.envVars) var envVars
    
    #expect(envVars.stripeEndpointSecret != nil)
    #expect(envVars.stripePublishableKey != nil)
    #expect(envVars.stripeSecretKey != nil)
}

@Test
func testDemoData() async throws {
    @Dependency(\.envVars) var envVars
    
    #expect(envVars.demoName != nil)
    #expect(envVars.demoEmail != nil)
    #expect(envVars.demoPassword != nil)
    #expect(envVars.demoStripeCustomerId != nil)
}

@Test
func testDatabaseAndSessionConfiguration() async throws {
    @Dependency(\.envVars) var envVars
    
    #expect(envVars.databaseUrl != nil)
    #expect(envVars.sessionCookieName != nil)
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
        
        #expect(envVars.companyName == "Custom Company")
        #expect(envVars.companyInfoEmailAddress == "custom@example.com")
        #expect(envVars.googleAnalyticsId == nil) // Should be nil as not provided
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
    
    guard let mailgunBaseUrl = envVars.mailgunBaseUrl else {
        #expect(Bool(false), "Expected mailgunBaseUrl to be a valid URL")
        return
    }
    
    #expect(mailgunBaseUrl.scheme == "https")
    #expect(mailgunBaseUrl.host == "api.mailgun.net")
}
