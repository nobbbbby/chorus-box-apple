import Foundation
import Library
import SwiftUI

public enum NavigationPlatform: CaseIterable {
    case iOS
    case macOS
    case tvOS

    public static var current: NavigationPlatform {
        #if os(macOS)
            return .macOS
        #elseif os(tvOS)
            return .tvOS
        #else
            return .iOS
        #endif
    }
}

public enum NavigationPage: String, CaseIterable, Identifiable {
    public var id: Self { self }

    case dashboard
    case groups
    case connections
    case logs
    case profiles
    case settings

    private struct Descriptor {
        let titleKey: LocalizedStringResource
        let iconSystemName: String
        let supportedPlatforms: Set<NavigationPlatform>
        let requiresConnectedProfile: Bool

        init(
            titleKey: LocalizedStringResource,
            iconSystemName: String,
            supportedPlatforms: Set<NavigationPlatform>,
            requiresConnectedProfile: Bool = false
        ) {
            self.titleKey = titleKey
            self.iconSystemName = iconSystemName
            self.supportedPlatforms = supportedPlatforms
            self.requiresConnectedProfile = requiresConnectedProfile
        }
    }

    private static let descriptors: [NavigationPage: Descriptor] = [
        .dashboard: Descriptor(
            titleKey: "Dashboard",
            iconSystemName: "text.and.command.macwindow",
            supportedPlatforms: Set(NavigationPlatform.allCases)
        ),
        .groups: Descriptor(
            titleKey: "Groups",
            iconSystemName: "rectangle.3.group.fill",
            supportedPlatforms: [.macOS],
            requiresConnectedProfile: true
        ),
        .connections: Descriptor(
            titleKey: "Connections",
            iconSystemName: "list.bullet.rectangle.portrait.fill",
            supportedPlatforms: [.macOS],
            requiresConnectedProfile: true
        ),
        .logs: Descriptor(
            titleKey: "Logs",
            iconSystemName: "doc.text.fill",
            supportedPlatforms: Set(NavigationPlatform.allCases)
        ),
        .profiles: Descriptor(
            titleKey: "Profiles",
            iconSystemName: "list.bullet.rectangle.fill",
            supportedPlatforms: Set(NavigationPlatform.allCases)
        ),
        .settings: Descriptor(
            titleKey: "Settings",
            iconSystemName: "gear.circle.fill",
            supportedPlatforms: Set(NavigationPlatform.allCases)
        ),
    ]

    private var descriptor: Descriptor {
        // Force unwrap is safe due to static table
        Self.descriptors[self]!
    }

    static func pages(for platform: NavigationPlatform) -> [NavigationPage] {
        allCases.filter { $0.supports(platform) }
    }

    static func pagesForCurrentPlatform() -> [NavigationPage] {
        pages(for: .current)
    }

    static var macosDefaultPages: [NavigationPage] {
        pages(for: .macOS).filter { $0 != .dashboard && !$0.descriptor.requiresConnectedProfile }
    }

    func supports(_ platform: NavigationPlatform) -> Bool {
        descriptor.supportedPlatforms.contains(platform)
    }

    var label: some View {
        Label(title, systemImage: descriptor.iconSystemName)
            .tint(.textColor)
    }

    var title: String {
        String(localized: descriptor.titleKey)
    }

    var requiresConnectedProfile: Bool {
        descriptor.requiresConnectedProfile
    }

    @MainActor
    var contentView: some View {
        viewBuilder {
            switch self {
            case .dashboard:
                DashboardView()
            case .groups:
                GroupListView()
            case .connections:
                ConnectionListView()
            case .logs:
                LogView()
            case .profiles:
                ProfileView()
            case .settings:
                SettingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
        #endif
    }

    func visible(_ profile: ExtensionProfile?) -> Bool {
        if requiresConnectedProfile {
            return profile?.status.isConnectedStrict == true
        }
        return true
    }
}
