import Foundation
import ComposableArchitecture
import CoreLocation

// MARK: - MilestoneSheet Reducer

@Reducer
struct MilestoneSheetFeature {
    @ObservableState
    struct State: Equatable, Sendable, Identifiable {
        var id: UUID = UUID()
        var editingMilestone: Milestone?
        var pointIndex: Int
        var latitude: Double
        var longitude: Double
        var elevation: Double
        var distance: Double
        var selectedType: MilestoneType
        var personalMessage: String
        var name: String
        var autoMessage: String? = nil
        var isPlayingPreview = false
        @Shared(.inMemory("isPremium")) var isPremium = false

        var isEditing: Bool { editingMilestone != nil }
    }

    static func buildFullMessage(
        autoMessage: String?,
        personalMessage: String,
        includeAuto: Bool
    ) -> String? {
        var parts: [String] = []
        if includeAuto, let auto = autoMessage, !auto.isEmpty {
            parts.append(auto)
        }
        if !personalMessage.isEmpty {
            parts.append(personalMessage)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case typeSelected(MilestoneType)
        case saveButtonTapped
        case deleteButtonTapped
        case dismissTapped
        case previewTTSTapped
        case stopTTSTapped
        case ttsFinished
    }

    @Dependency(\.speech) var speech

    private enum CancelID { case ttsPreview }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case .typeSelected(let type):
                state.selectedType = type
                return .none
            case .saveButtonTapped:
                return .none
            case .deleteButtonTapped:
                return .none
            case .dismissTapped:
                speech.stop()
                return .cancel(id: CancelID.ttsPreview)
            case .previewTTSTapped:
                guard !(state.autoMessage ?? "").isEmpty || !state.personalMessage.isEmpty else { return .none }
                state.isPlayingPreview = true
                let fullMessage = Self.buildFullMessage(
                    autoMessage: state.autoMessage,
                    personalMessage: state.personalMessage,
                    includeAuto: true
                )!
                return .run { send in
                    try? speech.configureAudioSession()
                    await speech.speak(fullMessage)
                    await send(.ttsFinished)
                }
                .cancellable(id: CancelID.ttsPreview)
            case .stopTTSTapped:
                state.isPlayingPreview = false
                speech.stop()
                return .cancel(id: CancelID.ttsPreview)
            case .ttsFinished:
                state.isPlayingPreview = false
                return .none
            }
        }
    }
}

// MARK: - Pending Trail Data (données non sauvegardées)

struct PendingTrailData: Equatable, Sendable {
    var trail: Trail
    var trackPoints: [TrackPoint]
    var detectedMilestones: [Milestone]
    var detectedSegments: [Segment]
}

// MARK: - Editor Tool

enum EditorTool: Equatable, Sendable {
    case segment
    case repere
}

// MARK: - Trim State

struct TrimState: Equatable, Sendable {
    var leftIndex: Int
    var rightIndex: Int
    var editingSegmentId: Int64?  // nil = creating, non-nil = editing existing
}

// MARK: - Editor Feature

@Reducer
struct EditorFeature {
    @ObservableState
    struct State: Equatable, Sendable {
        // Mode: soit trailId (existant), soit pendingData (nouveau)
        var trailId: Int64?
        var pendingData: PendingTrailData?

        var trailDetail: TrailDetail?
        var cursorPointIndex: Int?
        var scrolledPointIndex: Int = 0
        var milestones: [Milestone] = []
        var originalMilestones: [Milestone] = []
        var isRenamingTrail = false
        var editedTrailName = ""
        // TODO: Réactiver pour gestion batch des milestones
        // var isSelectingMilestones = false
        // var selectedMilestoneIndices: Set<Int> = []
        var activeTool: EditorTool? = nil
        var trimState: TrimState? = nil
        var segments: [Segment] = []
        var originalSegments: [Segment] = []
        var isSavingInBackground = false
        @Shared(.inMemory("isPremium")) var isPremium = false
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var milestoneSheet: MilestoneSheetFeature.State?
        @Presents var segmentTypeSheet: SegmentTypeSheetFeature.State?
        @Presents var paywall: PaywallFeature.State?

        var hasMilestoneChanges: Bool {
            milestones != originalMilestones
        }

        // Init pour un trail existant
        init(trailId: Int64) {
            self.trailId = trailId
            self.pendingData = nil
        }

        // Init pour un nouveau trail (données en mémoire)
        init(pendingData: PendingTrailData) {
            self.trailId = nil
            self.pendingData = pendingData
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onAppear
        case trailLoaded(TrailDetail)
        case cursorMoved(Int?)
        case scrollPositionChanged(Int)
        case profileTapped(Int)
        case saveButtonTapped
        case savingCompleted([Milestone])
        case milestoneSheet(PresentationAction<MilestoneSheetFeature.Action>)
        case segmentTypeSheet(PresentationAction<SegmentTypeSheetFeature.Action>)
        case deleteMilestone(Int)
        case editMilestone(Milestone)
        // TODO: Réactiver pour gestion batch des milestones
        // case toggleSelectionMode
        // case toggleMilestoneSelection(Int)
        // case deleteSelectedMilestones
        case backTapped
        case deleteTrailButtonTapped
        case renameButtonTapped
        case renameConfirmed
        case renameCancelled
        case trailNameUpdated(String)
        case alert(PresentationAction<Alert>)
        case paywall(PresentationAction<PaywallFeature.Action>)

        // Segment toolbox
        case toolSelected(EditorTool?)
        case trimLeftMoved(Int)
        case trimRightMoved(Int)
        case trimValidated
        case autoDetectTapped
        case segmentTapped(Segment)
        case _insertSegment(Segment)
        case _updateSegment(Segment)
        case _deleteSegmentById(Int64)
        case _segmentSaved(Segment)
        case _segmentDeleted(Int64)

        // Background save
        case backgroundSaveCompleted(Trail, [Milestone])
        case backgroundSaveFailed

        @CasePathable
        enum Alert: Sendable {
            case confirmDelete
        }

        // MARK: - Internal actions (for testability)
        case _loadTrailDetail
        case _loadPendingData
        case _saveMilestones
        case _removeMilestoneAt(Int)
        // TODO: Réactiver pour gestion batch des milestones
        // case _removeSelectedMilestones
        case _addMilestone(Milestone)
        case _updateMilestone(Int64, MilestoneType, String, String?)
        case _updateTrailName(String)
        case _deleteTrail
    }

    @Dependency(\.database) var database
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                // Mode 1: Trail existant - charger depuis la DB
                if state.trailId != nil {
                    return .send(._loadTrailDetail)
                }
                // Mode 2: Nouveau trail - utiliser les données en mémoire
                if state.pendingData != nil {
                    return .send(._loadPendingData)
                }
                return .none

            case ._loadTrailDetail:
                return .run { [trailId = state.trailId] send in
                    if let trailId, let detail = try await database.fetchTrailDetail(trailId) {
                        await send(.trailLoaded(detail))
                    }
                }

            case ._loadPendingData:
                guard let pending = state.pendingData else { return .none }

                // Créer un TrailDetail temporaire pour l'affichage
                let detail = TrailDetail(
                    trail: pending.trail,
                    trackPoints: pending.trackPoints,
                    milestones: pending.detectedMilestones,
                    segments: pending.detectedSegments
                )
                state.trailDetail = detail
                state.milestones = pending.detectedMilestones
                state.originalMilestones = pending.detectedMilestones
                state.segments = pending.detectedSegments
                state.originalSegments = pending.detectedSegments
                state.isSavingInBackground = true

                // Lancer la sauvegarde en arrière-plan
                return .run { [pending] send in
                    do {
                        // 1. Sauvegarder le trail et les trackpoints
                        let savedTrail = try await database.insertTrail(pending.trail, pending.trackPoints)

                        // 2. Sauvegarder les milestones si présents
                        if let trailId = savedTrail.id, !pending.detectedMilestones.isEmpty {
                            // Mettre à jour les milestones avec le bon trailId
                            let milestonesWithTrailId = pending.detectedMilestones.map { milestone in
                                Milestone(
                                    id: nil,
                                    trailId: trailId,
                                    pointIndex: milestone.pointIndex,
                                    latitude: milestone.latitude,
                                    longitude: milestone.longitude,
                                    elevation: milestone.elevation,
                                    distance: milestone.distance,
                                    type: milestone.milestoneType,
                                    message: milestone.message,
                                    name: milestone.name
                                )
                            }
                            let savedMs = try await database.saveMilestones(trailId, milestonesWithTrailId)

                            // 3. Sauvegarder les segments si présents
                            if !pending.detectedSegments.isEmpty {
                                // Mettre à jour les segments avec le bon trailId
                                for segment in pending.detectedSegments {
                                    let segmentWithTrailId = Segment(
                                        id: nil,
                                        trailId: trailId,
                                        type: segment.type,
                                        startIndex: segment.startIndex,
                                        endIndex: segment.endIndex,
                                        startDistance: segment.startDistance,
                                        endDistance: segment.endDistance
                                    )
                                    _ = try await database.insertSegment(segmentWithTrailId)
                                }
                            }

                            await send(.backgroundSaveCompleted(savedTrail, savedMs))
                        } else {
                            await send(.backgroundSaveCompleted(savedTrail, []))
                        }
                    } catch {
                        await send(.backgroundSaveFailed)
                    }
                }

            case let .trailLoaded(detail):
                state.trailDetail = detail
                state.milestones = detail.milestones
                state.originalMilestones = detail.milestones
                state.segments = detail.segments
                state.originalSegments = detail.segments
                return .none

            case let .backgroundSaveCompleted(savedTrail, savedMilestones):
                state.isSavingInBackground = false
                state.trailId = savedTrail.id
                state.pendingData = nil
                state.trailDetail?.trail = savedTrail
                if !savedMilestones.isEmpty {
                    state.milestones = savedMilestones
                    state.originalMilestones = savedMilestones
                }
                return .none

            case .backgroundSaveFailed:
                state.isSavingInBackground = false
                // TODO: Gérer l'erreur (afficher une alerte ?)
                return .none

            case let .cursorMoved(index):
                state.cursorPointIndex = index
                return .none

            case let .scrollPositionChanged(index):
                state.scrolledPointIndex = index
                return .none

            // MARK: - Segment Toolbox

            case .toolSelected(let tool):
                state.activeTool = tool
                if tool == .segment {
                    let totalPoints = state.trailDetail?.trackPoints.count ?? 0
                    let center = state.scrolledPointIndex
                    let offset = max(totalPoints / 7, 20)
                    state.trimState = TrimState(
                        leftIndex: max(0, center - offset),
                        rightIndex: min(totalPoints - 1, center + offset)
                    )
                } else {
                    state.trimState = nil
                }
                return .none

            case .trimLeftMoved(let index):
                guard var trim = state.trimState else { return .none }
                trim.leftIndex = min(index, trim.rightIndex - 1)
                trim.leftIndex = max(0, trim.leftIndex)
                for seg in state.segments where seg.id != trim.editingSegmentId {
                    if trim.leftIndex >= seg.startIndex && trim.leftIndex <= seg.endIndex {
                        trim.leftIndex = seg.endIndex + 1
                    }
                }
                state.trimState = trim
                return .none

            case .trimRightMoved(let index):
                guard var trim = state.trimState else { return .none }
                let maxIndex = (state.trailDetail?.trackPoints.count ?? 1) - 1
                trim.rightIndex = max(index, trim.leftIndex + 1)
                trim.rightIndex = min(maxIndex, trim.rightIndex)
                for seg in state.segments where seg.id != trim.editingSegmentId {
                    if trim.rightIndex >= seg.startIndex && trim.rightIndex <= seg.endIndex {
                        trim.rightIndex = seg.startIndex - 1
                    }
                }
                state.trimState = trim
                return .none

            case .trimValidated:
                guard let trim = state.trimState,
                      let detail = state.trailDetail,
                      trim.leftIndex < detail.trackPoints.count,
                      trim.rightIndex < detail.trackPoints.count else { return .none }

                let trackPoints = detail.trackPoints
                let leftPoint = trackPoints[trim.leftIndex]
                let rightPoint = trackPoints[trim.rightIndex]

                // Auto-detect type from elevation trend
                let elevDelta = rightPoint.elevation - leftPoint.elevation
                let distance = rightPoint.distance - leftPoint.distance
                let slope = distance > 0 ? elevDelta / distance : 0
                let detectedType: SegmentType = slope > 0.05 ? .climbing : (slope < -0.05 ? .descending : .flat)

                let tempSegment = Segment(
                    id: trim.editingSegmentId,
                    trailId: state.trailId ?? 0,
                    type: detectedType.rawValue,
                    startIndex: trim.leftIndex,
                    endIndex: trim.rightIndex,
                    startDistance: leftPoint.distance,
                    endDistance: rightPoint.distance
                )
                let stats = Segment.computeStats(segment: tempSegment, trackPoints: trackPoints)

                state.segmentTypeSheet = SegmentTypeSheetFeature.State(
                    selectedType: detectedType,
                    stats: stats,
                    editingSegmentId: trim.editingSegmentId,
                    startIndex: trim.leftIndex,
                    endIndex: trim.rightIndex,
                    startDistance: leftPoint.distance,
                    endDistance: rightPoint.distance
                )
                return .none

            case .segmentTapped(let segment):
                state.activeTool = .segment
                state.trimState = TrimState(
                    leftIndex: segment.startIndex,
                    rightIndex: segment.endIndex,
                    editingSegmentId: segment.id
                )
                return .none

            case .autoDetectTapped:
                if !state.isPremium {
                    state.paywall = PaywallFeature.State()
                    return .none
                }
                guard let detail = state.trailDetail else { return .none }

                let analyzerSegments = ElevationProfileAnalyzer.segments(from: detail.trackPoints)
                let existingSegments = state.segments

                // Map analyzer segments to Segment entities, filtering out overlaps
                var newSegments: [Segment] = []
                for seg in analyzerSegments {
                    let candidate = Segment(
                        trailId: state.trailId ?? 0,
                        type: seg.type == .climbing ? SegmentType.climbing.rawValue :
                              seg.type == .descending ? SegmentType.descending.rawValue :
                              SegmentType.flat.rawValue,
                        startIndex: seg.startIndex,
                        endIndex: seg.endIndex,
                        startDistance: seg.startDistance,
                        endDistance: seg.endDistance
                    )
                    if !Segment.overlaps(candidate, with: existingSegments + newSegments) {
                        newSegments.append(candidate)
                    }
                }

                guard !newSegments.isEmpty else { return .none }

                // Insert all new segments
                return .run { [database, newSegments] send in
                    for segment in newSegments {
                        let saved = try await database.insertSegment(segment)
                        await send(._segmentSaved(saved))
                    }
                }

            case ._insertSegment(let segment):
                return .run { [database] send in
                    let saved = try await database.insertSegment(segment)
                    await send(._segmentSaved(saved))
                }

            case ._updateSegment(let segment):
                return .run { [database] send in
                    let saved = try await database.updateSegment(segment)
                    await send(._segmentSaved(saved))
                }

            case ._deleteSegmentById(let segmentId):
                return .run { [database] send in
                    try await database.deleteSegment(segmentId)
                    await send(._segmentDeleted(segmentId))
                }

            case ._segmentSaved(let segment):
                if let index = state.segments.firstIndex(where: { $0.id == segment.id }) {
                    state.segments[index] = segment
                } else {
                    state.segments.append(segment)
                    state.segments.sort { $0.startDistance < $1.startDistance }
                }
                state.originalSegments = state.segments
                state.activeTool = nil
                state.trimState = nil
                return .none

            case ._segmentDeleted(let segmentId):
                state.segments.removeAll { $0.id == segmentId }
                state.originalSegments = state.segments
                state.activeTool = nil
                state.trimState = nil
                return .none

            case let .profileTapped(pointIndex):
                guard let detail = state.trailDetail,
                      pointIndex < detail.trackPoints.count else { return .none }

                // Free users: max 10 milestones
                if !state.isPremium && state.milestones.count >= 10 {
                    state.paywall = PaywallFeature.State()
                    return .none
                }

                let point = detail.trackPoints[pointIndex]

                // Auto-detect type based on segments or elevation change
                let detectedType: MilestoneType
                if let segment = Segment.findSegment(containing: pointIndex, in: state.segments) {
                    // Use segment type if available
                    switch segment.segmentType {
                    case .climbing: detectedType = .montee
                    case .descending: detectedType = .descente
                    case .flat: detectedType = .plat
                    }
                } else {
                    // Fallback to elevation-based detection
                    let lookAhead = 20
                    let futureIndex = min(pointIndex + lookAhead, detail.trackPoints.count - 1)
                    if futureIndex > pointIndex {
                        let currentElevation = detail.trackPoints[pointIndex].elevation
                        let futureElevation = detail.trackPoints[futureIndex].elevation
                        let delta = futureElevation - currentElevation
                        if delta > 10 {
                            detectedType = .montee
                        } else if delta < -10 {
                            detectedType = .descente
                        } else {
                            detectedType = .plat
                        }
                    } else {
                        detectedType = .plat
                    }
                }

                // Compute autoMessage from segments
                var autoMessage: String? = nil
                if let segment = Segment.findSegment(containing: pointIndex, in: state.segments) {
                    let stats = Segment.computeStats(segment: segment, trackPoints: detail.trackPoints)
                    autoMessage = AnnouncementBuilder.build(
                        type: detectedType,
                        name: nil,
                        segmentStats: stats
                    )
                }

                state.milestoneSheet = MilestoneSheetFeature.State(
                    editingMilestone: nil,
                    pointIndex: pointIndex,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    elevation: point.elevation,
                    distance: point.distance,
                    selectedType: detectedType,
                    personalMessage: "",
                    name: "",
                    autoMessage: autoMessage
                )
                return .none

            case let .editMilestone(milestone):
                var autoMessage: String? = nil
                var personalMessage = milestone.message
                if let segment = Segment.findSegment(containing: milestone.pointIndex, in: state.segments),
                   let detail = state.trailDetail {
                    let stats = Segment.computeStats(segment: segment, trackPoints: detail.trackPoints)
                    autoMessage = AnnouncementBuilder.build(
                        type: milestone.milestoneType,
                        name: milestone.name,
                        segmentStats: stats
                    )
                    // Split prefix
                    if let auto = autoMessage, personalMessage.hasPrefix(auto) {
                        personalMessage = String(personalMessage.dropFirst(auto.count)).trimmingCharacters(in: .whitespaces)
                    }
                }

                state.milestoneSheet = MilestoneSheetFeature.State(
                    editingMilestone: milestone,
                    pointIndex: milestone.pointIndex,
                    latitude: milestone.latitude,
                    longitude: milestone.longitude,
                    elevation: milestone.elevation,
                    distance: milestone.distance,
                    selectedType: milestone.milestoneType,
                    personalMessage: personalMessage,
                    name: milestone.name ?? "",
                    autoMessage: autoMessage
                )
                return .none

            case let .deleteMilestone(index):
                return .concatenate(
                    .send(._removeMilestoneAt(index)),
                    .send(._saveMilestones)
                )

            case let ._removeMilestoneAt(index):
                guard index < state.milestones.count else { return .none }
                state.milestones.remove(at: index)
                return .none

            // TODO: Réactiver pour gestion batch des milestones
            // case .toggleSelectionMode:
            //     state.isSelectingMilestones.toggle()
            //     if !state.isSelectingMilestones {
            //         state.selectedMilestoneIndices.removeAll()
            //     }
            //     return .none

            // case let .toggleMilestoneSelection(index):
            //     if state.selectedMilestoneIndices.contains(index) {
            //         state.selectedMilestoneIndices.remove(index)
            //     } else {
            //         state.selectedMilestoneIndices.insert(index)
            //     }
            //     return .none

            // case .deleteSelectedMilestones:
            //     return .concatenate(
            //         .send(._removeSelectedMilestones),
            //         .send(._saveMilestones)
            //     )

            // case ._removeSelectedMilestones:
            //     let indicesToDelete = state.selectedMilestoneIndices.sorted(by: >)
            //     for index in indicesToDelete {
            //         if index < state.milestones.count {
            //             state.milestones.remove(at: index)
            //         }
            //     }
            //     state.selectedMilestoneIndices.removeAll()
            //     state.isSelectingMilestones = false
            //     return .none

            case .saveButtonTapped:
                return .send(._saveMilestones)

            case ._saveMilestones:
                // Ne sauvegarder que si on a un trailId (données déjà en DB)
                guard let trailId = state.trailId else { return .none }
                return .run { [milestones = state.milestones] send in
                    let saved = try await database.saveMilestones(trailId, milestones)
                    await send(.savingCompleted(saved))
                }

            case let .savingCompleted(savedMilestones):
                state.milestones = savedMilestones
                state.originalMilestones = savedMilestones
                return .none

            case .milestoneSheet(.presented(.typeSelected(let type))):
                if let sheet = state.milestoneSheet {
                    var autoMessage: String? = nil
                    if let segment = Segment.findSegment(containing: sheet.pointIndex, in: state.segments),
                       let detail = state.trailDetail {
                        let stats = Segment.computeStats(segment: segment, trackPoints: detail.trackPoints)
                        autoMessage = AnnouncementBuilder.build(
                            type: type,
                            name: sheet.name.isEmpty ? nil : sheet.name,
                            segmentStats: stats
                        )
                    }
                    state.milestoneSheet?.autoMessage = autoMessage
                }
                return .none

            case .milestoneSheet(.presented(.saveButtonTapped)):
                guard let sheet = state.milestoneSheet else { return .none }

                let fullMessage = MilestoneSheetFeature.buildFullMessage(
                    autoMessage: sheet.autoMessage,
                    personalMessage: sheet.personalMessage,
                    includeAuto: state.isPremium
                ) ?? sheet.selectedType.label
                let name: String? = sheet.name.isEmpty ? nil : sheet.name
                let currentTrailId = state.trailId ?? 0

                state.milestoneSheet = nil

                if let existingMilestone = sheet.editingMilestone,
                   existingMilestone.id != nil {
                    return .concatenate(
                        .send(._updateMilestone(existingMilestone.id!, sheet.selectedType, fullMessage, name)),
                        .send(._saveMilestones)
                    )
                } else {
                    let milestone = Milestone(
                        id: nil,
                        trailId: currentTrailId,
                        pointIndex: sheet.pointIndex,
                        latitude: sheet.latitude,
                        longitude: sheet.longitude,
                        elevation: sheet.elevation,
                        distance: sheet.distance,
                        type: sheet.selectedType,
                        message: fullMessage,
                        name: name
                    )
                    return .concatenate(
                        .send(._addMilestone(milestone)),
                        .send(._saveMilestones)
                    )
                }

            case let ._addMilestone(milestone):
                state.milestones.append(milestone)
                state.milestones.sort { $0.distance < $1.distance }
                return .none

            case let ._updateMilestone(id, type, message, name):
                guard let index = state.milestones.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                state.milestones[index].type = type.rawValue
                state.milestones[index].message = message
                state.milestones[index].name = name
                return .none

            case .milestoneSheet(.presented(.deleteButtonTapped)):
                guard let sheet = state.milestoneSheet,
                      let editingMilestone = sheet.editingMilestone,
                      let milestoneId = editingMilestone.id,
                      let index = state.milestones.firstIndex(where: { $0.id == milestoneId }) else {
                    state.milestoneSheet = nil
                    return .none
                }
                state.milestoneSheet = nil
                return .concatenate(
                    .send(._removeMilestoneAt(index)),
                    .send(._saveMilestones)
                )

            case .milestoneSheet(.presented(.dismissTapped)):
                state.milestoneSheet = nil
                return .none

            case .milestoneSheet(.presented(.binding)):
                return .none

            case .milestoneSheet(.presented(.previewTTSTapped)),
                 .milestoneSheet(.presented(.stopTTSTapped)),
                 .milestoneSheet(.presented(.ttsFinished)):
                return .none

            case .milestoneSheet(.dismiss):
                return .none

            case .backTapped:
                return .run { _ in
                    await dismiss()
                }

            case .deleteTrailButtonTapped:
                state.alert = AlertState {
                    TextState("Supprimer ce parcours ?")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("Annuler")
                    }
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("Supprimer")
                    }
                } message: {
                    TextState("Cette action supprimera définitivement le parcours et tous ses repères.")
                }
                return .none

            case .renameButtonTapped:
                state.editedTrailName = state.trailDetail?.trail.name ?? ""
                state.isRenamingTrail = true
                return .none

            case .renameConfirmed:
                state.isRenamingTrail = false
                let newName = state.editedTrailName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !newName.isEmpty else { return .none }
                // Ne renommer que si on a un trailId
                guard state.trailId != nil else {
                    // Pour un pending trail, juste mettre à jour localement
                    state.trailDetail?.trail.name = newName
                    state.pendingData?.trail.name = newName
                    return .none
                }
                return .send(._updateTrailName(newName))

            case let ._updateTrailName(newName):
                guard let trailId = state.trailId else { return .none }
                return .run { send in
                    try await database.updateTrailName(trailId, newName)
                    await send(.trailNameUpdated(newName))
                }

            case .renameCancelled:
                state.isRenamingTrail = false
                return .none

            case let .trailNameUpdated(newName):
                state.trailDetail?.trail.name = newName
                return .none

            case .alert(.presented(.confirmDelete)):
                return .send(._deleteTrail)

            case ._deleteTrail:
                guard let trailId = state.trailId else {
                    // Si pas encore sauvé, juste fermer
                    return .run { _ in await dismiss() }
                }
                return .run { _ in
                    try await database.deleteTrail(trailId)
                    await dismiss()
                }

            case .alert:
                return .none

            // MARK: - Segment Type Sheet

            case .segmentTypeSheet(.presented(.saveButtonTapped)):
                guard let sheet = state.segmentTypeSheet else { return .none }
                let trailId = state.trailId ?? 0
                let segment = Segment(
                    id: sheet.editingSegmentId,
                    trailId: trailId,
                    type: sheet.selectedType.rawValue,
                    startIndex: sheet.startIndex,
                    endIndex: sheet.endIndex,
                    startDistance: sheet.startDistance,
                    endDistance: sheet.endDistance
                )

                state.segmentTypeSheet = nil

                var effects: [Effect<Action>] = []
                if sheet.isEditing {
                    effects.append(.send(._updateSegment(segment)))
                } else {
                    effects.append(.send(._insertSegment(segment)))
                }

                // Auto-create milestone if toggle is ON
                if sheet.addMilestone, let detail = state.trailDetail {
                    let point = detail.trackPoints[sheet.startIndex]
                    let milestoneType = sheet.selectedType.milestoneType
                    let stats = Segment.computeStats(segment: segment, trackPoints: detail.trackPoints)
                    let autoMessage = AnnouncementBuilder.build(type: milestoneType, name: nil, segmentStats: stats)
                    let message = autoMessage ?? milestoneType.label

                    let milestone = Milestone(
                        trailId: trailId,
                        pointIndex: sheet.startIndex,
                        latitude: point.latitude,
                        longitude: point.longitude,
                        elevation: point.elevation,
                        distance: point.distance,
                        type: milestoneType,
                        message: message
                    )
                    effects.append(.send(._addMilestone(milestone)))
                    effects.append(.send(._saveMilestones))
                }

                return .concatenate(effects)

            case .segmentTypeSheet(.presented(.deleteButtonTapped)):
                guard let sheet = state.segmentTypeSheet,
                      let segmentId = sheet.editingSegmentId else {
                    state.segmentTypeSheet = nil
                    return .none
                }
                state.segmentTypeSheet = nil
                return .send(._deleteSegmentById(segmentId))

            case .segmentTypeSheet(.presented(.dismissTapped)):
                state.segmentTypeSheet = nil
                state.activeTool = nil
                state.trimState = nil
                return .none

            case .segmentTypeSheet(.presented(.binding)),
                 .segmentTypeSheet(.presented(.typeSelected)):
                return .none

            case .segmentTypeSheet(.dismiss):
                return .none

            // MARK: - Paywall

            case .paywall(.presented(.purchaseCompleted)),
                 .paywall(.presented(.restoreCompleted)):
                state.$isPremium.withLock { $0 = true }
                return .none

            case .paywall(.dismiss):
                state.paywall = nil
                return .none

            case .paywall:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$milestoneSheet, action: \.milestoneSheet) {
            MilestoneSheetFeature()
        }
        .ifLet(\.$segmentTypeSheet, action: \.segmentTypeSheet) {
            SegmentTypeSheetFeature()
        }
        .ifLet(\.$paywall, action: \.paywall) {
            PaywallFeature()
        }
    }

    // MARK: - Helpers
}
