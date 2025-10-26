//
//  ConsoleDestination.swift
//  KlarLog
//

import Foundation

/// A `LogDestination` that writes messages to the system console using `os.Logger`.
///
/// `ConsoleDestination` uses Apple's unified logging system (`os.Logger`) to write messages,
/// which integrates with Console.app and other system logging tools.
///
/// ## Xcode Previews Support
///
/// When running in Xcode Previews (where `os.Logger` is unavailable), this destination
/// automatically falls back to `print()` with formatted output.
///
/// Messages logged through this destination appear in:
/// - Xcode's debug console
/// - Console.app (searchable by subsystem and category)
/// - System logs accessible via `log` command-line tool
public struct ConsoleDestination: LogDestination, Sendable {
    /// The log levels that this destination should handle.
    ///
    /// Only messages whose level is included in this collection are written to the console.
    public var logForLogLevels: [LogLevel]
    
    /// Creates a console logging destination.
    ///
    /// - Parameter logForLogLevels: The log levels this destination should write. Messages whose level is not included are ignored. Defaults to all log levels.
    public init(logForLogLevels: [LogLevel] = LogLevel.allCases) {
        self.logForLogLevels = logForLogLevels
    }
    
    /// Writes a message to the system console using os.Logger.
    ///
    /// Falls back to `print()` when running in Xcode Previews where `os.Logger` is unavailable.
    /// - Parameters:
    ///   - subsystem: The logging subsystem, typically your app's bundle identifier.
    ///   - category: The logging category that groups related messages.
    ///   - level: The severity level for the message.
    ///   - message: The text to log.
    public func log(subsystem: String, category: String, level: LogLevel, message: String) {
        /// Only perform the action of this destination if it was configured to act on this log level.
        guard logForLogLevels.contains(level) else {
            return
        }
        
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Xcode Previews cannot use os.Logger; fall back to print.
            print("#OSLog_PREVIEW[\(level.rawValue.uppercased())][\(subsystem)][\(category)] \(message)")
        } else {
            let logger = os.Logger(subsystem: subsystem, category: category)
            
            switch level {
            case .debug:
                logger.debug("\(message)")
            case .info:
                logger.info("\(message)")
            case .notice:
                logger.notice("\(message)")
            case .warning:
                logger.warning("\(message)")
            case .error:
                logger.error("\(message)")
            case .critical:
                logger.critical("\(message)")
            }
        }
    }
}

