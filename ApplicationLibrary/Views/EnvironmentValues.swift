import Foundation
import Libbox
import Library
import SwiftUI

public extension EnvironmentValues {
    private struct showMenuBarExtraKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(true)
    }

    var showMenuBarExtra: Binding<Bool> {
        get {
            self[showMenuBarExtraKey.self]
        }
        set {
            self[showMenuBarExtraKey.self] = newValue
        }
    }

    private struct selectionKey: EnvironmentKey {
        @MainActor
        static var defaultValue: Binding<NavigationFeature> {
            .constant(NavigationFeatureProvider.defaultFeature() ?? NavigationFeature.fallback)
        }
    }

    var selection: Binding<NavigationFeature> {
        get {
            self[selectionKey.self]
        }
        set {
            self[selectionKey.self] = newValue
        }
    }

    private struct importRemoteProfileKey: EnvironmentKey {
        static var defaultValue: Binding<LibboxImportRemoteProfile?> = .constant(nil)
    }

    var importRemoteProfile: Binding<LibboxImportRemoteProfile?> {
        get {
            self[importRemoteProfileKey.self]
        }
        set {
            self[importRemoteProfileKey.self] = newValue
        }
    }

    private struct importProfileKey: EnvironmentKey {
        static var defaultValue: Binding<LibboxProfileContent?> = .constant(nil)
    }

    var importProfile: Binding<LibboxProfileContent?> {
        get {
            self[importProfileKey.self]
        }
        set {
            self[importProfileKey.self] = newValue
        }
    }
}
