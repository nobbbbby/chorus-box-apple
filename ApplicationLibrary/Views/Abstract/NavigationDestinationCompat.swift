import SwiftUI

func NavigationDestinationCompat(isPresented: Binding<Bool>, @ViewBuilder destination: () -> some View) -> some View {
    // For modern stacks, NavigationStack + navigationDestination(isPresented:) is preferred.
    NavigationLink(value: true) {
        EmptyView()
    }
    .navigationDestination(isPresented: isPresented) {
        destination()
    }
}
