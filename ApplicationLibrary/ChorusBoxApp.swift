import SwiftUI
import Library
import OSLog
#if os(macOS)
import AppKit
#endif

public struct ChorusBoxApp: Scene {
    private let logger = AppLog.logger(category: "app-scene")

    public init() {
        logger.info("init start (bootstrap deferred)")
    }

    #if !os(macOS)
    @StateObject private var appShell = AppShellState()
    #endif

    public var body: some Scene {
        #if os(macOS)
        MacScenes()
        #else
        WindowGroup { RootView().environmentObject(appShell) }
        #endif
    }
}

#if os(macOS)
    private struct MacScenes: Scene {
    @State private var showMenuBarExtra = false
    @State private var isMenuPresented = false
    @StateObject private var appShell = AppShellState()
    private let logger = AppLog.logger(category: "app-mac-scenes")

        init() {
            logger.info("init")
        }

        var body: some Scene {
            logger.debug("body evaluated")
            return Window("Chorus Box", id: "main") {
                RootView()
                    .onAppear {
                        logger.info("main window appear")
                        Task { await initialize() }
                    }
                    .environment(\.showMenuBarExtra, $showMenuBarExtra)
                    .environmentObject(appShell)
            }
            .windowResizability(.contentSize)
            .commands {
                if showMenuBarExtra {
                    CommandGroup(replacing: .appTermination) {
                        Button("Quit Chorus Box") { hide(closeApp: true) }
                            .keyboardShortcut("q", modifiers: [.command])
                    }
                    CommandGroup(replacing: .saveItem) {
                        Button("Close") { hide(closeApp: false) }
                            .keyboardShortcut("w", modifiers: [.command])
                    }
                }
                SidebarCommands()
                CommandGroup(replacing: .appSettings) {
                    Button("Settings") { appShell.openSettings.send(()) }
                        .keyboardShortcut(",", modifiers: [.command])
                }
            }

            MenuBarExtra(isInserted: $showMenuBarExtra) {
                EmptyView()
            } label: { Image("MenuIcon") }
            .menuBarExtraStyle(.window)
        }

    private func initialize() async {
        showMenuBarExtra = await SharedPreferences.showMenuBarExtra.get()
    }

    private func hide(closeApp: Bool) {
        Task {
            if await SharedPreferences.menuBarExtraInBackground.get() {
                hide0(closeApp: closeApp)
            } else {
                if closeApp { NSApp.terminate(nil) } else { NSApp.keyWindow?.close() }
            }
        }
    }

    private func hide0(closeApp: Bool) {
        if closeApp || NSApp.keyWindow?.identifier?.rawValue == "main" {
            let transformState = ProcessApplicationTransformState(kProcessTransformToUIElementApplication)
            var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
            TransformProcessType(&psn, transformState)
            NSApp.setActivationPolicy(.accessory)
        }
        NSApp.keyWindow?.close()
    }
}
#endif
