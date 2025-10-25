//
//  File.swift
//  KlarLog
//
//  Created by Henri Bredt on 25.10.25.
//

import Foundation

public protocol LogDestination {
    func log(subsystem: String, category: String, level: Category.Level, message: String)
}

// MARK: - Default destination
public struct ConsoleDestination: LogDestination {
    public init() {}
    
    public func log(subsystem: String, category: String, level: Category.Level, message: String) {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Previews can't use OSLog so falling back to print
            print("[OSLog_PREVIEW][\(level.rawValue.uppercased())][\(subsystem)][\(category)] \(message)")
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

