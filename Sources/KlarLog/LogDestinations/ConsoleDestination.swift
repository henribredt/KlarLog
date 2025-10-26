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
    public init() {}
    
    public func log(subsystem: String, category: String, level: ExposedCategoryLogger.Level, message: String) {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Previews can't use OSLog so falling back to print
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

