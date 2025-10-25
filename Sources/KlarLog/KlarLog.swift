import Foundation
import os

//public enum LogLevel: String {
//    case debug = "DEBUG"
//    case info = "INFO"
//    case warning = "WARNING"
//    case error = "ERROR"
//    
//    var osLogType: OSLogType {
//        switch self {
//        case .debug: return .debug
//        case .info: return .info
//        case .warning: return .default
//        case .error: return .error
//        }
//    }
//}
//
//public protocol LogDestination: Sendable {
//    func log(level: LogLevel, message: String, subsystem: String, category: String)
//}
//
//public struct SubsystemLogger {
//    private let logger: Logger
//    private let subsystem: String
//    
//    
//    public init(_ logger: Logger, subsystem: String) {
//        self.logger = logger
//        self.subsystem = subsystem
//    }
//
//    public func debug(_ message: String, tag: String) {
//        logger.log(.debug, subsystem: subsystem, category: tag, message)
//    }
//
//    public func info(_ message: String, tag: String) {
//        logger.log(.info, subsystem: subsystem, category: tag, message)
//    }
//
//    public func warning(_ message: String, tag: String) {
//        logger.log(.warning, subsystem: subsystem, category: tag, message)
//    }
//
//    public func error(_ message: String, tag: String) {
//        logger.log(.error, subsystem: subsystem, category: tag, message)
//    }
//}
//
//public class LoggerConfiguration {
//    fileprivate var destinations: [LogDestination] = []
//    
//    public init() {}
//    
//    @discardableResult
//    public func addDestination(_ destination: LogDestination) -> Self {
//        destinations.append(destination)
//        return self
//    }
//}
//
//public final class Logger: Sendable {
//    public static var shared = Logger(enableOSLog: true, fileLogPath: nil)
//
//    private var destinations: [LogDestination] = []
//
//    // Configure on init. By default, enable OSLog and do not enable file logging unless a valid path is provided.
//    public init(enableOSLog: Bool = true, fileLogPath: String? = nil) {
//        if enableOSLog {
//            destinations.append(OSLogDestination())
//        }
//        if let path = fileLogPath, let fileDestination = FileLogDestination(filePath: path) {
//            destinations.append(fileDestination)
//        }
//    }
//    
//    fileprivate func log(_ level: LogLevel, subsystem: String, category: String, _ message: String) {
//        for destination in destinations {
//            destination.log(level: level, message: message, subsystem: subsystem, category: category)
//        }
//    }
//}
//
//public class FileLogDestination: LogDestination {
//    private let fileURL: URL
//    private let fileHandle: FileHandle?
//    private let queue = DispatchQueue(label: "FileLoggerQueue", qos: .background)
//
//    public init?(filePath: String) {
//        let url = URL(fileURLWithPath: filePath)
//        self.fileURL = url
//        if !FileManager.default.fileExists(atPath: filePath) {
//            FileManager.default.createFile(atPath: filePath, contents: nil)
//        }
//        self.fileHandle = try? FileHandle(forWritingTo: url)
//        self.fileHandle?.seekToEndOfFile()
//    }
//    
//    public func log(level: LogLevel, message: String, subsystem: String, category: String) {
//        queue.async {
//            let timestamp = ISO8601DateFormatter().string(from: Date())
//            let line = "[\(timestamp)] [\(subsystem):\(category)] [\(level.rawValue)] \(message)\n"
//            if let data = line.data(using: .utf8) {
//                self.fileHandle?.write(data)
//            }
//        }
//    }
//
//    deinit {
//        try? fileHandle?.close()
//    }
//}
//
//public class OSLogDestination: LogDestination {
//    public func log(level: LogLevel, message: String, subsystem: String, category: String) {
//        let oslog = OSLog(subsystem: subsystem, category: category)
//        os_log("%{public}@", log: oslog, type: level.osLogType, message)
//        
//        let logger = os.Logger(subsystem: subsystem, category: category)
//        
//        switch level {
//        case .debug:
//            logger.debug("\(message)")
//        case .info:
//            logger.info("\(message)")
//        case .warning:
//            logger.warning("\(message)")
//        case .error:
//            logger.error("\(message)")
//        }
//        
//    }
//    
//    public init() {}
//}
