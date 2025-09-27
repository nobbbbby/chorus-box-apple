import Combine
import SwiftUI
import Library
import Libbox
#if os(macOS)
#if canImport(MacLibrary)
import MacLibrary
#endif
#endif

public struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var environments: ExtensionEnvironments

    @State private var selection = NavigationPage.dashboard
    @State private var importProfile: LibboxProfileContent?
    @State private var importRemoteProfile: LibboxImportRemoteProfile?
    @State private var alert: Alert?

    public init() {}

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
        NavigationSplitView {
            SidebarView().navigationSplitViewColumnWidth(150)
        } detail: {
            NavigationStack { selection.contentView.navigationTitle(selection.title) }
                .navigationSplitViewColumnWidth(650)
        }
        .frame(minHeight: 500)
        .onAppear {
            environments.postReload()
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
            if newValue != .inactive { environments.postReload() }
        }
        .onChangeCompat(of: selection) { value in
            if value == .logs { environments.connectLog() }
        }
        .onReceive(environments.openSettings) { _ in selection = .settings }
        .environment(\.selection, $selection)
        .environment(\.importProfile, $importProfile)
        .environment(\.importRemoteProfile, $importRemoteProfile)
        .handlesExternalEvents(preferring: [], allowing: ["*"])
        .onOpenURL(perform: openURL)
        .onReceive(environments.$profileLoadError.compactMap { $0 }) { error in
            alert = Alert(error)
            environments.profileLoadError = nil
        }
        .onReceive(ChorusBoxErrorReporter.publisher) { event in
            if let error = event.underlyingError {
                alert = Alert(error)
            } else {
                alert = Alert(errorMessage: event.message)
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
            if let profile = environments.extensionProfile {
                tabViewContent(for: profile).environmentObject(profile)
            } else {
                tabViewContent(for: nil)
            }
        }
        .onAppear { environments.postReload(); ensureSelectionVisible() }
        .alertBinding($alert)
        .onChangeCompat(of: scenePhase) { newValue in if newValue == .active { environments.postReload() } }
        .onChangeCompat(of: environments.extensionProfile?.status) { _ in ensureSelectionVisible() }
        .onChangeCompat(of: environments.extensionProfile == nil) { _ in ensureSelectionVisible() }
        .onChangeCompat(of: selection) { newValue in if newValue == .logs { environments.connectLog() } }
        .environment(\.selection, $selection)
        .environment(\.importProfile, $importProfile)
        .environment(\.importRemoteProfile, $importRemoteProfile)
        .handlesExternalEvents(preferring: [], allowing: ["*"])
        .onOpenURL(perform: openURL)
        .onReceive(environments.$profileLoadError.compactMap { $0 }) { error in
            alert = Alert(error)
            environments.profileLoadError = nil
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

    private func availablePages(for profile: ExtensionProfile?) -> [NavigationPage] {
        NavigationPage.pagesForCurrentPlatform().filter { page in
            page.visible(profile)
        }
    }

    private func ensureSelectionVisible() {
        if !availablePages(for: environments.extensionProfile).contains(selection) {
            selection = .dashboard
        }
    }

    private func tabViewContent(for profile: ExtensionProfile?) -> some View {
        TabView(selection: $selection) {
            ForEach(availablePages(for: profile), id: \.self) { page in
                NavigationStackCompat {
                    page.contentView
                    #if os(iOS)
                        .navigationTitle(page.title)
                    #endif
                    #if os(tvOS)
                        .focusSection()
                    #endif
                }
                .tag(page)
                .tabItem { page.label }
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
        if (result.profileContent != nil || result.remoteProfile != nil), selection != .profiles {
            selection = .profiles
        }
        if let message = result.message, !message.isEmpty {
            alert = Alert(errorMessage: message)
        }
    }
}
