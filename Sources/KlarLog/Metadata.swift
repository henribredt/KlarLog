//
//  Metadata.swift
//  KlarLog
//

import Foundation

/// A type-safe container for structured logging metadata.
///
/// `LogMetadata` allows you to attach structured data to log messages, enabling
/// richer context and easier log analysis. Values can be strings, numbers, booleans,
/// or nested structures.
///
/// ## Usage
///
/// ```swift
/// logger.network.info("Request completed", metadata: [
///     "url": "https://api.example.com",
///     "duration": 123.5,
///     "status": 200,
///     "success": true
/// ])
/// ```
///
/// Metadata is formatted differently based on the destination:
/// - `ConsoleDestination`: Appended as key-value pairs
/// - `LocalFileDestination`: Serialized as JSON
/// - Custom destinations: Format as needed
public struct LogMetadata: Sendable, ExpressibleByDictionaryLiteral {
    /// The underlying storage for metadata values.
    private let storage: [String: MetadataValue]

    /// Creates metadata from a dictionary literal.
    ///
    /// - Parameter elements: Key-value pairs where values conform to `MetadataConvertible`.
    public init(dictionaryLiteral elements: (String, MetadataConvertible)...) {
        var storage: [String: MetadataValue] = [:]
        for (key, value) in elements {
            storage[key] = value.metadataValue
        }
        self.storage = storage
    }

    /// Creates metadata from a dictionary.
    ///
    /// - Parameter dictionary: A dictionary of metadata key-value pairs.
    public init(_ dictionary: [String: MetadataConvertible]) {
        var storage: [String: MetadataValue] = [:]
        for (key, value) in dictionary {
            storage[key] = value.metadataValue
        }
        self.storage = storage
    }

    /// Returns all metadata as a dictionary.
    public var dictionary: [String: MetadataValue] {
        storage
    }

    /// Returns true if the metadata is empty.
    public var isEmpty: Bool {
        storage.isEmpty
    }

    /// Formats the metadata as a human-readable string.
    ///
    /// Output format: `key1=value1 key2=value2`
    ///
    /// - Returns: A formatted string representation of the metadata.
    public func formatted() -> String {
        storage
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value.stringValue)" }
            .joined(separator: " ")
    }

    /// Formats the metadata as JSON.
    ///
    /// - Returns: A JSON string representation, or empty string if encoding fails.
    public func jsonString() -> String {
        let dict = storage.mapValues { $0.jsonValue }
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}

/// A type-erased metadata value that can hold various data types.
///
/// `MetadataValue` wraps primitive types (String, Int, Double, Bool) and provides
/// consistent serialization interfaces for logging destinations.
public enum MetadataValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([MetadataValue])
    case dictionary([String: MetadataValue])

    /// Returns a string representation of the value.
    public var stringValue: String {
        switch self {
        case .string(let value):
            return "\"\(value)\""
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        case .array(let values):
            let items = values.map { $0.stringValue }.joined(separator: ", ")
            return "[\(items)]"
        case .dictionary(let dict):
            let items = dict.sorted(by: { $0.key < $1.key })
                .map { "\($0.key): \($0.value.stringValue)" }
                .joined(separator: ", ")
            return "{\(items)}"
        }
    }

    /// Returns a JSON-compatible value.
    public var jsonValue: Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        case .array(let values):
            return values.map { $0.jsonValue }
        case .dictionary(let dict):
            return dict.mapValues { $0.jsonValue }
        }
    }
}

/// A protocol for types that can be converted to metadata values.
///
/// Conform custom types to this protocol to use them in structured logging.
public protocol MetadataConvertible: Sendable {
    var metadataValue: MetadataValue { get }
}

// MARK: - Standard Type Conformances

extension String: MetadataConvertible {
    public var metadataValue: MetadataValue { .string(self) }
}

extension Int: MetadataConvertible {
    public var metadataValue: MetadataValue { .int(self) }
}

extension Double: MetadataConvertible {
    public var metadataValue: MetadataValue { .double(self) }
}

extension Float: MetadataConvertible {
    public var metadataValue: MetadataValue { .double(Double(self)) }
}

extension Bool: MetadataConvertible {
    public var metadataValue: MetadataValue { .bool(self) }
}

extension Array: MetadataConvertible where Element: MetadataConvertible {
    public var metadataValue: MetadataValue {
        .array(self.map { $0.metadataValue })
    }
}

extension Dictionary: MetadataConvertible where Key == String, Value: MetadataConvertible {
    public var metadataValue: MetadataValue {
        .dictionary(self.mapValues { $0.metadataValue })
    }
}
