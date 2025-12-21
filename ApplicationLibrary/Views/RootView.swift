import Combine
import SwiftUI
import Library
import Libbox

public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appShell: AppShellState
    private let logger = AppLog.logger(category: "root-view")

    @State private var selection: NavigationFeature = NavigationFeatureProvider.defaultFeature() ?? NavigationFeature.fallback
    @State private var importProfile: LibboxProfileContent?
    @State private var importRemoteProfile: LibboxImportRemoteProfile?
    @State private var alert: Alert?

    public init() {
        logger.debug("init", fields: ["selection": .publicValue(selection.id)])
    }

    public var body: some View {
        #if canImport(ApplicationLibrary)
        if ApplicationLibrary.inPreview {
            body1.preferredColorScheme(.dark)
        } else {
            body1
        }
        #else
        body1
        #endif
    }

    private var body1: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSLikeBody
        #endif
    }

    #if os(macOS)
    @Environment(\.controlActiveState) private var controlActiveState

    private var macOSBody: some View {
        logger.debug("macOSBody building")
        return NavigationSplitView {
            MacSidebarView()
                .navigationSplitViewColumnWidth(150)
        } detail: {
            NavigationStack { selection.contentView.navigationTitle(selection.title) }
                .navigationSplitViewColumnWidth(650)
        }
        .frame(minHeight: 500)
        .onAppear {
            logger.info("macOS body appear", fields: ["selection": .publicValue(selection.id)])
            appShell.refreshProfile()
            ensureSelectionVisible()
            #if canImport(ApplicationLibrary)
            #if !DEBUG
            if Variant.useSystemExtension { Task { checkApplicationPath() } }
            #endif
            #endif
        }
        .alertBinding($alert)
        .toolbar { ToolbarItem(placement: .navigation) { StartStopButton() } }
        .onChangeCompat(of: controlActiveState) { newValue in
            if newValue != .inactive { appShell.refreshProfile() }
        }
        .onReceive(appShell.openSettings) { _ in
            selection = NavigationFeatureProvider.feature(id: NavigationFeatureID.settings) ?? NavigationFeature.fallback
        }
        .environment(\.selection, $selection)
        .environment(\.importProfile, $importProfile)
        .environment(\.importRemoteProfile, $importRemoteProfile)
        .handlesExternalEvents(preferring: [], allowing: ["*"])
        .onOpenURL(perform: openURL)
        .onReceive(appShell.profiles.$error.compactMap { $0 }) { error in
            alert = Alert(error)
            appShell.clearProfileError()
        }
        .onReceive(ChorusBoxErrorReporter.publisher) { event in
            if let error = event.underlyingError {
                alert = Alert(error)
            } else {
                alert = Alert(errorMessage: event.message)
            }
        }
    }

    private struct MacSidebarView: View {
        @Environment(\.selection) private var selection
        @EnvironmentObject private var appShell: AppShellState
        private let logger = AppLog.logger(category: "mac-sidebar")

        var body: some View {
            logger.debug(
                "body building",
                fields: [
                    "selection": .publicValue(selection.wrappedValue.id),
                    "isLoading": .publicValue(appShell.profiles.isLoading.description),
                ]
            )
            return Group {
                if appShell.profiles.isLoading {
                    ProgressView()
                } else {
                    let features = NavigationFeatureProvider.macOSFeatures(for: appShell.profiles.profile)
                    List(features, selection: selection) { feature in
                        feature.label.tag(feature)
                    }
                    .listStyle(.sidebar)
                }
            }
        }
    }

    private func checkApplicationPath() {
        let directoryName = URL(filePath: Bundle.main.bundlePath).deletingLastPathComponent().pathComponents.last
        if directoryName != "Applications" {
            alert = Alert(
                title: Text("Wrong application location"),
                message: Text("This app needs to be placed under the Applications folder to work."),
                dismissButton: .default(Text("Ok")) {
                    NSWorkspace.shared.selectFile(Bundle.main.bundlePath, inFileViewerRootedAtPath: "")
                    NSApp.terminate(nil)
                }
            )
        }
    }
    #endif

    #if !os(macOS)
    private var iOSLikeBody: some View {
        Group {
            if let profile = appShell.profiles.profile {
                tabViewContent(for: profile).environmentObject(profile)
            } else {
                tabViewContent(for: nil)
            }
        }
        .onAppear { appShell.refreshProfile(); ensureSelectionVisible() }
        .alertBinding($alert)
        .onChangeCompat(of: scenePhase) { newValue in if newValue == .active { appShell.refreshProfile() } }
        .onChangeCompat(of: appShell.profiles.profile?.status) { _ in ensureSelectionVisible() }
        .onChangeCompat(of: appShell.profiles.profile == nil) { _ in ensureSelectionVisible() }
        .environment(\.selection, $selection)
        .environment(\.importProfile, $importProfile)
        .environment(\.importRemoteProfile, $importRemoteProfile)
        .handlesExternalEvents(preferring: [], allowing: ["*"])
        .onOpenURL(perform: openURL)
        .onReceive(appShell.profiles.$error.compactMap { $0 }) { error in
            alert = Alert(error)
            appShell.clearProfileError()
        }
        .onReceive(ChorusBoxErrorReporter.publisher) { event in
            if let error = event.underlyingError {
                alert = Alert(error)
            } else {
                alert = Alert(errorMessage: event.message)
            }
        }
    }
#endif

    private func availableFeatures(for profile: ExtensionProfile?) -> [NavigationFeature] {
        NavigationFeatureProvider.availableFeatures(for: profile)
    }

    private func ensureSelectionVisible() {
        if !availableFeatures(for: appShell.profiles.profile).contains(selection) {
            selection = NavigationFeatureProvider.defaultFeature() ?? NavigationFeature.fallback
        }
    }

    private func tabViewContent(for profile: ExtensionProfile?) -> some View {
        let features = availableFeatures(for: profile)
        return TabView(selection: $selection) {
            ForEach(features, id: \.id) { feature in
                NavigationStackCompat {
                    feature.contentView
                    #if os(iOS)
                        .navigationTitle(feature.title)
                    #endif
                    #if os(tvOS)
                        .focusSection()
                    #endif
                }
                .tag(feature)
                .tabItem { feature.label }
            }
        }
    }

    private func openURL(url: URL) {
        Task { await handleIncomingURL(url) }
    }

    @MainActor
    private func handleIncomingURL(_ url: URL) async {
        let result = await ProfileImportCoordinator.handleIncomingURL(url)
        if let error = result.error {
            alert = Alert(error)
            return
        }
        if let profileContent = result.profileContent {
            importProfile = profileContent
        }
        if let remoteProfile = result.remoteProfile {
            importRemoteProfile = remoteProfile
        }
        if (result.profileContent != nil || result.remoteProfile != nil),
           selection.id != NavigationFeatureID.profiles {
            selection = NavigationFeatureProvider.feature(id: NavigationFeatureID.profiles) ?? NavigationFeature.fallback
        }
        if let message = result.message, !message.isEmpty {
            alert = Alert(errorMessage: message)
        }
    }
}

#if DEBUG
#if os(macOS)
#Preview("macOS – Empty Profile") {
    RootView()
        .environment(\.showMenuBarExtra, .constant(false))
        .environmentObject(AppShellState(profiles: ProfileStore(loader: { nil })))
        .frame(width: 900, height: 600)
}
#else
#Preview("iOS – Empty Profile") {
    RootView()
        .environmentObject(AppShellState(profiles: ProfileStore(loader: { nil })))
}
#endif
#endif
