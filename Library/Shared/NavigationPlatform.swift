import Foundation

public enum NavigationPlatform: CaseIterable {
    case iOS
    case macOS
    case tvOS

    public static var current: NavigationPlatform {
        #if os(macOS)
            return .macOS
        #elseif os(tvOS)
            return .tvOS
        #else
            return .iOS
        #endif
    }
}
