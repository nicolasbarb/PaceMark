import SwiftUI
import ComposableArchitecture

struct MilestoneSheetView: View {
    @Bindable var store: StoreOf<MilestoneSheetStore>
    @Namespace private var typeIndicator
    @State private var selectedDetent: PresentationDetent = .fraction(0.44)

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [TM.accent.opacity(0.08), TM.bgSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch store.effectiveStep {
                        case .discovery:
                            discoveryCard

                        case .editing:
                            editingForm
                        }
                    }
                    .animation(.spring(duration: 0.35), value: store.effectiveStep)
                }
            }
            .presentationDetents([.fraction(0.44), .large], selection: $selectedDetent)
            .presentationBackground(store.effectiveStep == .discovery ? .clear : TM.bgCard)
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(store.effectiveStep == .editing)
            .onChange(of: store.effectiveStep) { _, newStep in
                withAnimation(.spring(duration: 0.4)) {
                    selectedDetent = newStep == .discovery ? .fraction(0.44) : .large
                }
            }
            .onChange(of: selectedDetent) { _, newDetent in
                // Empêcher l'utilisateur de changer le detent manuellement
                let expected: PresentationDetent = store.effectiveStep == .discovery ? .fraction(0.44) : .large
                if newDetent != expected {
                    selectedDetent = expected
                }
            }
            .toolbar(store.effectiveStep == .editing ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark", role: .cancel) {
                        Haptic.light.trigger()
                        store.send(.dismissTapped)
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(store.isEditing ? "Modifier" : "Nouveau repère")
                            .font(.headline)
                        PointStatsView(distanceMeters: store.distance, altitudeMeters: store.elevation)
                    }
                }

                if store.isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Supprimer", systemImage: "trash", role: .destructive) {
                            Haptic.warning.trigger()
                            store.send(.deleteButtonTapped)
                        }
                        .tint(TM.danger)
                    }

                    ToolbarSpacer(.fixed, placement: .confirmationAction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider", systemImage: "checkmark") {
                        Haptic.success.trigger()
                        store.send(.saveButtonTapped)
                    }
                    .fontWeight(.semibold)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Discovery Card

    private var discoveryCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(TM.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PaceMark a analysé le terrain")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(TM.textPrimary)
                        Text("Annonce générée pour vous")
                            .font(.subheadline)
                            .foregroundStyle(TM.textTertiary)
                    }
                }

                // Auto-generated text
                if let autoMessage = store.autoMessage {
                    Text(autoMessage)
                        .font(.body)
                        .foregroundStyle(store.isPremium ? TM.textPrimary : TM.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(store.isPremium ? TM.bgPrimary.opacity(0.5) : Color.black.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            if !store.isPremium {
                                ProBadge(isLockVisible: true)
                                    .padding(8)
                            }
                        }
                }

                // Listen preview
                Button(store.isPlayingPreview ? "Arrêter" : "Écouter", systemImage: store.isPlayingPreview ? "stop.fill" : "speaker.wave.2.fill") {
                    Haptic.light.trigger()
                    if store.isPlayingPreview {
                        store.send(.stopTTSTapped)
                    } else {
                        store.send(.previewTTSTapped)
                    }
                }
                .secondaryButton(size: .large, width: .flexible, shape: .capsule)

                // Choice buttons
                choiceButtons
            }
            .padding(16)
    }

    // MARK: - Editing Form (Step 2)

    @ViewBuilder
    private var editingForm: some View {
        VStack(alignment: .leading) {
            sectionLabel("TYPE")

            typeCardsSelector(selectedType: store.selectedType)
                .padding(.top, 8)

            sectionLabel("ANNONCE VOCALE")
                .padding(.top, 14)

            messageTextField(placeholder: messagePlaceholder)
                .padding(.top, 8)

            listenButton
                .padding(.top, 12)

            sectionLabel("NOM (OPTIONNEL)")
                .padding(.top, 14)

            TextField("ex: Col de la Croix", text: $store.name)
                .font(.body)
                .foregroundStyle(TM.textPrimary)
                .padding(12)
                .background(TM.bgPrimary, in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(TM.border, lineWidth: 1)
                }
                .padding(.top, 8)
        }
        .padding(16)
    }

    // MARK: - Choice Buttons

    private var choiceButtons: some View {
        VStack(spacing: 8) {
            if store.isPremium {
                Button("Utiliser", systemImage: "checkmark.circle.fill") {
                    withAnimation(.spring(duration: 0.3)) {
                        _ = store.send(.useAutoMessage)
                    }
                }
                .primaryButton(size: .large, width: .flexible, shape: .capsule)
            } else {
                Button("Débloquer", systemImage: "lock.open.fill") {
                    // TODO: trigger paywall
                }
                .primaryButton(size: .large, width: .flexible, shape: .capsule)
            }

            Button("Écrire moi-même") {
                withAnimation(.spring(duration: 0.3)) {
                    _ = store.send(.writeOwnMessage)
                }
            }
            .tertiaryButton(size: .large, tint: TM.textSecondary)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .tracking(1)
            .foregroundStyle(TM.textMuted)
    }

    private func messageTextField(placeholder: String) -> some View {
        TextField(
            placeholder,
            text: $store.personalMessage,
            axis: .vertical
        )
        .lineLimit(3...5)
        .font(.body)
        .foregroundStyle(TM.textPrimary)
        .padding(12)
        .background(TM.bgPrimary, in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(TM.border, lineWidth: 1)
        }
    }

    private var isListenDisabled: Bool {
        (store.autoMessage ?? "").isEmpty && store.personalMessage.isEmpty
    }

    private var listenButton: some View {
        
//        Button {
//            Haptic.light.trigger()
//            if store.isPlayingPreview {
//                store.send(.stopTTSTapped)
//            } else {
//                store.send(.previewTTSTapped)
//            }
//        } label: {
//            HStack(spacing: 8) {
//                Image(systemName: store.isPlayingPreview ? "stop.fill" : "speaker.wave.2.fill")
//                    .font(.system(size: 13, weight: .semibold))
//                Text(store.isPlayingPreview ? "Arrêter" : "Écouter l'annonce")
//                    .font(.subheadline.weight(.semibold))
//            }
//            .foregroundStyle(isListenDisabled ? TM.textMuted : TM.accent)
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 10)
//            .overlay {
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(isListenDisabled ? TM.border : TM.accent, lineWidth: 1)
//            }
//        }
        // Listen preview
        Button(store.isPlayingPreview ? "Arrêter" : "Écouter", systemImage: store.isPlayingPreview ? "stop.fill" : "speaker.wave.2.fill") {
            Haptic.light.trigger()
            if store.isPlayingPreview {
                store.send(.stopTTSTapped)
            } else {
                store.send(.previewTTSTapped)
            }
        }
        .secondaryButton(size: .large, width: .flexible, shape: .capsule)
        .disabled(isListenDisabled)
        .accessibilityLabel(store.isPlayingPreview ? "Arrêter la lecture" : "Écouter l'annonce")
    }

    private var messagePlaceholder: String {
        switch store.selectedType {
        case .ravito: "ex: Ravitaillement, prenez à gauche\u{2026}"
        case .danger: "ex: Attention, passage technique\u{2026}"
        case .info: "ex: Belle vue sur la vallée\u{2026}"
        case .plat: "ex: Portion plate, relancez\u{2026}"
        case .montee, .descente: "Ajouter un message personnel\u{2026}"
        }
    }

    private func typeCardsSelector(selectedType: MilestoneType) -> some View {
        HStack(spacing: 0) {
            ForEach(MilestoneType.allCases, id: \.self) { (type: MilestoneType) in
                let isSelected = selectedType == type

                Button {
                    Haptic.selection.trigger()
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                        store.send(.typeSelected(type))
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: type.systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? type.color : TM.textMuted)
                            .frame(width: 20, height: 20)

                        Text(type.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isSelected ? TM.textPrimary : TM.textMuted)
                            .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(type.color.opacity(0.12))
                                .matchedGeometryEffect(id: "typeBackground", in: typeIndicator)
                        }
                    }
                }
            }
        }
        .padding(4)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

// MARK: - Previews

private let previewAutoMessage = "Montée. 1 virgule 8 kilomètres à 12 pourcent. 215 mètres de dénivelé positif."

#Preview("Discovery — PRO") {
    Color.clear.sheet(isPresented: .constant(true)) {
        MilestoneSheetView(
            store: Store(
                initialState: {
                    var state = MilestoneSheetStore.State(
                        pointIndex: 50, latitude: 45.0641, longitude: 6.4078,
                        elevation: 2350, distance: 3500, selectedType: .montee,
                        personalMessage: "", name: "",
                        autoMessage: previewAutoMessage
                    )
                    state.$isPremium.withLock { $0 = true }
                    return state
                }()
            ) { MilestoneSheetStore() }
        )
    }
}

#Preview("Discovery — Gratuit") {
    Color.clear.sheet(isPresented: .constant(true)) {
        MilestoneSheetView(
            store: Store(
                initialState: {
                    var state = MilestoneSheetStore.State(
                        pointIndex: 50, latitude: 45.0641, longitude: 6.4078,
                        elevation: 2350, distance: 3500, selectedType: .montee,
                        personalMessage: "", name: "",
                        autoMessage: previewAutoMessage
                    )
                    state.$isPremium.withLock { $0 = false }
                    return state
                }()
            ) { MilestoneSheetStore() }
        )
    }
}

#Preview("Editing — PRO") {
    Color.clear.sheet(isPresented: .constant(true)) {
        MilestoneSheetView(
            store: Store(
                initialState: {
                    var state = MilestoneSheetStore.State(
                        pointIndex: 50, latitude: 45.0641, longitude: 6.4078,
                        elevation: 2350, distance: 3500, selectedType: .montee,
                        personalMessage: "", name: "",
                        autoMessage: previewAutoMessage,
                        useAutoAnnouncement: true,
                        step: .editing
                    )
                    state.$isPremium.withLock { $0 = true }
                    return state
                }()
            ) { MilestoneSheetStore() }
        )
    }
}

#Preview("Editing — Gratuit") {
    Color.clear.sheet(isPresented: .constant(true)) {
        MilestoneSheetView(
            store: Store(
                initialState: {
                    var state = MilestoneSheetStore.State(
                        pointIndex: 50, latitude: 45.0641, longitude: 6.4078,
                        elevation: 2350, distance: 3500, selectedType: .montee,
                        personalMessage: "", name: "",
                        autoMessage: previewAutoMessage,
                        step: .editing
                    )
                    state.$isPremium.withLock { $0 = false }
                    return state
                }()
            ) { MilestoneSheetStore() }
        )
    }
}
