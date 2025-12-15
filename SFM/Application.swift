import ApplicationLibrary
import SwiftUI

@main
struct ChorusBoxApplication: App {
    @NSApplicationDelegateAdaptor(ChorusBoxMacAppDelegate.self) private var appDelegate

    init() {
        NSLog("[ChorusBoxApplication] constructing ChorusBoxApp scene")
    }

    var body: some Scene {
        ChorusBoxApp()
    }
}
