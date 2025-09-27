import Combine
import Foundation
import SwiftUI

public class ExtensionEnvironments: ObservableObject {
    @Published public var logClient = CommandClient(.log)
    @Published public var extensionProfileLoading = true
    @Published public var extensionProfile: ExtensionProfile?
    @Published public var emptyProfiles = false
    @Published public var profileLoadError: Error?

    public let profileUpdate = PassthroughSubject<Void, Never>()
    public let selectedProfileUpdate = PassthroughSubject<Void, Never>()
    public let openSettings = PassthroughSubject<Void, Never>()

    public init() {}

    deinit {
        logClient.disconnect()
    }

    public func postReload() {
        Task {
            await reload()
        }
    }

    @MainActor
    public func reload() async {
        extensionProfileLoading = true
        profileLoadError = nil
        do {
            let profile = try await ExtensionProfile.load()
            extensionProfileLoading = false
            emptyProfiles = profile == nil
            guard let profile else {
                if extensionProfile != nil {
                    extensionProfile = nil
                    logClient.disconnect()
                }
                return
            }
            if extensionProfile !== profile {
                profile.register()
                extensionProfile = profile
            } else {
                extensionProfile?.objectWillChange.send()
            }
        } catch {
            extensionProfileLoading = false
            profileLoadError = error
            emptyProfiles = true
            extensionProfile = nil
            logClient.disconnect()
        }
    }

    public func connectLog() {
        guard let profile = extensionProfile else {
            return
        }
        if profile.status.isConnected, !logClient.isConnected {
            logClient.connect()
        }
    }
}
