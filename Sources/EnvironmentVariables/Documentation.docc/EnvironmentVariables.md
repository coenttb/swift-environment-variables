# ``EnvironmentVariables``

A type-safe environment variable management system for Swift applications.

## Overview

EnvironmentVariables provides a robust, type-safe way to manage environment variables in Swift applications. It offers seamless integration with the Dependencies library, validation of required keys, and support for multiple configuration sources.

### Key Features

- **Type-safe access**: Convert environment variables to `Int`, `Bool`, `URL`, and `String` types
- **Required key validation**: Ensure critical environment variables are present at runtime
- **Layered configuration**: Load from process environment, local development files, and defaults
- **Dependencies integration**: First-class support for Point-Free's Dependencies library
- **Comprehensive testing**: Includes test helpers and mock values

## Topics

### Essentials

- ``EnvironmentVariables``
- ``EnvVars``

### Creating Environment Variables

- ``EnvironmentVariables/live(localEnvFile:requiredKeys:decoder:)``
- ``EnvironmentVariables/init(dictionary:requiredKeys:)``

### Accessing Values

- ``EnvironmentVariables/subscript(_:)``
- ``EnvironmentVariables/int(_:)``
- ``EnvironmentVariables/bool(_:)``
- ``EnvironmentVariables/url(_:)``

### Error Handling

- ``EnvironmentVariables/Error``
- ``EnvironmentVariables/LiveError``

### Testing

- ``EnvironmentVariables/testValue``
- ``EnvironmentVariables/local``

### Dependencies Integration

- ``DependencyValues/envVars``