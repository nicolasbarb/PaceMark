import Foundation
import ComposableArchitecture
import UniformTypeIdentifiers

@Reducer
struct ImportFeature {
    @ObservableState
    struct State: Equatable, Sendable {
        var phase: Phase = .upload
        var isShowingFilePicker = false
        var error: String?

        // Données parsées (pas en DB, juste en mémoire)
        var parsedTrail: Trail?
        var parsedTrackPoints: [TrackPoint] = []
        var detectedMilestones: [Milestone] = []
        var detectedSegments: [Segment] = []
        @Shared(.inMemory("isPremium")) var isPremium = false

        // Paywall
        @Presents var paywall: PaywallFeature.State?

        enum Phase: Equatable, Sendable {
            case upload
            case analyzing
            case result
        }
    }

    enum Action: Equatable {
        // Upload phase
        case uploadZoneTapped
        case filePickerDismissed
        case fileSelected(String) // URL path as String for Sendable

        // Analysis
        case analysisCompleted(Trail, [TrackPoint], [Milestone], [Segment])
        case importFailed(String)

        // Result phase
        case unlockTapped
        case continueWithMilestonesTapped
        case skipTapped
        case dismissTapped

        // Output to parent - envoie les données en mémoire, pas de trailId
        case importCompleted(PendingTrailData)

        // Paywall
        case paywall(PresentationAction<PaywallFeature.Action>)
    }

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            // MARK: - Upload Phase

            case .uploadZoneTapped:
                state.isShowingFilePicker = true
                state.error = nil
                return .none

            case .filePickerDismissed:
                state.isShowingFilePicker = false
                return .none

            case let .fileSelected(urlPath):
                state.phase = .analyzing
                state.error = nil
                let url = URL(fileURLWithPath: urlPath)
                let isPremium = state.isPremium

                return .run { send in
                    do {
                        // 1. Parser le GPX
                        let (parsedPoints, dPlus) = try await MainActor.run {
                            try GPXParser.parse(url: url)
                        }
                        let trailName = GPXParser.trailName(from: url)
                        let totalDistance = parsedPoints.last?.distance ?? 0

                        // 2. Créer le trail (sans id, pas en DB)
                        let trail = Trail(
                            id: nil,
                            name: trailName,
                            createdAt: Date(),
                            distance: totalDistance,
                            dPlus: dPlus
                        )

                        // 3. Créer les track points (trailId sera assigné plus tard)
                        let trackPoints = parsedPoints.enumerated().map { index, point in
                            TrackPoint(
                                id: nil,
                                trailId: 0,
                                index: index,
                                latitude: point.latitude,
                                longitude: point.longitude,
                                elevation: point.elevation,
                                distance: point.distance
                            )
                        }

                        if isPremium {
                            // PRO: detect segments + milestones
                            let analyzerSegments = ElevationProfileAnalyzer.segments(from: trackPoints)
                            let segments = analyzerSegments.map { seg in
                                Segment(
                                    trailId: 0,
                                    type: seg.type == .climbing ? SegmentType.climbing.rawValue :
                                          seg.type == .descending ? SegmentType.descending.rawValue :
                                          SegmentType.flat.rawValue,
                                    startIndex: seg.startIndex,
                                    endIndex: seg.endIndex,
                                    startDistance: seg.startDistance,
                                    endDistance: seg.endDistance
                                )
                            }
                            let milestones = MilestoneDetector.detect(from: trackPoints, trailId: 0)
                            await send(.analysisCompleted(trail, trackPoints, milestones, segments))
                        } else {
                            // Free: skip analysis, go directly to editor
                            let pendingData = PendingTrailData(
                                trail: trail,
                                trackPoints: trackPoints,
                                detectedMilestones: [],
                                detectedSegments: []
                            )
                            await send(.importCompleted(pendingData))
                        }
                    } catch let error as GPXParser.ParseError {
                        await send(.importFailed(error.localizedDescription))
                    } catch {
                        await send(.importFailed("Erreur lors de l'import: \(error.localizedDescription)"))
                    }
                }

            // MARK: - Analysis Result

            case let .analysisCompleted(trail, trackPoints, milestones, segments):
                state.phase = .result
                state.parsedTrail = trail
                state.parsedTrackPoints = trackPoints
                state.detectedMilestones = milestones
                state.detectedSegments = segments
                return .none

            case let .importFailed(message):
                state.phase = .upload
                state.error = message
                return .none

            // MARK: - Result Phase Actions

            case .unlockTapped:
                state.paywall = PaywallFeature.State()
                return .none

            case .continueWithMilestonesTapped:
                // Premium: continuer avec les jalons détectés
                guard let trail = state.parsedTrail else { return .none }
                let pendingData = PendingTrailData(
                    trail: trail,
                    trackPoints: state.parsedTrackPoints,
                    detectedMilestones: state.detectedMilestones,
                    detectedSegments: state.detectedSegments
                )
                return .send(.importCompleted(pendingData))

            case .skipTapped:
                // Continuer sans les jalons détectés
                guard let trail = state.parsedTrail else { return .none }
                let pendingData = PendingTrailData(
                    trail: trail,
                    trackPoints: state.parsedTrackPoints,
                    detectedMilestones: [], // Pas de jalons
                    detectedSegments: []
                )
                return .send(.importCompleted(pendingData))

            case .dismissTapped:
                return .run { _ in
                    await dismiss()
                }

            case .importCompleted:
                // Handled by parent
                return .none

            // MARK: - Paywall

            case .paywall(.presented(.purchaseCompleted)),
                 .paywall(.presented(.restoreCompleted)):
                // RevenueCat handles the purchase — isPremium updated via premiumStatusStream
                state.$isPremium.withLock { $0 = true }
                return .none

            case .paywall(.dismiss):
                state.paywall = nil
                return .none

            case .paywall:
                return .none
            }
        }
        .ifLet(\.$paywall, action: \.paywall) {
            PaywallFeature()
        }
    }
}
