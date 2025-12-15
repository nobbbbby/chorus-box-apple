import Combine
import Foundation
import NetworkExtension

@MainActor
public final class LogStreamStore: ObservableObject {
    public let client: CommandClient

    private var statusCancellable: AnyCancellable?

    public init(client: CommandClient = CommandClient(.log)) {
        self.client = client
    }

    deinit {
        statusCancellable?.cancel()
        client.disconnect()
    }

    public func handleProfileChange(_ profile: ExtensionProfile?) {
        statusCancellable?.cancel()
        guard let profile else {
            client.disconnect()
            return
        }
        statusCancellable = profile.$status
            .removeDuplicates()
            .sink { [weak self] status in
                self?.updateConnection(for: status)
            }
        updateConnection(for: profile.status)
    }

    private func updateConnection(for status: NEVPNStatus) {
        if status.isConnectedStrict {
            if !client.isConnected {
                client.connect()
            }
        } else if client.isConnected {
            client.disconnect()
        }
    }
}
