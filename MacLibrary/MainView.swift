import ApplicationLibrary
import Libbox
import Library
import SwiftUI
import Combine

@MainActor
public struct MainView: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @EnvironmentObject private var environments: ExtensionEnvironments

    @State private var selection = NavigationPage.dashboard
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
            environments.postReload()
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
                environments.postReload()
            }
        }
        .onChangeCompat(of: selection) { value in
            if value == .logs {
                environments.connectLog()
            }
        }
        .onReceive(environments.openSettings) {
            selection = .settings
        }
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
    MainView().environmentObject(ExtensionEnvironments())
}

    
