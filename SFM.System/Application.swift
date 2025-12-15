import ApplicationLibrary
import SwiftUI

@main
struct ChorusBoxApplication: App {
    @NSApplicationDelegateAdaptor(ChorusBoxStandaloneAppDelegate.self) private var appDelegate

    var body: some Scene {
        ChorusBoxApp()
    }
}
