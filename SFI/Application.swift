import ApplicationLibrary
import SwiftUI

@main
struct ChorusBoxApplication: App {
    @UIApplicationDelegateAdaptor(ChorusBoxMobileAppDelegate.self) private var appDelegate

    var body: some Scene {
        ChorusBoxApp()
    }
}
