import Libbox
import Library
import NetworkExtension
import System

class PacketTunnelProvider: ExtensionProvider {
    override func startTunnel(options: [String: NSObject]?) async throws {
        guard let usernameObject = options?["username"] else {
            writeFatalError("missing start options")
            return
        }
        let username = usernameObject as! NSString
        let sharedDirectory = URL(filePath: "/Users/\(username)/Library/Group Containers/\(FilePath.groupName)")
        let cacheDirectory = sharedDirectory
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Caches", isDirectory: true)
        let workingDirectory = cacheDirectory.appendingPathComponent("Working", isDirectory: true)
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
        } catch {
            NSLog("Failed to prepare container directories: \(error.localizedDescription)")
        }
        FilePath.override(containerPaths: .init(shared: sharedDirectory, cache: cacheDirectory, working: workingDirectory))
        let iCloudRoot = URL(filePath: "/Users/\(username)/Library/Mobile Documents/iCloud~\(FilePath.packageName.replacingOccurrences(of: ".", with: "~"))")
        FilePath.overrideICloudDirectory(iCloudRoot.appendingPathComponent("Documents", isDirectory: true))
        let databasePath = FilePath.sharedDirectory.appendingPathComponent("settings.db").relativePath
        if !FileManager.default.isReadableFile(atPath: databasePath) {
            do {
                let fd = try FileDescriptor.open(databasePath, .readOnly)
                try! fd.close()
                NSLog("Can access \(databasePath)")
            } catch {
                NSLog("Can't access \(databasePath): \(error.localizedDescription)")
            }
            try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 100)
            throw FullDiskAccessPermissionRequired.error
        }

        self.username = String(username)
        try await super.startTunnel(options: options)
    }
}
