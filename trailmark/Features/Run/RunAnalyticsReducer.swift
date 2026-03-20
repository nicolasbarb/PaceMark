import ComposableArchitecture
import CoreLocation

struct RunAnalyticsReducer: Reducer {
    @Dependency(\.telemetry) var telemetry

    func reduce(into state: inout RunStore.State, action: RunStore.Action) -> Effect<RunStore.Action> {
        switch action {
        case .startButtonTapped:
            let milestoneCount = state.trailDetail?.milestones.count ?? 0
            let distance = state.trailDetail?.trail.distance ?? 0
            return .run { [telemetry] _ in
                telemetry.signal("Run.started", [
                    "milestoneCount": "\(milestoneCount)",
                    "distance": "\(Int(distance))"
                ])
            }

        case let .authorizationResult(rawValue):
            let status = CLAuthorizationStatus(rawValue: rawValue) ?? .notDetermined
            let statusName: String
            switch status {
            case .authorizedAlways:
                statusName = "always"
            case .authorizedWhenInUse:
                statusName = "whenInUse"
            default:
                return .none
            }
            return .run { [telemetry] _ in
                telemetry.signal("Run.gpsAuthorized", ["status": statusName])
            }

        case let .milestoneTriggered(milestone):
            let totalCount = state.trailDetail?.milestones.count ?? 0
            let triggeredCount = state.triggeredMilestoneIds.count
            return .run { [telemetry] _ in
                telemetry.signal("Run.milestoneTriggered", [
                    "type": milestone.type,
                    "triggeredCount": "\(triggeredCount)",
                    "totalCount": "\(totalCount)"
                ])
            }

        case .stopButtonTapped:
            let totalCount = state.trailDetail?.milestones.count ?? 0
            let triggeredCount = state.triggeredMilestoneIds.count
            let distance = state.trailDetail?.trail.distance ?? 0
            return .run { [telemetry] _ in
                telemetry.signal("Run.completed", [
                    "triggeredCount": "\(triggeredCount)",
                    "totalCount": "\(totalCount)",
                    "distance": "\(Int(distance))"
                ])
            }

        case .backTapped:
            guard state.isRunning else { return .none }
            let totalCount = state.trailDetail?.milestones.count ?? 0
            let triggeredCount = state.triggeredMilestoneIds.count
            return .run { [telemetry] _ in
                telemetry.signal("Run.abandoned", [
                    "triggeredCount": "\(triggeredCount)",
                    "totalCount": "\(totalCount)"
                ])
            }

        default:
            return .none
        }
    }
}
