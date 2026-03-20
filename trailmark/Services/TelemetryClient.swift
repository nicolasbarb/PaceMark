import Foundation
import Dependencies
import TelemetryDeck

// MARK: - TelemetryClient

struct TelemetryClient: Sendable {
    var signal: @Sendable (_ name: String, _ parameters: [String: String]) -> Void
}

// MARK: - DependencyKey

extension TelemetryClient: DependencyKey {
    static var liveValue: TelemetryClient {
        TelemetryClient(
            signal: { name, parameters in
                TelemetryDeck.signal(name, parameters: parameters)
            }
        )
    }

    static var testValue: TelemetryClient {
        TelemetryClient(
            signal: { _, _ in }
        )
    }

    static var previewValue: TelemetryClient {
        TelemetryClient(
            signal: { _, _ in }
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var telemetry: TelemetryClient {
        get { self[TelemetryClient.self] }
        set { self[TelemetryClient.self] = newValue }
    }
}