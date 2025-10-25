//
//  KlarLog
//  Simplified version - no privacy parameters
//

@dynamicMemberLookup
public final class KlarLog<Registry> {
    private var registry: Registry
    private var subsystem: String
    
    public init(with registry: Registry, subsystem: String) {
        self.registry = registry
        self.subsystem = subsystem
    }
    
    /// Provides read-only dynamic member lookup into the underlying `registry`.
    ///
    /// Using `@dynamicMemberLookup`, property access on `KlarLog` that matches a `KeyPath` on `Registry`
    /// is forwarded to the `registry` instance. For example, `log.someProperty` resolves to
    /// `registry[\.someProperty]`.
    ///
    /// - Parameter keyPath: A `KeyPath` into `Registry` for the requested value.
    /// - Returns: The value at the given key path from the `registry`.
    subscript<T>(dynamicMember keyPath: KeyPath<Registry, T>) -> T {
        registry[keyPath: keyPath]
    }
    
//    /// Provides read–write dynamic member lookup into the underlying `registry` when the member is writable.
//    ///
//    /// This overload enables both reading and assigning via dynamic member syntax. For example,
//    /// `log.someMutableProperty = value` writes through to `registry[\.someMutableProperty] = value`.
//    ///
//    /// - Parameter keyPath: A `WritableKeyPath` into `Registry` for the requested value.
//    /// - Returns: The current value at the given key path from the `registry`.
//    subscript<T>(dynamicMember keyPath: WritableKeyPath<Registry, T>) -> T {
//        get { registry[keyPath: keyPath] }
//        set { registry[keyPath: keyPath] = newValue }
//    }
}

public extension KlarLog {
    subscript(dynamicMember keyPath: KeyPath<Registry, CategoryLogger>) -> Category {
        let base = registry[keyPath: keyPath]
        return Category(subsystem: { [weak self] in self?.subsystem ?? "" }, base: base)
    }
    
    subscript(dynamicMember keyPath: WritableKeyPath<Registry, CategoryLogger>) -> Category {
        let base = registry[keyPath: keyPath]
        return Category(subsystem: { [weak self] in self?.subsystem ?? "" }, base: base)
    }
}
