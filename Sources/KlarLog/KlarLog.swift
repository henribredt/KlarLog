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
/// instances ready for logging. All logging is soely handled by `ExposedCategoryLogger`
/// instances that warp the underlying `CategoryLogger` and provide loggin APIs.
///
/// `KlarLog` is a lightweight facade that binds a logging registry to a subsystem
/// identifier by wrapping a registry of `CategoryLogger` instances and automatically
/// associates each logger with a subsystem string in the retured `ExposedCategoryLogger`.
///
/// ## Usage
///
/// Define a registry with your application's logging categories of type `CategoryLogger`.
/// Perform `CategoryLogger` configuration on `init` of the instance:
///
/// ```swift
/// public struct CategoryLoggers {
///    public let general = CategoryLogger(
///        category: "general",
///        destinations: [ConsoleDestination()]
///    )
///    public let authentification = CategoryLogger(
///        category: "auth",
///        destinations: [ConsoleDestination()]
///    )
/// }
/// ```
///
/// Create a single shared `KlarLog` instance at app startup:
///
/// ```swift
/// let log = KlarLog(with: CategoryLoggers(), subsystem: "com.example.app")
/// ```
///
/// Then log throughout your app using the configured categories:
///
/// ```swift
/// log.general.info("Starting request")
/// log.auth.error("Password is empty String")
/// ```
///
/// Each log message is automatically tagged with your subsystem and the appropriate
/// category, making it easy to filter and organize logs in Console.app or other
/// logging tools.
///
/// - Important: Only `CategoryLogger` properties on `Registry` are accessible.
///   Other property types should not be stored in the `Registry` and will not be
///   exposed through dynamic member lookup as`ExposedCategoryLogger`.
@dynamicMemberLookup
public final class KlarLog<Registry> {
    /// The underlying registry that provides concrete `CategoryLogger` instances.
    private var registry: Registry
    /// The logging subsystem name associated with this `KlarLog` instance.
    private var subsystem: String
    
    /// Creates a new `KlarLog` instance.
    /// Typically you'll only want to create one globally shared instance.
    ///
    /// - Note:
    /// `KlarLog` expects `registry` to contain only `CategoryLogger` properties.
    /// Other property types will not be accessible through dynamic member lookup.
    ///
    /// - Parameters:
    ///   - registry: The backing registry whose properties of type `CategoryLogger` are projected via dynamic member lookup.
    ///   - subsystem: The subsystem string used to tag category loggers returned by this wrapper.
    public init(with registry: Registry, subsystem: String) {
        self.registry = registry
        self.subsystem = subsystem
    }
  
    /// Returns an `ExposedCategoryLogger` bound to this instance's `subsystem` when the requested
    /// member is a `CategoryLogger` on `Registry`.
    ///
    /// `ExposedCategoryLogger` is the user-facing logging surface that provides a
    /// ergonomic API for logging.
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
        return ExposedCategoryLogger(subsystem: { [weak self] in self?.subsystem ?? "" }, base: base)
    }
}

