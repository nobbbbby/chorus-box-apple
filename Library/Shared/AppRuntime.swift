import Foundation
import Libbox

public enum LibboxBootstrapper {
    public static func bootstrap(isTVOS: Bool) {
        NSLog("[AppRuntime] bootstrap begin isTVOS=\(isTVOS)")
        let options = LibboxSetupOptions()
        options.basePath = FilePath.sharedDirectory.relativePath
        options.workingPath = FilePath.workingDirectory.relativePath
        options.tempPath = FilePath.cacheDirectory.relativePath
        #if os(tvOS)
            if isTVOS { options.isTVOS = true }
        #endif
        var error: NSError?
        LibboxSetup(options, &error)
        LibboxSetLocale(Locale.current.identifier)
        if let error {
            NSLog("[AppRuntime] bootstrap finished with error: \(error.localizedDescription)")
        } else {
            NSLog("[AppRuntime] bootstrap finished successfully")
        }
    }
}

public struct AppRuntime {
    public struct Options {
        public enum ConfigurationMode {
            case configure
            case configureIfNeeded
        }

        public var configurationMode: ConfigurationMode
        public var isTVOS: Bool

        public init(configurationMode: ConfigurationMode = .configureIfNeeded, isTVOS: Bool = false) {
            self.configurationMode = configurationMode
            self.isTVOS = isTVOS
        }
    }

    private let configurationBuilder: () -> ChorusBoxConfiguration
    private let options: Options

    public init(configuration: @escaping () -> ChorusBoxConfiguration, options: Options = .init()) {
        configurationBuilder = configuration
        self.options = options
    }

    public func start() {
        NSLog("[AppRuntime] start begin mode=\(options.configurationMode)")
        switch options.configurationMode {
        case .configure:
            ChorusBoxConfiguration.configure(configurationBuilder())
        case .configureIfNeeded:
            _ = ChorusBoxConfiguration.configureIfNeeded(configurationBuilder)
        }
        LibboxBootstrapper.bootstrap(isTVOS: options.isTVOS)
        NSLog("[AppRuntime] start finished")
    }

    public func commandClient(
        _ type: CommandClient.ConnectionType,
        logMaxLines: Int = 300
    ) -> CommandClient {
        CommandClient(type, logMaxLines: logMaxLines)
    }

    public func logClient(maxLines: Int = 300) -> CommandClient {
        commandClient(.log, logMaxLines: maxLines)
    }

    public var sharedDirectory: URL {
        FilePath.sharedDirectory
    }

    public var cacheDirectory: URL {
        FilePath.cacheDirectory
    }

    public var workingDirectory: URL {
        FilePath.workingDirectory
    }
}
