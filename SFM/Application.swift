import ApplicationLibrary
import SwiftUI

@main
struct ChorusBoxApplication: App {
    @NSApplicationDelegateAdaptor(ChorusBoxMacAppDelegate.self) private var appDelegate

    var body: some Scene {
        ChorusBoxApp()
    }
}
