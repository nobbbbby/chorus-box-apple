import SwiftUI

public extension View {
    @ViewBuilder
    func onChangeCompat(of value: some Equatable, _ action: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            onChange(of: value, initial: false) { _, _ in action() }
        } else {
            onChange(of: value) { _ in action() }
        }
    }

    @ViewBuilder
    func onChangeCompat<V>(of value: V, _ action: @escaping (_ newValue: V) -> Void) -> some View where V: Equatable {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            onChange(of: value, initial: false) { _, newValue in action(newValue) }
        } else {
            onChange(of: value, perform: action)
        }
    }
}
