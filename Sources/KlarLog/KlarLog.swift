//
//  KlarLog.swift
//  KlarLog
//


/// The primary entry point for logging in your application.
/// A `KlarLog` instance stores `CategoryLogger` instances in a registry and provides
/// ergonomic read-only access.
///
/// By using `@dynamicMemberLookup`, `KlarLog` provides direct access to registry
/// properties as if they were its own, returning fully-configured `ExposedCategoryLogger`
/// instances ready for logging. All logging is solely handled by `ExposedCategoryLogger`
/// instances that wrap the underlying `CategoryLogger` and provide logging APIs.
///
/// `KlarLog` is a lightweight facade that binds a logging registry to a subsystem
/// identifier by wrapping a registry of `CategoryLogger` instances and automatically
/// associates each logger with a subsystem string in the returned `ExposedCategoryLogger`.
///
/// Destinations are provided via a destinations registry that you supply at init.
/// `KlarLog` exposes that registry directly through `logger.destinations.<member>`, and also
/// collects all `LogDestination` values at init time to supply them to the exposed category loggers.
///
/// ## Usage
///
/// Define a registry with your application's logging categories of type `CategoryLogger`.
/// Perform `CategoryLogger` configuration in the registry's initializer or property declarations:
///
/// ```swift
/// public struct CategoryLoggers {
///    public let general = CategoryLogger(category: "general")
///    public let authentication = CategoryLogger(category: "auth")
/// }
/// ```
///
/// Define a destinations registry with concrete `LogDestination` implementations:
///
/// ```swift
/// public struct LogDestinations {
///    public let console = ConsoleDestination()
///    public let file = LocalFileDestination(fileURL: .desktopDirectory, maxMessages: 800)
/// }
/// ```
///
/// Create a single shared `KlarLog` instance at app startup:
///
/// ```swift
/// let log = KlarLog(
///     with: CategoryLoggers(),
///     destinationsRegistry: LogDestinations(),
///     subsystem: Bundle.main.bundleIdentifier ?? "com.example.app"
/// )
/// ```
///
/// Then log throughout your app using the configured categories:
///
/// ```swift
/// log.general.info("Starting request")
/// log.authentication.error("Password is empty String")
/// ```
///
/// Access destination instances directly from the destination registry you provided:
///
/// ```swift
/// let file = log.destinations.file // LocalFileDestination
/// let console = log.destinations.console // ConsoleDestination
/// ```
///
/// - Important: Only `CategoryLogger` properties on `Registry` are accessible via
///   dynamic member lookup on `KlarLog` (e.g., `log.general`). Other property types
///   should not be stored in the `Registry` and will not be exposed as `ExposedCategoryLogger`s.
@dynamicMemberLookup
public final class KlarLog<Registry, DestinationRegistry> {
    /// The underlying registry that provides concrete `CategoryLogger` instances.
    private var registry: Registry
    /// The destinations registry that provides concrete `LogDestination` instances.
    private var destinationsRegistry: DestinationRegistry
    /// The logging subsystem name associated with this `KlarLog` instance.
    private var subsystem: String
    
    /// The cached list of destinations.
    private var _destinations: [LogDestination]
    
    /// Creates a new `KlarLog` instance.
    /// Typically you'll only want to create one globally shared instance.
    ///
    /// - Note:
    /// `KlarLog` expects `registry` to contain only `CategoryLogger` properties.
    /// Other property types will not be accessible through dynamic member lookup.
    ///
    /// - Parameters:
    ///   - registry: The backing registry whose properties of type `CategoryLogger` are projected via dynamic member lookup.
    ///   - destinationsRegistry: The backing registry whose properties of type `LogDestination` will be collected.
    ///   - subsystem: The subsystem string used to tag category loggers returned by this wrapper.
    public init(with registry: Registry, destinationsRegistry: DestinationRegistry, subsystem: String) {
        self.registry = registry
        self.destinationsRegistry = destinationsRegistry
        self.subsystem = subsystem
        // Reflect over the destinationsRegistry and collect all properties that are LogDestination
        var collected: [LogDestination] = []
        let mirror = Mirror(reflecting: destinationsRegistry)
        for child in mirror.children {
            if let destination = child.value as? LogDestination {
                collected.append(destination)
            }
        }
        self._destinations = collected
    }
  
    /// Dynamic member lookup for `CategoryLogger` entries on the registry.
    /// The returned `ExposedCategoryLogger` is bound to this instance's subsystem
    /// and uses the collected list of destinations from the destinations registry.
    ///
    /// This enables a fluent API such as:
    ///
    /// ```swift
    /// // Given a registry with a `network` CategoryLogger
    /// let log = KlarLog(with: registry, subsystem: "com.example.app")
    /// log.network.info("Fetching profile…")
    /// ```
    ///
    /// - Parameter keyPath: A `KeyPath` into `Registry` that resolves to a `CategoryLogger`.
    /// - Returns: An `ExposedCategoryLogger` that forwards to the resolved `CategoryLogger` and supplies the current `subsystem`.
    subscript(dynamicMember keyPath: KeyPath<Registry, CategoryLogger>) -> ExposedCategoryLogger {
        let base = registry[keyPath: keyPath]
        return ExposedCategoryLogger(
            subsystem: { [weak self] in self?.subsystem ?? "" },
            destinations: { [weak self] in self?._destinations ?? [] },
            base: base
        )
    }
  
    // MARK: - Destinations Direct Access

    /// Exposes the destinations registry directly so callers can use
    /// `logger.destinations.<member>` to access the concrete `LogDestination` instances
    /// defined on the registry type provided at init.
    ///
    /// Example:
    /// ```swift
    /// let console = logger.destinations.console
    /// let file = logger.destinations.file
    /// ```
    public var destinations: DestinationRegistry { destinationsRegistry }
}

