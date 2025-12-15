import Foundation

public struct NavigationFeatureDescriptor: Identifiable, Hashable {
    public let id: String
    public let titleKey: String
    public let iconSystemName: String
    public let supportedPlatforms: Set<NavigationPlatform>
    public let requiresConnectedProfile: Bool

    public init(
        id: String,
        titleKey: String,
        iconSystemName: String,
        supportedPlatforms: Set<NavigationPlatform>,
        requiresConnectedProfile: Bool = false
    ) {
        self.id = id
        self.titleKey = titleKey
        self.iconSystemName = iconSystemName
        self.supportedPlatforms = supportedPlatforms
        self.requiresConnectedProfile = requiresConnectedProfile
    }
}

public final class NavigationFeatureRegistry {
    public static let shared = NavigationFeatureRegistry()

    private var descriptors: [NavigationFeatureDescriptor] = []
    // Recursive to allow default registration to call through to `register` without deadlocking.
    private let lock = NSRecursiveLock()
    private var didRegisterDefaults = false

    private init() {}

    public func register(_ descriptor: NavigationFeatureDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        guard !descriptors.contains(where: { $0.id == descriptor.id }) else {
            return
        }
        descriptors.append(descriptor)
    }

    public func registerDefaultDescriptorsIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didRegisterDefaults else {
            return
        }
        didRegisterDefaults = true
        register(
            NavigationFeatureDescriptor(
                id: "dashboard",
                titleKey: "Dashboard",
                iconSystemName: "text.and.command.macwindow",
                supportedPlatforms: Set(NavigationPlatform.allCases)
            )
        )
        register(
            NavigationFeatureDescriptor(
                id: "groups",
                titleKey: "Groups",
                iconSystemName: "rectangle.3.group.fill",
                supportedPlatforms: [.macOS],
                requiresConnectedProfile: true
            )
        )
        register(
            NavigationFeatureDescriptor(
                id: "connections",
                titleKey: "Connections",
                iconSystemName: "list.bullet.rectangle.portrait.fill",
                supportedPlatforms: [.macOS],
                requiresConnectedProfile: true
            )
        )
        register(
            NavigationFeatureDescriptor(
                id: "logs",
                titleKey: "Logs",
                iconSystemName: "doc.text.fill",
                supportedPlatforms: Set(NavigationPlatform.allCases)
            )
        )
        register(
            NavigationFeatureDescriptor(
                id: "profiles",
                titleKey: "Profiles",
                iconSystemName: "list.bullet.rectangle.fill",
                supportedPlatforms: Set(NavigationPlatform.allCases)
            )
        )
        register(
            NavigationFeatureDescriptor(
                id: "settings",
                titleKey: "Settings",
                iconSystemName: "gear.circle.fill",
                supportedPlatforms: Set(NavigationPlatform.allCases)
            )
        )
    }

    public func allFeatures() -> [NavigationFeatureDescriptor] {
        lock.lock()
        defer { lock.unlock() }
        return descriptors
    }

    public func descriptor(withID id: String) -> NavigationFeatureDescriptor? {
        lock.lock()
        defer { lock.unlock() }
        return descriptors.first(where: { $0.id == id })
    }

    public func features(for platform: NavigationPlatform) -> [NavigationFeatureDescriptor] {
        lock.lock()
        defer { lock.unlock() }
        return descriptors.filter { $0.supportedPlatforms.contains(platform) }
    }
}
