import Foundation
import ComposableArchitecture

@Reducer
struct SegmentTypeSheetFeature {
    @ObservableState
    struct State: Equatable, Sendable, Identifiable {
        var id: UUID = UUID()
        var selectedType: SegmentType
        var stats: SegmentStats
        var addMilestone: Bool = false
        var editingSegmentId: Int64?

        var startIndex: Int
        var endIndex: Int
        var startDistance: Double
        var endDistance: Double

        @Shared(.inMemory("isPremium")) var isPremium = false

        var isEditing: Bool { editingSegmentId != nil }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case typeSelected(SegmentType)
        case saveButtonTapped
        case deleteButtonTapped
        case dismissTapped
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding: return .none
            case .typeSelected(let type):
                state.selectedType = type
                return .none
            case .saveButtonTapped, .deleteButtonTapped, .dismissTapped:
                return .none
            }
        }
    }
}
