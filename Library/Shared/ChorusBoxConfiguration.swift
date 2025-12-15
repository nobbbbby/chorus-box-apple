import Foundation

public struct ChorusBoxConfiguration: Sendable {
    public enum Platform: Sendable {
        case iOS
        case macOS
        case tvOS
        case systemExtension
    }

    public let platform: Platform
    public let applicationName: String
    public let usesSystemExtension: Bool
    public let isBeta: Bool

    public init(
        platform: Platform,
        applicationName: String,
        usesSystemExtension: Bool,
        isBeta: Bool
    ) {
        self.platform = platform
        self.applicationName = applicationName
        self.usesSystemExtension = usesSystemExtension
        self.isBeta = isBeta
    }

    private static var storage: ChorusBoxConfiguration?
    private static let lock = NSLock()

    public static func configure(_ configuration: ChorusBoxConfiguration) {
        lock.lock()
        defer { lock.unlock() }
        precondition(storage == nil, "ChorusBoxConfiguration was configured more than once")
        storage = configuration
    }

    public static var current: ChorusBoxConfiguration {
        lock.lock()
        defer { lock.unlock() }
        guard let configuration = storage else {
            fatalError("ChorusBoxConfiguration.configure(_:) must be called before accessing the configuration")
        }
        return configuration
    }

    public static var isConfigured: Bool {
        lock.lock()
        defer { lock.unlock() }
        return storage != nil
    }

    @discardableResult
    public static func configureIfNeeded(_ builder: () -> ChorusBoxConfiguration) -> ChorusBoxConfiguration {
        lock.lock()
        defer { lock.unlock() }
        if let configuration = storage {
            return configuration
        }
        let configuration = builder()
        storage = configuration
        return configuration
    }
}
