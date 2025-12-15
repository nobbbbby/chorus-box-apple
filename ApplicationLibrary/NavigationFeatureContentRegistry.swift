import SwiftUI

final class NavigationFeatureContentRegistry {
    static let shared = NavigationFeatureContentRegistry()

    private var builders: [String: () -> AnyView] = [:]
    private let lock = NSLock()

    private init() {}

    func register(id: String, builder: @escaping () -> AnyView) {
        lock.lock()
        builders[id] = builder
        lock.unlock()
    }

    func builder(for id: String) -> (() -> AnyView)? {
        lock.lock()
        defer { lock.unlock() }
        return builders[id]
    }
}
