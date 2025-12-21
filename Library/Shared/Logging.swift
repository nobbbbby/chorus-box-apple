import Foundation
import OSLog

public enum LogLevel {
    case debug
    case info
    case warn
    case error
}

public enum LogFieldValue {
    case publicValue(String)
    case privateValue(String)

    var rendered: String {
        switch self {
        case let .publicValue(value):
            return value
        case .privateValue:
            return "<redacted>"
        }
    }
}

public enum LogConfiguration {
    /// Toggle to allow debug logging in release builds when needed.
    public static var enableDebugLoggingInRelease = false

    static var shouldEmitDebug: Bool {
        #if DEBUG
            true
        #else
            enableDebugLoggingInRelease || ProcessInfo.processInfo.environment["CHORUSBOX_DEBUG_LOGS"] == "1"
        #endif
    }
}

public struct AppLog {
    public static let subsystem = "io.nobby.chorus.box"

    public static func logger(category: String, correlationID: String? = nil) -> StructuredLogger {
        StructuredLogger(
            logger: Logger(subsystem: subsystem, category: category),
            correlationID: correlationID
        )
    }
}

public struct StructuredLogger {
    private let logger: Logger
    private let correlationID: String?
    private let buildInfo = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    public init(logger: Logger, correlationID: String? = nil) {
        self.logger = logger
        self.correlationID = correlationID
    }

    public func with(correlationID: String?) -> StructuredLogger {
        StructuredLogger(logger: logger, correlationID: correlationID)
    }

    public func debug(_ message: String, fields: [String: LogFieldValue] = [:]) {
        log(.debug, message, fields: fields)
    }

    public func info(_ message: String, fields: [String: LogFieldValue] = [:]) {
        log(.info, message, fields: fields)
    }

    public func warn(_ message: String, fields: [String: LogFieldValue] = [:]) {
        log(.warn, message, fields: fields)
    }

    public func error(_ message: String, fields: [String: LogFieldValue] = [:]) {
        log(.error, message, fields: fields)
    }

    public func log(_ level: LogLevel, _ message: String, fields: [String: LogFieldValue] = [:]) {
        if level == .debug, !LogConfiguration.shouldEmitDebug {
            return
        }

        var metadataParts: [String] = []
        if let correlationID {
            metadataParts.append("corr=\(correlationID)")
        }
        if let buildInfo {
            metadataParts.append("build=\(buildInfo)")
        }
        metadataParts.append("platform=\(ProcessInfo.processInfo.operatingSystemVersionString)")

        if !fields.isEmpty {
            let rendered = fields.map { key, value in
                "\(key)=\(value.rendered)"
            }
            metadataParts.append(rendered.joined(separator: ","))
        }

        let metadata = metadataParts.joined(separator: " ")
        logger.log(level: level.osLogType, "\(message, privacy: .public) \(metadata, privacy: .private)")
    }
}

private extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warn:
            return .default
        case .error:
            return .error
        }
    }
}
