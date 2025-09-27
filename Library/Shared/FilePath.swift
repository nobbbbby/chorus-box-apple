import Foundation

public enum FilePath {
    public static let packageName = "io.nobby.chorus.box"

    public enum Error: Swift.Error, LocalizedError {
        case missingAppGroup
        case directoryCreationFailed(URL, Swift.Error)

        public var errorDescription: String? {
            switch self {
            case .missingAppGroup:
                return "Shared container is unavailable. Check App Group entitlements."
            case let .directoryCreationFailed(url, underlying):
                return "Unable to create directory at \(url.path): \(underlying.localizedDescription)"
            }
        }
    }

    public struct ContainerPaths {
        public let shared: URL
        public let cache: URL
        public let working: URL
    }

    public static let groupName = "group.\(packageName)"
    private static let lock = NSLock()
    private static var cachedPaths: ContainerPaths?
    private static var manualPaths: ContainerPaths?
    private static var manualICloudDirectory: URL?

    public static func containerPaths() throws -> ContainerPaths {
        lock.lock()
        defer { lock.unlock() }
        if let manualPaths {
            cachedPaths = manualPaths
            return manualPaths
        }
        if let cachedPaths {
            return cachedPaths
        }
        let paths = try resolveContainerPaths()
        cachedPaths = paths
        return paths
    }

    public static func containerPathsOrFallback() -> ContainerPaths {
        do {
            return try containerPaths()
        } catch {
            NSLog("[FilePath] Falling back to documents directory: \(error.localizedDescription)")
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let cache = documents.appendingPathComponent("Cache", isDirectory: true)
            let working = cache.appendingPathComponent("Working", isDirectory: true)
            try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
            try? FileManager.default.createDirectory(at: working, withIntermediateDirectories: true)
            return ContainerPaths(shared: documents, cache: cache, working: working)
        }
    }

    public static var sharedDirectory: URL {
        containerPathsOrFallback().shared
    }

    public static var cacheDirectory: URL {
        containerPathsOrFallback().cache
    }

    public static var workingDirectory: URL {
        containerPathsOrFallback().working
    }

    public static var iCloudDirectory: URL {
        if let manualICloudDirectory {
            return manualICloudDirectory
        }
        if let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents", isDirectory: true) {
            return url
        }
        return sharedDirectory.appendingPathComponent("iCloud", isDirectory: true)
    }

    public static func override(containerPaths paths: ContainerPaths) {
        lock.lock()
        manualPaths = paths
        cachedPaths = paths
        lock.unlock()
    }

    public static func overrideICloudDirectory(_ url: URL) {
        lock.lock()
        manualICloudDirectory = url
        lock.unlock()
    }

    private static func resolveContainerPaths() throws -> ContainerPaths {
        let fileManager = FileManager.default
        guard let base = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupName) else {
            throw Error.missingAppGroup
        }

        #if os(iOS)
            let shared = base
            let cache = shared.appendingPathComponent("Library", isDirectory: true).appendingPathComponent("Caches", isDirectory: true)
        #elseif os(tvOS)
            let shared = base
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Caches", isDirectory: true)
            let cache = shared
        #elseif os(macOS)
            let shared = base
            let cache = shared
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Caches", isDirectory: true)
        #endif

        #if os(macOS)
            let working = cache.appendingPathComponent("Working", isDirectory: true)
        #else
            let working = cache.appendingPathComponent("Working", isDirectory: true)
        #endif

        try createDirectoryIfNeeded(at: shared)
        try createDirectoryIfNeeded(at: cache)
        try createDirectoryIfNeeded(at: working)

        return ContainerPaths(shared: shared, cache: cache, working: working)
    }

    private static func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw Error.directoryCreationFailed(url, error)
        }
    }
}

public extension URL {
    var fileName: String {
        var path = relativePath
        if let index = path.lastIndex(of: "/") {
            path = String(path[path.index(index, offsetBy: 1)...])
        }
        return path
    }
}
