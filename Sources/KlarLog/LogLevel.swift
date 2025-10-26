//
//  LogLevel.swift
//  KlarLog
//

/// Log severity levels following standard logging conventions.
///
/// Ordered from least to most severe. Use the lowest level that conveys the needed
/// information so downstream systems can filter effectively.
///
/// - .debug: Detailed information for development and troubleshooting.
/// - .info: General operational messages about normal flow.
/// - .notice: Significant but expected conditions worth noting.
/// - .warning: Something unexpected happened or may cause a problem.
/// - .error: A failure occurred that impacted functionality.
/// - .critical: An unrecoverable failure requiring immediate attention.
public enum LogLevel: String, Sendable, CaseIterable {
    case debug, info, notice, warning, error, critical
}
