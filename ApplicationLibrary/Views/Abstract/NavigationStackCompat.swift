import SwiftUI

@ViewBuilder
public func NavigationStackCompat(@ViewBuilder content: () -> some View) -> some View {
    if #available(iOS 17.0, macOS 14.0, tvOS 17.0, *) {
        NavigationStack { content() }
    } else if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
        NavigationStack { content() }
    } else {
        NavigationView(content: content)
            #if !os(macOS)
                .navigationViewStyle(.stack)
            #endif
    }
}
