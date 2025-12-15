import Foundation
import Libbox

public enum ProfileImportCoordinator {
    public struct Result {
        public let profileContent: LibboxProfileContent?
        public let remoteProfile: LibboxImportRemoteProfile?
        public let error: Error?
        public let message: String?

        public init(
            profileContent: LibboxProfileContent? = nil,
            remoteProfile: LibboxImportRemoteProfile? = nil,
            error: Error? = nil,
            message: String? = nil
        ) {
            self.profileContent = profileContent
            self.remoteProfile = remoteProfile
            self.error = error
            self.message = message
        }

        public static let ignored = Result(message: nil)
    }

    public static func handleIncomingURL(_ url: URL) async -> Result {
        if url.host == "import-remote-profile" {
            return handleRemoteImport(url: url)
        }
        if url.pathExtension.lowercased() == "bpf" {
            return await handleLocalImport(url: url)
        }
        let message = String(localized: "Handled unknown URL \(url.absoluteString)")
        return Result(message: message)
    }

    private static func handleRemoteImport(url: URL) -> Result {
        var error: NSError?
        let remoteProfile = LibboxParseRemoteProfileImportLink(url.absoluteString, &error)
        if let error {
            return Result(error: error)
        }
        guard let remoteProfile else {
            return Result(message: String(localized: "Failed to import profile from URL"))
        }
        return Result(remoteProfile: remoteProfile)
    }

    private static func handleLocalImport(url: URL) async -> Result {
        do {
            let data = try await loadData(from: url)
            let profile = try LibboxProfileContent.from(data)
            return Result(profileContent: profile)
        } catch {
            return Result(error: error)
        }
    }

    private static func loadData(from url: URL) async throws -> Data {
        #if os(macOS) || os(iOS)
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        #endif
        return try Data(contentsOf: url)
    }
}
