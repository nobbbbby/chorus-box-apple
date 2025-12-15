import ApplicationLibrary
import Library
import SwiftUI

public struct SidebarView: View {
    @Environment(\.selection) private var selection
    @EnvironmentObject private var appShell: AppShellState

    public init() {}
    public var body: some View {
        VStack {
            if ApplicationLibrary.inPreview {
                SidebarViewPreview(features: NavigationFeatureProvider.macOSFeatures(for: nil))
            } else if appShell.profiles.isLoading {
                ProgressView()
            } else if let profile = appShell.profiles.profile {
                SidebarView0(features: NavigationFeatureProvider.macOSFeatures(for: profile))
                    .environmentObject(profile)
            } else {
                SidebarView1(features: NavigationFeatureProvider.macOSFeatures(for: nil))
            }
        }
    }

    struct SidebarView0: View {
        @Environment(\.selection) private var selection
        @EnvironmentObject private var extensionProfile: ExtensionProfile
        let features: [NavigationFeature]

        var body: some View {
            let dashboard = features.first { $0.id == NavigationFeatureID.dashboard }
            let connectedFeatures = features.filter { feature in
                guard feature.requiresConnectedProfile else { return false }
                if feature.id == NavigationFeatureID.connections {
                    return Variant.isBeta
                }
                return true
            }
            let regularFeatures = features.filter { !$0.requiresConnectedProfile && $0.id != NavigationFeatureID.dashboard }
            return VStack {
                viewBuilder {
                    List(selection: selection) {
                        if let dashboard {
                            Section(dashboard.title) {
                                dashboard.label.tag(dashboard)
                                ForEach(connectedFeatures, id: \.id) { feature in
                                    feature.label.tag(feature)
                                }
                            }
                        }
                        Divider()
                        ForEach(regularFeatures, id: \.id) { feature in
                            feature.label.tag(feature)
                        }
                    }
                }
                .listStyle(.sidebar)
                .scrollDisabled(true)
            }
            .onChangeCompat(of: extensionProfile.status) {
                if !selection.wrappedValue.isVisible(for: extensionProfile) {
                    selection.wrappedValue = NavigationFeatureProvider.defaultFeature() ?? NavigationFeature.fallback
                }
            }
        }
    }

    struct SidebarView1: View {
        @Environment(\.selection) private var selection
        let features: [NavigationFeature]

        var body: some View {
            List(features, selection: selection) { feature in
                feature.label.tag(feature)
            }
        }
    }

    struct SidebarViewPreview: View {
        @Environment(\.selection) private var selection
        let features: [NavigationFeature]

        var body: some View {
            VStack {
                List(selection: selection) {
                    ForEach(features, id: \.id) { feature in
                        feature.label.tag(feature)
                    }
                }
                .listStyle(.sidebar)
                .scrollDisabled(true)
            }
        }
    }
}
