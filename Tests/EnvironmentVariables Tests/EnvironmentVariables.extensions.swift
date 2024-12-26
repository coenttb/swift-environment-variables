//
//  File.swift
//  swift-environment-package variables
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import Foundation
import EnvironmentVariables

extension EnvVars {
    static var liveTest: Self {
        do {
            return try EnvironmentVariables.live(localDevelopment: URL.projectRoot.appendingPathComponent(".env.example"), requiredKeys: [], decoder: .init())
        } catch {
            print(error)
            fatalError()
        }
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
extension EnvVars {
    // Analytics
    package var googleAnalyticsId: String? {
        get { self["GOOGLE_ANALYTICS_ID"] }
        set { self["GOOGLE_ANALYTICS_ID"] = newValue }
    }
    
    package var hotjarAnalyticsId: String? {
        get { self["HOTJAR_ANALYTICS_ID"] }
        set { self["HOTJAR_ANALYTICS_ID"] = newValue }
    }
    
    // Company Info
    package var companyName: String? {
        get { self["COMPANY_NAME"] }
        set { self["COMPANY_NAME"] = newValue }
    }
    
    package var companyInfoEmailAddress: String? {
        get { self["COMPANY_INFO_EMAIL_ADDRESS"] }
        set { self["COMPANY_INFO_EMAIL_ADDRESS"] = newValue }
    }
    
    package var companyXComHandle: String? {
        get { self["COMPANY_X_COM_HANDLE"] }
        set { self["COMPANY_X_COM_HANDLE"] = newValue }
    }
    
    package var companyGithubHandle: String? {
        get { self["COMPANY_GITHUB_HANDLE"] }
        set { self["COMPANY_GITHUB_HANDLE"] = newValue }
    }
    
    package var companyLinkedinHandle: String? {
        get { self["COMPANY_LINKEDIN_HANDLE"] }
        set { self["COMPANY_LINKEDIN_HANDLE"] = newValue }
    }
    
    // Demo Data
    package var demoName: String? {
        get { self["DEMO_NAME"] }
        set { self["DEMO_NAME"] = newValue }
    }
    
    package var demoEmail: String? {
        get { self["DEMO_EMAIL"] }
        set { self["DEMO_EMAIL"] = newValue }
    }
    
    package var demoPassword: String? {
        get { self["DEMO_PASSWORD"] }
        set { self["DEMO_PASSWORD"] = newValue }
    }
    
    package var demoStripeCustomerId: String? {
        get { self["DEMO_STRIPE_CUSTOMER_ID"] }
        set { self["DEMO_STRIPE_CUSTOMER_ID"] = newValue }
    }
    
    // Database
    package var databaseUrl: String? {
        get { self["DATABASE_URL"] }
        set { self["DATABASE_URL"] = newValue }
    }
    
    // Session
    package var sessionCookieName: String? {
        get { self["SESSION_COOKIE_NAME"] }
        set { self["SESSION_COOKIE_NAME"] = newValue }
    }
    
    // Mailgun
    package var mailgunBaseUrl: URL? {
        get { self["MAILGUN_BASE_URL"].flatMap(URL.init(string:)) }
        set { self["MAILGUN_BASE_URL"] = newValue?.absoluteString }
    }
    
    package var mailgunPrivateApiKey: String? {
        get { self["MAILGUN_PRIVATE_API_KEY"] }
        set { self["MAILGUN_PRIVATE_API_KEY"] = newValue }
    }
    
    package var mailgunDomain: String? {
        get { self["MAILGUN_DOMAIN"] }
        set { self["MAILGUN_DOMAIN"] = newValue }
    }
    
    package var mailgunWebhookSigningKey: String? {
        get { self["MAILGUN_WEBHOOK_SIGNING_KEY"] }
        set { self["MAILGUN_WEBHOOK_SIGNING_KEY"] = newValue }
    }
    
    package var mailgunCompanyEmail: String? {
        get { self["MAILGUN_COMPANY_EMAIL"] }
        set { self["MAILGUN_COMPANY_EMAIL"] = newValue }
    }
    
    // Stripe
    package var stripeEndpointSecret: String? {
        get { self["STRIPE_ENDPOINT_SECRET"] }
        set { self["STRIPE_ENDPOINT_SECRET"] = newValue }
    }
    
    package var stripePublishableKey: String? {
        get { self["STRIPE_PUBLISHABLE_KEY"] }
        set { self["STRIPE_PUBLISHABLE_KEY"] = newValue }
    }
    
    package var stripeSecretKey: String? {
        get { self["STRIPE_SECRET_KEY"] }
        set { self["STRIPE_SECRET_KEY"] = newValue }
    }
}
