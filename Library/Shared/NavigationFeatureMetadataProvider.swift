import Foundation

public enum NavigationFeatureMetadataProvider {
    /// Register defaults and return descriptors for a platform without pulling in SwiftUI builders.
    @discardableResult
    public static func preload(for platform: NavigationPlatform) -> [NavigationFeatureDescriptor] {
        descriptors(for: platform)
    }

    public static func descriptors(for platform: NavigationPlatform) -> [NavigationFeatureDescriptor] {
        NavigationFeatureRegistry.shared.registerDefaultDescriptorsIfNeeded()
        return NavigationFeatureRegistry.shared.features(for: platform)
    }

    public static func descriptor(id: String) -> NavigationFeatureDescriptor? {
        NavigationFeatureRegistry.shared.registerDefaultDescriptorsIfNeeded()
        return NavigationFeatureRegistry.shared.descriptor(withID: id)
    }

    /// Data-only accessor for consumers that cannot depend on SwiftUI view builders (widgets, intents).
    public static func availableDescriptors(
        for platform: NavigationPlatform,
        profile: ExtensionProfile?
    ) -> [NavigationFeatureDescriptor] {
        descriptors(for: platform).filter { descriptor in
            guard descriptor.requiresConnectedProfile else { return true }
            return profile?.status.isConnectedStrict == true
        }
    }
}
