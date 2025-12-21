import Foundation
import Library
import SwiftUI

public struct NavigationFeature: Identifiable {
    public let descriptor: NavigationFeatureDescriptor
    private let contentBuilder: () -> AnyView

    init(descriptor: NavigationFeatureDescriptor, contentBuilder: @escaping () -> AnyView) {
        self.descriptor = descriptor
        self.contentBuilder = contentBuilder
    }

    public var id: String {
        descriptor.id
    }

    @MainActor
    public var label: some View {
        Label(
            String(localized: LocalizedStringResource(stringLiteral: descriptor.titleKey)),
            systemImage: descriptor.iconSystemName
        )
        .tint(.textColor)
    }

    @MainActor
    public var title: String {
        String(localized: LocalizedStringResource(stringLiteral: descriptor.titleKey))
    }

    @MainActor
    public var contentView: AnyView {
        contentBuilder()
    }

    public var requiresConnectedProfile: Bool {
        descriptor.requiresConnectedProfile
    }

    public func isVisible(for profile: ExtensionProfile?) -> Bool {
        guard requiresConnectedProfile else {
            return true
        }
        return profile?.status.isConnectedStrict == true
    }
}

extension NavigationFeature: Hashable {
    public static func == (lhs: NavigationFeature, rhs: NavigationFeature) -> Bool {
        lhs.descriptor.id == rhs.descriptor.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(descriptor.id)
    }
}

extension NavigationFeature {
    public static var fallback: NavigationFeature {
        NavigationFeature(
            descriptor: NavigationFeatureDescriptor(
                id: NavigationFeatureID.dashboard,
                titleKey: "Dashboard",
                iconSystemName: "text.and.command.macwindow",
                supportedPlatforms: Set(NavigationPlatform.allCases)
            ),
            contentBuilder: { AnyView(EmptyView()) }
        )
    }
}

public enum NavigationFeatureID {
    public static let dashboard = "dashboard"
    public static let groups = "groups"
    public static let connections = "connections"
    public static let profiles = "profiles"
    public static let settings = "settings"
}

public enum NavigationFeatureProvider {
    @MainActor
    public static func descriptors(for platform: NavigationPlatform = NavigationPlatform.current) -> [NavigationFeatureDescriptor] {
        NavigationFeatureRegistry.shared.registerDefaultDescriptorsIfNeeded()
        NavigationFeatureBootstrap.bootstrap()
        return NavigationFeatureRegistry.shared.features(for: platform)
    }

    @MainActor
    public static func descriptor(id: String) -> NavigationFeatureDescriptor? {
        NavigationFeatureRegistry.shared.registerDefaultDescriptorsIfNeeded()
        NavigationFeatureBootstrap.bootstrap()
        return NavigationFeatureRegistry.shared.descriptor(withID: id)
    }

    @MainActor
    public static func availableFeatures(for profile: ExtensionProfile?) -> [NavigationFeature] {
        let descriptors = descriptors(for: NavigationPlatform.current)
        return descriptors.compactMap { descriptor -> NavigationFeature? in
            guard let builder = NavigationFeatureContentRegistry.shared.builder(for: descriptor.id) else {
                return nil
            }
            let feature = NavigationFeature(descriptor: descriptor, contentBuilder: builder)
            if feature.isVisible(for: profile) {
                return feature
            }
            return descriptor.requiresConnectedProfile ? nil : feature
        }
    }

    @MainActor
    public static func macOSFeatures(for profile: ExtensionProfile?) -> [NavigationFeature] {
        let descriptors = descriptors(for: .macOS)
        return descriptors.compactMap { descriptor -> NavigationFeature? in
            guard let builder = NavigationFeatureContentRegistry.shared.builder(for: descriptor.id) else {
                return nil
            }
            let feature = NavigationFeature(descriptor: descriptor, contentBuilder: builder)
            if feature.isVisible(for: profile) {
                return feature
            }
            return descriptor.requiresConnectedProfile ? nil : feature
        }
    }

    @MainActor
    public static func feature(id: String) -> NavigationFeature? {
        guard
            let descriptor = descriptor(id: id),
            let builder = NavigationFeatureContentRegistry.shared.builder(for: id)
        else {
            return nil
        }
        return NavigationFeature(descriptor: descriptor, contentBuilder: builder)
    }

    @MainActor
    public static func defaultFeature() -> NavigationFeature? {
        feature(id: NavigationFeatureID.dashboard)
    }
}

enum NavigationFeatureBootstrap {
    private static var didRegister = false
    private static let logger = AppLog.logger(category: "navigation")

    @MainActor
    static func bootstrap() {
        guard !didRegister else {
            return
        }
        didRegister = true
        registerFeatures()
    }

    @MainActor
    private static func registerFeatures() {
        logger.info("registering features")
        NavigationFeatureRegistry.shared.registerDefaultDescriptorsIfNeeded()
        register(id: NavigationFeatureID.dashboard) {
            DashboardView()
        }
        register(id: NavigationFeatureID.groups) {
            GroupListView()
        }
        register(id: NavigationFeatureID.connections) {
            ConnectionListView()
        }
        register(id: NavigationFeatureID.profiles) {
            ProfileView()
        }
        register(id: NavigationFeatureID.settings) {
            SettingView()
        }
    }

    @MainActor
    private static func register(
        id: String,
        @ViewBuilder builder: @escaping () -> some View
    ) {
        NavigationFeatureContentRegistry.shared.register(id: id) {
            AnyView(
                builder()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    #if os(iOS)
                        .background(Color(uiColor: .systemGroupedBackground))
                    #endif
            )
        }
    }
}
