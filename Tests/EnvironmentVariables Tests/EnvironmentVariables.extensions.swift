//
//  File.swift
//  swift-environment-variables
//
//  Created by Coen ten Thije Boonkkamp on 20/12/2024.
//

import Foundation
import EnvironmentVariables

extension EnvVars {
    // Analytics
    var googleAnalyticsId: String? {
        get { self["GOOGLE_ANALYTICS_ID"] }
        set { self["GOOGLE_ANALYTICS_ID"] = newValue }
    }
    
    var hotjarAnalyticsId: String? {
        get { self["HOTJAR_ANALYTICS_ID"] }
        set { self["HOTJAR_ANALYTICS_ID"] = newValue }
    }
    
    // Company Info
    var companyName: String? {
        get { self["COMPANY_NAME"] }
        set { self["COMPANY_NAME"] = newValue }
    }
    
    var companyInfoEmailAddress: String? {
        get { self["COMPANY_INFO_EMAIL_ADDRESS"] }
        set { self["COMPANY_INFO_EMAIL_ADDRESS"] = newValue }
    }
    
    var companyXComHandle: String? {
        get { self["COMPANY_X_COM_HANDLE"] }
        set { self["COMPANY_X_COM_HANDLE"] = newValue }
    }
    
    var companyGithubHandle: String? {
        get { self["COMPANY_GITHUB_HANDLE"] }
        set { self["COMPANY_GITHUB_HANDLE"] = newValue }
    }
    
    var companyLinkedinHandle: String? {
        get { self["COMPANY_LINKEDIN_HANDLE"] }
        set { self["COMPANY_LINKEDIN_HANDLE"] = newValue }
    }
    
    // Demo Data
    var demoName: String? {
        get { self["DEMO_NAME"] }
        set { self["DEMO_NAME"] = newValue }
    }
    
    var demoEmail: String? {
        get { self["DEMO_EMAIL"] }
        set { self["DEMO_EMAIL"] = newValue }
    }
    
    var demoPassword: String? {
        get { self["DEMO_PASSWORD"] }
        set { self["DEMO_PASSWORD"] = newValue }
    }
    
    var demoStripeCustomerId: String? {
        get { self["DEMO_STRIPE_CUSTOMER_ID"] }
        set { self["DEMO_STRIPE_CUSTOMER_ID"] = newValue }
    }
    
    // Database
    var databaseUrl: String? {
        get { self["DATABASE_URL"] }
        set { self["DATABASE_URL"] = newValue }
    }
    
    // Session
    var sessionCookieName: String? {
        get { self["SESSION_COOKIE_NAME"] }
        set { self["SESSION_COOKIE_NAME"] = newValue }
    }
    
    // Mailgun
    var mailgunBaseUrl: URL? {
        get { self["MAILGUN_BASE_URL"].flatMap(URL.init(string:)) }
        set { self["MAILGUN_BASE_URL"] = newValue?.absoluteString }
    }
    
    var mailgunPrivateApiKey: String? {
        get { self["MAILGUN_PRIVATE_API_KEY"] }
        set { self["MAILGUN_PRIVATE_API_KEY"] = newValue }
    }
    
    var mailgunDomain: String? {
        get { self["MAILGUN_DOMAIN"] }
        set { self["MAILGUN_DOMAIN"] = newValue }
    }
    
    var mailgunWebhookSigningKey: String? {
        get { self["MAILGUN_WEBHOOK_SIGNING_KEY"] }
        set { self["MAILGUN_WEBHOOK_SIGNING_KEY"] = newValue }
    }
    
    var mailgunCompanyEmail: String? {
        get { self["MAILGUN_COMPANY_EMAIL"] }
        set { self["MAILGUN_COMPANY_EMAIL"] = newValue }
    }
    
    // Stripe
    var stripeEndpointSecret: String? {
        get { self["STRIPE_ENDPOINT_SECRET"] }
        set { self["STRIPE_ENDPOINT_SECRET"] = newValue }
    }
    
    var stripePublishableKey: String? {
        get { self["STRIPE_PUBLISHABLE_KEY"] }
        set { self["STRIPE_PUBLISHABLE_KEY"] = newValue }
    }
    
    var stripeSecretKey: String? {
        get { self["STRIPE_SECRET_KEY"] }
        set { self["STRIPE_SECRET_KEY"] = newValue }
    }
}
