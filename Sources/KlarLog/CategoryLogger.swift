//
//  CategoryLogger.swift
//  KlarLog
//

/// Internal logging instance that routes log messages to destinations provided by `KlarLog`.
///
/// `CategoryLogger` represents a logging category (e.g., "network", "database").
/// After initialization in your registry in `KlarLog`, these instances are wrapped by
/// `ExposedCategoryLogger` which provides the public logging API.
///
/// You create `CategoryLogger` instances in your registry; destinations are configured on `KlarLog`:
///
/// ```swift
/// public struct CategoryLoggers {
///     public let network = CategoryLogger(category: "network")
/// }
/// ```
///
/// After configuring the registry of `KlarLog` as shown above, end users never interact with
/// `CategoryLogger` directly as all logging is performed through `ExposedCategoryLogger`
/// instances returned by `KlarLog`.
public struct CategoryLogger: Sendable {
    /// The category name for this logger (e.g., "network", "database").
    let category: String
    
    /// Creates a new category logger.
    ///
    /// - Parameters:
    ///   - category: The category name that will be used to tag all log messages.
    public init(category: String) {
        self.category = category
    }
    
    /// Routes a log message to all provided destinations.
    /// This method is only called by `ExposedCategoryLogger`.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (e.g., "com.example.app").
    ///   - destinations: The list of destinations where messages should be sent.
    ///   - level: The severity level of the log message.
    ///   - message: The message text of the log.
    fileprivate func log(subsystem: String, destinations: [LogDestination], level: LogLevel, message: String) {
        destinations.forEach { $0.log(subsystem: subsystem, category: category, level: level, message: message) }
    }
}

/// Public-facing logging interface for category-based logging.
///
/// `ExposedCategoryLogger` wraps a `CategoryLogger` and binds it to a specific subsystem and a set of
/// destinations. It exposes ergonomic methods like `debug(_:)`, `info(_:)`, and `error(_:)`
/// for logging at different severity levels.
///
/// You don't construct `ExposedCategoryLogger` directly. Instead, obtain instances from `KlarLog`
/// using the category registry you define. The registry holds lightweight `CategoryLogger` values, while
/// `KlarLog` provides the subsystem and destinations.
///
/// Logging is fire-and-forget.
///
/// ## Usage
///
/// ```swift
/// let log = KlarLog(...)
///
/// // Given log was configured with a network `CategoryLogger`
/// log.network.debug("Starting request")
/// log.network.info("Response received")
/// log.network.error("Connection failed")
/// ```
public struct ExposedCategoryLogger {
    /// Closure that provides the current subsystem identifier.
    private let subsystem: () -> String
    /// Closure that provides the LogDestinations
    private let destinations: () -> [LogDestination]
    /// The underlying category logger that routes messages to destinations.
    private var base: CategoryLogger
    
    /// Creates a new exposed category logger.
    ///
    /// This initializer is typically called by `KlarLog` via dynamic member lookup.
    /// You should not need to create instances manually.
    ///
    /// - Parameters:
    ///   - subsystem: A closure that returns the current subsystem string.
    ///   - destinations: A closure that returns the current destinations.
    ///   - base: The underlying `CategoryLogger` that routes messages to destinations.
    public init(subsystem: @escaping () -> String, destinations: @escaping () -> [LogDestination], base: CategoryLogger) {
        self.subsystem = subsystem
        self.destinations = destinations
        self.base = base
    }
    
    /// Routes a log message at the specified level to all configured destinations.
    ///
    /// - Parameters:
    ///   - level: The severity level of the message.
    ///   - message: The message text to log.
    private func log(_ level: LogLevel, _ message: String) {
        base.log(subsystem: subsystem(), destinations: destinations(), level: level, message: message)
    }
    
    // MARK: - Convenience logging methods
    
    /// Logs a debug message.
    ///
    /// Use for verbose diagnostic information useful during development.
    ///
    /// - Parameter message: The message to log.
    ///
    /// ### Example
    /// ```swift
    /// log.network.debug("Request headers: \(headers)")
    /// ```
    public func debug(_ message: String) {
        self.log(.debug, message)
    }
    
    /// Logs an informational message.
    ///
    /// Use for general informational messages about normal application flow.
    ///
    /// - Parameter message: The message to log.
    ///
    /// ### Example
    /// ```swift
    /// log.network.info("Response received: status=\(status)")
    /// ```
    public func info(_ message: String) {
        self.log(.info, message)
    }
    
    /// Logs a notice message.
    ///
    /// Use for normal but significant conditions that may require attention.
    ///
    /// - Parameter message: The message to log.
    ///
    /// ### Example
    /// ```swift
    /// log.database.notice("Migration completed")
    /// ```
    public func notice(_ message: String) {
        self.log(.notice, message)
    }
    
    /// Logs a warning message.
    ///
    /// Use for conditions that could become errors or deserve review.
    ///
    /// - Parameter message: The message to log.
    ///
    /// ### Example
    /// ```swift
    /// log.network.warning("Slow response: \(latency) ms")
    /// ```
    public func warning(_ message: String) {
        self.log(.warning, message)
    }
    
    /// Logs an error message.
    ///
    /// Use for failures that affected functionality but may be recoverable.
    ///
    /// - Parameter message: The message to log.
    ///
    /// ### Example
    /// ```swift
    /// log.storage.error("Failed to write file: \(error.localizedDescription)")
    /// ```
    public func error(_ message: String) {
        self.log(.error, message)
    }
    
    /// Logs a critical message.
    ///
    /// Use for unrecoverable failures requiring immediate attention.
    ///
    /// - Parameter message: The message to log.
    ///
    /// ### Example
    /// ```swift
    /// log.auth.critical("Token compromise detected")
    /// ```
    public func critical(_ message: String) {
        self.log(.critical, message)
    }
}

