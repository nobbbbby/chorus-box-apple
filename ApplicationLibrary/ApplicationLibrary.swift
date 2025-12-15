import Foundation

public class ApplicationLibrary {
    public static let bundle = Bundle(for: ApplicationLibrary.self)
    public static var inPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

// MARK: - Bootstrap & Notifications shared from ApplicationLibrary framework

import Libbox
import Library
#if !os(tvOS)
import UserNotifications
#endif

#if !os(tvOS)
public enum NotificationHelper {
    public static func configureOpenURLCategory(delegate: UNUserNotificationCenterDelegate) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([
            UNNotificationCategory(
                identifier: "OPEN_URL",
                actions: [
                    UNNotificationAction(identifier: "COPY_URL", title: "Copy URL", options: .foreground, icon: UNNotificationActionIcon(systemImageName: "clipboard.fill")),
                    UNNotificationAction(identifier: "OPEN_URL", title: "Open", options: .foreground, icon: UNNotificationActionIcon(systemImageName: "safari.fill")),
                ],
                intentIdentifiers: []
            ),
        ])
        notificationCenter.delegate = delegate
    }
}
#endif

// MARK: - Platform App Delegates

#if canImport(UIKit)
import UIKit
#if !os(tvOS)
import UserNotifications
#endif

@MainActor
public final class ChorusBoxMobileAppDelegate: NSObject, UIApplicationDelegate {
    #if !os(tvOS)
    private var profileServer: ProfileServer?
    #endif
    private let runtime = AppRuntime(
        configuration: {
            #if os(tvOS)
                return ChorusBoxConfiguration(
                    platform: .tvOS,
                    applicationName: "SFT",
                    usesSystemExtension: false,
                    isBeta: LibboxVersion().contains("-")
                )
            #else
                return ChorusBoxConfiguration(
                    platform: .iOS,
                    applicationName: "SFI",
                    usesSystemExtension: false,
                    isBeta: LibboxVersion().contains("-")
                )
            #endif
        },
        options: ChorusBoxMobileAppDelegate.runtimeOptions
    )

    private static let runtimeOptions: AppRuntime.Options = {
        #if os(tvOS)
            AppRuntime.Options(isTVOS: true)
        #else
            AppRuntime.Options()
        #endif
    }()

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        runtime.start()
        NSLog("Here I stand")
        #if !os(tvOS)
        NotificationHelper.configureOpenURLCategory(delegate: application.notificationCenterDelegate)
        #endif
        setup()
        return true
    }

    private func setup() {
        do {
            try UIProfileUpdateTask.configure()
            NSLog("setup background task success")
        } catch {
            NSLog("setup background task error: \(error.localizedDescription)")
            ChorusBoxErrorReporter.report(message: "Background task setup failed", error: error)
        }
        #if !os(tvOS)
        Task {
            if UIDevice.current.userInterfaceIdiom == .phone {
                await requestNetworkPermission()
            }
            await setupBackground()
        }
        #endif
    }

    #if !os(tvOS)
    @MainActor
    private func setupBackground() async {
        if #available(iOS 16.0, *) {
            do {
                let profileServer = try ProfileServer()
                profileServer.start()
                self.profileServer?.cancel()
                self.profileServer = profileServer
                NSLog("started profile server")
            } catch {
                NSLog("setup profile server error: \(error.localizedDescription)")
                ChorusBoxErrorReporter.report(message: "Unable to start profile sharing server", error: error)
            }
        }
    }

    private func requestNetworkPermission() async {
        if await SharedPreferences.networkPermissionRequested.get() {
            return
        }
        if !DeviceCensorship.isChinaDevice() {
            await SharedPreferences.networkPermissionRequested.set(true)
            return
        }
        let request = URLRequest(url: URL(string: "http://captive.apple.com")!)
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                ChorusBoxErrorReporter.report(message: "Network permission verification failed", error: error)
                return
            }
            guard let response = response as? HTTPURLResponse else {
                ChorusBoxErrorReporter.report(message: "Network permission verification returned an unexpected response")
                return
            }
            guard response.statusCode == 200 else {
                ChorusBoxErrorReporter.report(message: "Network permission verification failed with status \(response.statusCode)")
                return
            }
            Task { await SharedPreferences.networkPermissionRequested.set(true) }
        }.resume()
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        profileServer?.cancel()
        profileServer = nil
    }
    #endif

}

private extension UIApplication {
    #if !os(tvOS)
    var notificationCenterDelegate: UNUserNotificationCenterDelegate {
        ChorusBoxNotificationDelegate.shared
    }
    #endif
}

#if !os(tvOS)
private final class ChorusBoxNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ChorusBoxNotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        .banner
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let url = response.notification.request.content.userInfo["OPEN_URL"] as? String else {
            return
        }
        switch response.actionIdentifier {
        case "COPY_URL":
            UIPasteboard.general.string = url
        case "OPEN_URL":
            fallthrough
        default:
            guard let target = URL(string: url) else {
                return
            }
            await UIApplication.shared.open(target)
        }
    }
}
#endif
#endif

#if os(macOS)
import AppKit
import UserNotifications

    open class ChorusBoxMacAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
        private lazy var runtime: AppRuntime = {
            AppRuntime(
                configuration: { [unowned self] in
                    runtimeConfiguration()
            },
            options: runtimeOptions()
        )
    }()

    public override init() {
        NSLog("[ChorusBoxMacAppDelegate] init")
        super.init()
    }

    public func applicationWillFinishLaunching(_ notification: Notification) {
        NSLog("[ChorusBoxMacAppDelegate] willFinishLaunching")
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[ChorusBoxMacAppDelegate] didFinishLaunching start")
        let runtimeInstance = runtime
        Task.detached(priority: .userInitiated) {
            let start = Date()
            NSLog("[ChorusBoxMacAppDelegate] runtime.start begin")
            runtimeInstance.start()
            let elapsed = Date().timeIntervalSince(start)
            NSLog("[ChorusBoxMacAppDelegate] runtime.start finished in \(String(format: "%.2f", elapsed))s")
        }
        NotificationHelper.configureOpenURLCategory(delegate: self)
        Task { await adjustActivationPolicy() }
        Task {
            do {
                try await ProfileUpdateTask.configure()
                try await handleLoginItemLaunch()
            } catch {
                NSLog("application setup error: \(error.localizedDescription)")
                ChorusBoxErrorReporter.report(message: "Application setup failed", error: error)
            }
        }
    }

    open func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        SharedPreferences.inDebug || !SharedPreferences.menuBarExtraInBackground.getBlocking()
    }

    open func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, NSApp.activationPolicy() == .accessory {
            NSApp.setActivationPolicy(.regular)
            NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.activate()
        }
        return true
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        .banner
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let url = response.notification.request.content.userInfo["OPEN_URL"] as? String else {
            return
        }
        switch response.actionIdentifier {
        case "COPY_URL":
            NSPasteboard.general.setString(url, forType: .URL)
        case "OPEN_URL":
            fallthrough
        default:
            guard let target = URL(string: url) else {
                return
            }
            NSWorkspace.shared.open(target)
        }
    }

    open func runtimeConfiguration() -> ChorusBoxConfiguration {
        ChorusBoxConfiguration(
            platform: .macOS,
            applicationName: "SFM",
            usesSystemExtension: false,
            isBeta: LibboxVersion().contains("-")
        )
    }

    open func runtimeOptions() -> AppRuntime.Options {
        AppRuntime.Options()
    }

    @MainActor
    private func adjustActivationPolicy() async {
        let event = NSAppleEventManager.shared().currentAppleEvent
        let launchedAsLogInItem =
            event?.eventID == kAEOpenApplication &&
            event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        let showMenuBarExtra = await SharedPreferences.showMenuBarExtra.get()
        let menuBarInBackground = await SharedPreferences.menuBarExtraInBackground.get()
        NSLog("[ChorusBoxMacAppDelegate] adjustActivationPolicy launchedAsLoginItem=\(launchedAsLogInItem) showMenuBarExtra=\(showMenuBarExtra) menuBarInBackground=\(menuBarInBackground)")
        // Force a visible app window to avoid macOS hiding the process and causing user confusion.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSLog("[ChorusBoxMacAppDelegate] activationPolicy set to regular and app activated")
    }

    @MainActor
    private func handleLoginItemLaunch() async throws {
        let event = NSAppleEventManager.shared().currentAppleEvent
        let launchedAsLogInItem =
            event?.eventID == kAEOpenApplication &&
            event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        guard launchedAsLogInItem else { return }
        NSLog("[ChorusBoxMacAppDelegate] handleLoginItemLaunch triggered")
        if await SharedPreferences.startedByUser.get() {
            if let profile = try await ExtensionProfile.load() {
                try await profile.start()
                NSLog("[ChorusBoxMacAppDelegate] login item profile started")
            }
        }
    }
}

public final class ChorusBoxStandaloneAppDelegate: ChorusBoxMacAppDelegate {
    public override func applicationWillFinishLaunching(_ notification: Notification) {
        super.applicationWillFinishLaunching(notification)
        Task { await setupSystemExtension() }
    }

    public override func runtimeConfiguration() -> ChorusBoxConfiguration {
        ChorusBoxConfiguration(
            platform: .macOS,
            applicationName: "SFM",
            usesSystemExtension: true,
            isBeta: false
        )
    }

    public override func runtimeOptions() -> AppRuntime.Options {
        AppRuntime.Options(configurationMode: .configure)
    }

    private func setupSystemExtension() async {
        do {
            if await SystemExtension.isInstalled() {
                if let result = try await SystemExtension.install(), result == .willCompleteAfterReboot {
                    return
                }
            }
        } catch {
            NSLog("setup system extension error: \(error.localizedDescription)")
            ChorusBoxErrorReporter.report(message: "System extension installation failed", error: error)
        }
    }
}
#endif
