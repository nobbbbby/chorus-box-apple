import ApplicationLibrary
import Libbox
import Library
import ApplicationLibrary
import SwiftUI
import Combine

@MainActor
public struct MainView: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @EnvironmentObject private var appShell: AppShellState

    @State private var selection: NavigationFeature = NavigationFeatureProvider.defaultFeature() ?? NavigationFeature.fallback
    @State private var importProfile: LibboxProfileContent?
    @State private var importRemoteProfile: LibboxImportRemoteProfile?
    @State private var alert: Alert?

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(150)
        } detail: {
            NavigationStack {
                selection.contentView
                    .navigationTitle(selection.title)
            }
            .navigationSplitViewColumnWidth(650)
        }
        .frame(minHeight: 500)
        .onAppear {
            appShell.refreshProfile()
            #if !DEBUG
                if Variant.useSystemExtension {
                    Task {
                        checkApplicationPath()
                    }
                }
            #endif
        }
        .alertBinding($alert)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                StartStopButton()
            }
        }
        .onChangeCompat(of: controlActiveState) { newValue in
            if newValue != .inactive {
                appShell.refreshProfile()
            }
        }
        .onReceive(appShell.openSettings) {
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
}


#Preview {
    MainView().environmentObject(AppShellState())
}

    
