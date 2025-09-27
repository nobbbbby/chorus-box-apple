import Foundation
import Combine

public enum ChorusBoxErrorReporter {
    public struct Event {
        public let message: String
        public let underlyingError: Error?

        public init(message: String, underlyingError: Error? = nil) {
            self.message = message
            self.underlyingError = underlyingError
        }
    }

    public static let notificationName = Notification.Name("io.nobby.chorus-box.error")

    public static func report(message: String, error: Error? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: notificationName,
                object: Event(message: message, underlyingError: error)
            )
        }
    }

    public static var publisher: AnyPublisher<Event, Never> {
        NotificationCenter.default
            .publisher(for: notificationName)
            .compactMap { $0.object as? Event }
            .eraseToAnyPublisher()
    }
}
