//
//  File.swift
//  KlarLog
//

/// Internal logging instance that routes log messages to configured destinations.
///
/// `CategoryLogger` represents a logging category (e.g., "network", "database") and
/// maintains a list of destinations where log messages should be sent. After initialization
/// and configuration in your registry in `KlarLog`, these instances are wrapped by `ExposedCategoryLogger`
/// which provides the public logging API.
///
/// You create `CategoryLogger` instances in your registry and configure them with destinations:
///
/// ```swift
/// public struct CategoryLoggers {
///     public let network = CategoryLogger(
///         category: "network",
///         destinations: [ConsoleDestination()]
///     )
/// }
/// ```
///
/// After configuring the regisitry of `KlarLog` as shown above, end users never interact with
/// `CategoryLogger` directly as all logging is performed through `ExposedCategoryLogger` instances
/// returned by `KlarLog`.
public struct CategoryLogger {
    /// The category name for this logger (e.g., "network", "database").
    private let category: String
    /// The list of destinations that will receive log messages from this category.
    private var destinations: [LogDestination]
    
    /// Creates a new category logger.
    ///
    /// - Parameters:
    ///   - category: The category name that will be used to tag all log messages.
    ///   - destinations: The list of destinations where messages should be sent.
    public init(category: String, destinations: [LogDestination]) {
        self.category = category
        self.destinations = destinations
    }
    
    /// Routes a log message to all configured destinations.
    /// This method is only called by `ExposedCategoryLogger`.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (e.g., "com.example.app").
    ///   - level: The severity level of the log message.
    ///   - message: The message text of the log.
    fileprivate func log(subsystem: String, level: ExposedCategoryLogger.Level, message: String) {
        destinations.forEach { $0.log(subsystem: subsystem, category: category, level: level, message: message) }
    }
}

/// The public-facing logging interface that provides convenience methods for logging at different severity levels.
///
/// `ExposedCategoryLogger` wraps a `CategoryLogger` and binds it to a specific subsystem, providing
/// ergonomic logging methods like `debug(_:)`, `info(_:)`, and `error(_:)`. You obtain instances
/// of `ExposedCategoryLogger` from `KlarLog` via dynamic member lookup.
///
/// ## Usage
///
/// ```swift
/// let log = KlarLog(with: CategoryLoggers(), subsystem: "com.example.app")
/// // Given a registry with `debug`, `info` and `error` `CategoryLogger` instances
/// log.network.debug("Starting request")
/// log.network.info("Response received")
/// log.network.error("Connection failed")
/// ```
public struct ExposedCategoryLogger {
    /// Log severity levels following standard logging conventions.
    ///
    /// Levels are ordered from least to most severe:
    /// - `debug`: Detailed information for debugging
    /// - `info`: General informational messages
    /// - `notice`: Normal but significant conditions
    /// - `warning`: Warning conditions that should be reviewed
    /// - `error`: Error conditions that need attention
    /// - `critical`: Critical conditions requiring immediate action
    public enum Level: String {
        case debug, info, notice, warning, error, critical
    }
    
    /// Closure that provides the current subsystem identifier.
    private let subsystem: () -> String
    /// The underlying category logger that routes messages to destinations.
    public var base: CategoryLogger
    
    /// Creates a new exposed category logger.
    ///
    /// This initializer is typically called by `KlarLog` via dynamic member lookup.
    /// You should not need to create instances manually.
    ///
    /// - Parameters:
    ///   - subsystem: A closure that returns the current subsystem string.
    ///   - base: The underlying `CategoryLogger` that routes messages to destinations.
    internal init(subsystem: @escaping () -> String, base: CategoryLogger) {
        self.subsystem = subsystem
        self.base = base
    }
    
    /// Routes a log message at the specified level to all configured destinations.
    ///
    /// - Parameters:
    ///   - level: The severity level of the message.
    ///   - message: The message text to log.
    private func log(_ level: Level, _ message: String) {
        base.log(subsystem: subsystem(), level: level, message: message)
    }
    
    // MARK: - Convenience logging methods
    
    /// Logs a debug message.
    ///
    /// Use for detailed information useful during development and debugging.
    ///
    /// - Parameter message: The message to log.
    public func debug(_ message: String) {
        self.log(.debug, message)
    }
    
    /// Logs an informational message.
    ///
    /// Use for general informational messages about normal application flow.
    ///
    /// - Parameter message: The message to log.
    public func info(_ message: String) {
        self.log(.info, message)
    }
    
    /// Logs a notice message.
    ///
    /// Use for normal but significant conditions that may require attention.
    ///
    /// - Parameter message: The message to log.
    public func notice(_ message: String) {
        self.log(.notice, message)
    }
    
    /// Logs a warning message.
    ///
    /// Use for warning conditions that should be reviewed but don't prevent operation.
    ///
    /// - Parameter message: The message to log.
    public func warning(_ message: String) {
        self.log(.warning, message)
    }
    
    /// Logs an error message.
    ///
    /// Use for error conditions that need attention and may affect functionality.
    ///
    /// - Parameter message: The message to log.
    public func error(_ message: String) {
        self.log(.error, message)
    }
    
    /// Logs a critical message.
    ///
    /// Use for critical conditions that require immediate action.
    ///
    /// - Parameter message: The message to log.
    public func critical(_ message: String) {
        self.log(.critical, message)
    }
}
