//
//  File.swift
//  KlarLog
//

import Foundation

/// A `LogDestination` that writes messages to a local file with automatic size management.
///
/// `LocalFileDestination` maintains a persistent log file and automatically manages its size
/// by removing old entries when the maximum message count is reached (FIFO - first in, first out).
///
/// ## Thread Safety
///
/// `LocalFileDestination` uses Swift's actor model to ensure thread-safe file access when
/// logging from multiple tasks simultaneously. All file operations are performed asynchronously
/// off the main thread.
///
/// ## File Format
///
/// Each log entry is written as a single line with ISO 8601 timestamp:
///
/// ```
/// 2025-10-25T14:30:45Z [ERROR] [com.example.app] [network] Connection failed
/// ```
///
/// ## Usage
///
/// ```swift
/// let fileURL = FileManager.default
///     .urls(for: .documentDirectory, in: .userDomainMask)[0]
///     .appendingPathComponent("app.log")
///
/// let localFileDestination = LocalFileDestination(
///     fileURL: fileURL,
///     maxMessages: 1000
/// )
///
/// let logger = CategoryLogger(
///     category: "network",
///     destinations: [ConsoleDestination(), localFileDestination]
/// )
/// ```
///
/// ## Reading Logs
///
/// Use `readLogs()` to retrieve all stored log entries asynchronously:
///
/// ```swift
/// let logs = await localFileDestination.readLogs()
/// print(logs.joined(separator: "\n"))
/// ```
///
/// - Important: File I/O operations may fail. The destination silently ignores errors
///   to prevent crashes, but you can check the file system directly if logs don't appear.
public final class LocalFileDestination: LogDestination, Sendable {
    /// The URL where log messages are stored.
    private let fileURL: URL
    
    /// The maximum number of log messages to retain before removing old entries.
    private let maxMessages: Int
    
    /// Human-readable date formatter for timestamp generation (localized, medium styles).
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    /// Actor that ensures serialized, thread-safe access to file operations.
    private let fileActor: FileOperationActor
    
    /// Creates a new file destination.
    ///
    /// If the file doesn't exist, it will be created on the first log write.
    /// If it exists, new messages are appended.
    ///
    /// - Parameters:
    ///   - fileURL: The URL where logs should be written. Must be a file URL.
    ///   - maxMessages: The maximum number of log messages to retain. When exceeded,
    ///     the oldest messages are removed (FIFO). Defaults to 1000.
    ///
    /// - Note: The file is not created or validated during initialization. The first
    ///   write operation will create it if necessary.
    public init(fileURL: URL, maxMessages: Int = 1000) {
        self.fileURL = fileURL
        self.maxMessages = maxMessages
        self.fileActor = FileOperationActor(fileURL: fileURL, maxMessages: maxMessages)
    }
    
    /// Writes a log message to the file asynchronously.
    ///
    /// The message is formatted with a timestamp and appended to the file. If the file
    /// exceeds `maxMessages`, the oldest entries are removed to maintain the limit.
    ///
    /// This method returns immediately and performs all file operations asynchronously
    /// off the main thread.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier.
    ///   - category: The category name.
    ///   - level: The severity level.
    ///   - message: The message text to log.
    public func log(subsystem: String, category: String, level: ExposedCategoryLogger.Level, message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let logLine = "\(timestamp)\t[\(level.rawValue.uppercased())]\t[\(category)] \(message)"
        
        Task.detached(priority: .utility) { [fileActor] in
            await fileActor.writeLog(logLine)
        }
    }
    
    /// Reads all log entries from the file asynchronously.
    ///
    /// Returns an array of log lines in the order they were written (oldest first).
    /// Each line includes the timestamp and full log context.
    ///
    /// - Returns: An array of log entry strings, or an empty array if the file doesn't
    ///   exist or cannot be read.
    public func readLogs() async -> [String] {
        return await fileActor.readLogs()
    }
    
    /// Reads all log entries as a single string from the file asynchronously.
    ///
    /// Returns the entire file contents (with trailing newline if present).
    /// If the file doesn't exist or can't be read, returns an empty string.
    ///
    /// - Returns: A single string containing all log entries.
    public func readLogsString() async -> String {
        return await fileActor.readLogsAsString()
    }
    
    /// Deletes all log entries from the file asynchronously.
    ///
    /// This removes the log file entirely. The file will be recreated on the next write.
    ///
    /// - Returns: `true` if the file was successfully deleted or didn't exist,
    ///   `false` if deletion failed.
    @discardableResult
    public func clearLogs() async -> Bool {
        return await fileActor.clearLogs()
    }
    
    /// Ensures the log file exists (creating it if necessary) and returns the URL for sharing/export.
    ///
    /// Use this when you want to share the log file with other apps (e.g., using a share sheet).
    /// This method is asynchronous and runs off the main thread via the internal file actor.
    ///
    /// - Returns: The URL of the log file. If creation fails, returns nil.
    public func logFileURLForSharing() async -> URL? {
        return await fileActor.ensureExistsAndReturnURL()
    }
}

// MARK: - File Operation Actor

/// An actor that serializes all file operations for thread-safe access.
private actor FileOperationActor {
    private let fileURL: URL
    private let maxMessages: Int
    
    init(fileURL: URL, maxMessages: Int) {
        self.fileURL = fileURL.appending(path: "app.logs")
        self.maxMessages = maxMessages
    }
    
    /// Writes a log line to the file and enforces the message limit.
    internal func writeLog(_ logLine: String) {
        // Read existing logs
        var lines = readLogsInternal()
        
        // Add new log
        lines.append(logLine)
        
        // Enforce FIFO limit
        if lines.count > maxMessages {
            lines = Array(lines.suffix(maxMessages))
        }
        
        // Write back to file
        let content = lines.joined(separator: "\n") + "\n"
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            // Silently fail to avoid crashing the app
        }
    }
    
    /// Reads all log entries from the file.
    func readLogs() -> [String] {
        return readLogsInternal()
    }
    
    /// Reads all log entries from the file as a single string.
    func readLogsAsString() -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ""
        }
        guard let data = try? Data(contentsOf: fileURL),
              let content = String(data: data, encoding: .utf8) else {
            return ""
        }
        return content
    }
    
    /// Deletes the log file.
    func clearLogs() -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return true
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            return false
        }
    }
    
    /// Ensures the file exists on disk and returns its URL.
    /// If the file doesn't exist, it creates an empty file at the target URL.
    /// If creation fails, it still returns the intended URL so callers can handle errors upstream.
    func ensureExistsAndReturnURL() -> URL? {
        let fm = FileManager.default
        let path = fileURL.path
        if !fm.fileExists(atPath: path) {
            // Ensure parent directory exists
            let dirURL = fileURL.deletingLastPathComponent()
            try? fm.createDirectory(at: dirURL, withIntermediateDirectories: true)
            // Create empty file
            let created = fm.createFile(atPath: path, contents: Data(), attributes: nil)
            if !created {
                // Fall through
                return nil
            }
        }
        return fileURL
    }
    
    // MARK: - Private Methods
    
    /// Internal read method.
    private func readLogsInternal() -> [String] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }
        
        return content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }
}

