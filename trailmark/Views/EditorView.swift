import SwiftUI
import ComposableArchitecture

// @Observable so wrapper views can react, but EditorView body NEVER reads .index
@Observable
final class ScrollIndexHolder {
    var index: Int = 0
}

struct EditorView: View {
    @Bindable var store: StoreOf<EditorFeature>
    @State private var scrollTarget: ScrollTarget?
    @State private var profileStatsData: ProfileStatsData?
    @State private var scrollIndexHolder = ScrollIndexHolder()
    @State private var highlightedMilestoneId: Int64?

    var body: some View {
        ZStack {
            TM.bgPrimary.ignoresSafeArea()

            if let detail = store.trailDetail {
                VStack(spacing: 0) {
                    // Mini profile overview (isolated wrapper observes scrollIndexHolder)
                    MiniProfileWrapper(
                        trackPoints: detail.trackPoints,
                        milestones: store.milestones,
                        scrollIndexHolder: scrollIndexHolder,
                        onIndexSelected: { index in
                            scrollTarget = ScrollTarget(index: index, animated: false)
                        }
                    )

                    // Scrollable profile (main) with stats overlay
                    ZStack(alignment: .top) {
                        ScrollableElevationProfileView(
                            trackPoints: detail.trackPoints,
                            milestones: store.milestones,
                            segments: detail.segments,
                            editingMilestoneId: highlightedMilestoneId,
                            statsData: profileStatsData,
                            scrollTarget: $scrollTarget,
                            onScrollIndexChanged: { [scrollIndexHolder] index in
                                scrollIndexHolder.index = index
                            },
                            onMilestoneTapped: { milestone in
                                // 1. Scroll to milestone
                                scrollTarget = ScrollTarget(index: milestone.pointIndex, animated: true)

                                Task { @MainActor in
                                    // 2. After scroll, show highlight
                                    try? await Task.sleep(for: .milliseconds(350))
                                    highlightedMilestoneId = milestone.id

                                    // 3. After highlight, open sheet
                                    try? await Task.sleep(for: .milliseconds(300))
                                    Haptic.medium.trigger()
                                    store.send(.editMilestone(milestone))
                                }
                            }
                        )

                        // Overlays (isolated wrappers — only re-render on scroll)
                        HStack {
                            StatsOverlayWrapper(
                                scrollIndexHolder: scrollIndexHolder,
                                statsData: profileStatsData
                            )

                            Spacer()

                            DistanceOverlayWrapper(
                                scrollIndexHolder: scrollIndexHolder,
                                statsData: profileStatsData
                            )
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 12)
                        .allowsHitTesting(false)

                        // Trim overlay (when segment tool is active)
                        if let trimState = store.trimState {
                            TrimOverlayView(
                                trimState: trimState,
                                trackPointCount: detail.trackPoints.count,
                                onLeftMoved: { store.send(.trimLeftMoved($0)) },
                                onRightMoved: { store.send(.trimRightMoved($0)) },
                                onValidate: { store.send(.trimValidated) },
                                onCancel: { store.send(.toolSelected(nil)) }
                            )
                        }
                    }
                    .containerRelativeFrame(.vertical) { height, _ in height * 0.5 }

                    // Milestone carousel (fills remaining space)
                    ProfileStatsWrapper(
                        scrollIndexHolder: scrollIndexHolder,
                        statsData: profileStatsData,
                        milestones: store.milestones,
                        onGoToMilestone: { milestone in
                            scrollTarget = ScrollTarget(index: milestone.pointIndex, animated: true)
                        },
                        onEditMilestone: { milestone in
                            highlightedMilestoneId = milestone.id
                            Haptic.medium.trigger()
                            store.send(.editMilestone(milestone))
                        },
                        onScrolledToMilestone: { milestone in
                            scrollTarget = ScrollTarget(index: milestone.pointIndex, animated: true)
                        }
                    )
                    .padding(.bottom, 12)

                    // Glass toolbox (bottom)
                    toolbox
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            } else {
                ProgressView()
                    .tint(TM.accent)
            }
        }
        .toolbar {
            ToolbarItem(placement: .title) {
                if let detail = store.trailDetail {
                    Text(detail.trail.name)
                }
            }
            ToolbarItem(placement: .subtitle) {
                if let detail = store.trailDetail {
                    TrailStatsView(distanceKm: detail.distKm, dPlus: detail.trail.dPlus)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Renommer", systemImage: "square.and.pencil") {
                    Haptic.light.trigger()
                    store.send(.renameButtonTapped)
                }
            }
            ToolbarSpacer(.fixed, placement: .primaryAction)
            ToolbarItem(placement: .destructiveAction) {
                Button("Supprimer", systemImage: "trash", role: .destructive) {
                    Haptic.warning.trigger()
                    store.send(.deleteTrailButtonTapped)
                }
                .tint(Color.red)
            }
        }
        .toolbarRole(.editor)
        .alert($store.scope(state: \.alert, action: \.alert))
        .alert(
            "Renommer le parcours",
            isPresented: Binding(
                get: { store.isRenamingTrail },
                set: { if !$0 { store.send(.renameCancelled) } }
            )
        ) {
            TextField("Nom du parcours", text: $store.editedTrailName)
            Button("Annuler", role: .cancel) {
                Haptic.light.trigger()
                store.send(.renameCancelled)
            }
            Button("Renommer") {
                Haptic.medium.trigger()
                store.send(.renameConfirmed)
            }
            .keyboardShortcut(.defaultAction)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: store.trailDetail?.trackPoints.count) { _, newCount in
            if let count = newCount, count > 0,
               let detail = store.trailDetail {
                profileStatsData = ProfileStatsData(trackPoints: detail.trackPoints, segments: detail.segments)
            }
        }
        .task(id: store.trailDetail?.trail.id) {
            // Compute stats data when detail becomes available
            if let detail = store.trailDetail {
                profileStatsData = ProfileStatsData(trackPoints: detail.trackPoints, segments: detail.segments)
            }
        }
        .sheet(
            item: $store.scope(state: \.milestoneSheet, action: \.milestoneSheet)
        ) { sheetStore in
            MilestoneSheetView(store: sheetStore)
                .presentationDetents([.fraction(0.5), .large])
                .presentationBackground(TM.bgCard)
                .onDisappear {
                    highlightedMilestoneId = nil
                }
        }
        .sheet(
            item: $store.scope(state: \.segmentTypeSheet, action: \.segmentTypeSheet)
        ) { sheetStore in
            SegmentTypeSheetView(store: sheetStore)
                .presentationDetents([.fraction(0.4)])
                .presentationBackground(TM.bgCard)
        }
        .fullScreenCover(
            item: $store.scope(state: \.paywall, action: \.paywall)
        ) { paywallStore in
            PaywallContainerView(store: paywallStore)
        }
    }


    // MARK: - Glass Toolbox

    private var toolbox: some View {
        HStack(spacing: 0) {
            // Segment tool
            toolButton(
                icon: "waveform.path.ecg",
                label: "Segment",
                isActive: store.activeTool == .segment
            ) {
                Haptic.medium.trigger()
                if store.activeTool == .segment {
                    store.send(.toolSelected(nil))
                } else {
                    store.send(.toolSelected(.segment))
                }
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 2)

            // Repere tool
            toolButton(
                icon: "mappin.and.ellipse",
                label: "Repere",
                isActive: store.activeTool == .repere
            ) {
                Haptic.medium.trigger()
                store.send(.profileTapped(scrollIndexHolder.index))
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 2)

            // Auto PRO tool
            Button {
                Haptic.medium.trigger()
                store.send(.autoDetectTapped)
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(store.activeTool == nil ? Color.white.opacity(0.7) : Color.white.opacity(0.35))
                    HStack(spacing: 2) {
                        Text("Auto")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.5))
                        Text("PRO")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(TM.accent, in: RoundedRectangle(cornerRadius: 3))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(8)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func toolButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? TM.accent : Color.white.opacity(0.7))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isActive ? TM.accent : Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(TM.accent.opacity(0.15))
                }
            }
        }
    }
}

// MARK: - Milestone Sheet View

struct MilestoneSheetView: View {
    @Bindable var store: StoreOf<MilestoneSheetFeature>
    @Namespace private var typeIndicator

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Type selector (horizontal cards from Approach 3)
                    sectionLabel("TYPE")

                    typeCardsSelector(selectedType: store.selectedType)
                        .padding(.top, 8)

                    // MARK: - Message Section (conditional layout)
                    if let autoMessage = store.autoMessage {
                        // montee/descente: auto block + personal complement
                        HStack(spacing: 6) {
                            sectionLabel("ANNONCE VOCALE")
                            proBadge
                        }
                        .padding(.top, 14)

                        // Auto-generated text block (read-only)
                        Text(autoMessage)
                            .font(.body)
                            .foregroundStyle(TM.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(TM.bgSecondary, in: RoundedRectangle(cornerRadius: 10))
                            .opacity(store.isPremium ? 1 : 0.7)
                            .padding(.top, 8)

                        sectionLabel("COMPLEMENT PERSO")
                            .padding(.top, 14)

                        TextField(
                            "Ajouter un message personnel\u{2026}",
                            text: $store.personalMessage,
                            axis: .vertical
                        )
                        .lineLimit(3...5)
                        .font(.body)
                        .foregroundStyle(TM.textPrimary)
                        .padding(12)
                        .background(TM.bgPrimary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(TM.border, lineWidth: 1)
                        )
                        .padding(.top, 8)
                    } else {
                        // Non montee/descente: plain message field
                        sectionLabel("MESSAGE TTS")
                            .padding(.top, 14)

                        TextField(
                            messagePlaceholder,
                            text: $store.personalMessage,
                            axis: .vertical
                        )
                        .lineLimit(3...5)
                        .font(.body)
                        .foregroundStyle(TM.textPrimary)
                        .padding(12)
                        .background(TM.bgPrimary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(TM.border, lineWidth: 1)
                        )
                        .padding(.top, 8)
                    }

                    // Full-width listen button
                    listenButton
                        .padding(.top, 12)

                    // Name
                    sectionLabel("NOM (OPTIONNEL)")
                        .padding(.top, 14)

                    TextField("ex: Col de la Croix", text: $store.name)
                        .font(.body)
                        .foregroundStyle(TM.textPrimary)
                        .padding(12)
                        .background(TM.bgPrimary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(TM.border, lineWidth: 1)
                        )
                        .padding(.top, 8)

                }
                .padding(20)
            }
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

    // MARK: - Section Label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .tracking(1)
            .foregroundStyle(TM.textMuted)
    }

    // MARK: - PRO Badge

    private var proBadge: some View {
        HStack(spacing: 4) {
            if !store.isPremium {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.black)
            }
            Text("PRO")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(TM.accent, in: RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Listen Button

    private var isListenDisabled: Bool {
        (store.autoMessage ?? "").isEmpty && store.personalMessage.isEmpty
    }

    private var listenButton: some View {
        Button {
            Haptic.light.trigger()
            if store.isPlayingPreview {
                store.send(.stopTTSTapped)
            } else {
                store.send(.previewTTSTapped)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: store.isPlayingPreview ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text(store.isPlayingPreview ? "Arrêter" : "Écouter l'annonce")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isListenDisabled ? TM.textMuted : TM.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isListenDisabled ? TM.border : TM.accent, lineWidth: 1)
            )
        }
        .disabled(isListenDisabled)
        .accessibilityLabel(store.isPlayingPreview ? "Arrêter la lecture" : "Écouter l'annonce")
    }

    // MARK: - Message Placeholder

    private var messagePlaceholder: String {
        switch store.selectedType {
        case .ravito: "ex: Ravitaillement, prenez à gauche\u{2026}"
        case .danger: "ex: Attention, passage technique\u{2026}"
        case .info: "ex: Belle vue sur la vallée\u{2026}"
        case .plat: "ex: Portion plate, relancez\u{2026}"
        case .montee, .descente: "Ajouter un message personnel\u{2026}"
        }
    }

    // MARK: - Type Selector

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

// MARK: - Trim Overlay View

private struct TrimOverlayView: View {
    let trimState: TrimState
    let trackPointCount: Int
    let onLeftMoved: (Int) -> Void
    let onRightMoved: (Int) -> Void
    let onValidate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let leftFrac = trackPointCount > 1 ? CGFloat(trimState.leftIndex) / CGFloat(trackPointCount - 1) : 0
            let rightFrac = trackPointCount > 1 ? CGFloat(trimState.rightIndex) / CGFloat(trackPointCount - 1) : 1

            ZStack {
                // Dimmed left zone
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: leftFrac * totalWidth)
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .allowsHitTesting(false)

                // Dimmed right zone
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: (1 - rightFrac) * totalWidth)
                    .frame(maxHeight: .infinity, alignment: .trailing)
                    .allowsHitTesting(false)

                // Left handle
                TrimHandle()
                    .position(x: leftFrac * totalWidth, y: geo.size.height / 2)
                    .gesture(DragGesture().onChanged { value in
                        let newFrac = max(0, min(1, value.location.x / totalWidth))
                        let newIndex = Int(newFrac * CGFloat(trackPointCount - 1))
                        onLeftMoved(newIndex)
                    })

                // Right handle
                TrimHandle()
                    .position(x: rightFrac * totalWidth, y: geo.size.height / 2)
                    .gesture(DragGesture().onChanged { value in
                        let newFrac = max(0, min(1, value.location.x / totalWidth))
                        let newIndex = Int(newFrac * CGFloat(trackPointCount - 1))
                        onRightMoved(newIndex)
                    })

                // Validate button (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            Haptic.success.trigger()
                            onValidate()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.green.opacity(0.4), radius: 8)
                        }
                        .padding(12)
                    }
                }
            }
        }
    }
}

private struct TrimHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(TM.accent)
            .frame(width: 8, height: 60)
            .overlay {
                VStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 1, height: 12)
                    }
                }
            }
    }
}

// MARK: - Segment Type Sheet View

struct SegmentTypeSheetView: View {
    @Bindable var store: StoreOf<SegmentTypeSheetFeature>

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Type selector
                Text("TYPE DE SEGMENT")
                    .font(.caption2.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(TM.textMuted)
                    .padding(.top, 20)

                HStack(spacing: 8) {
                    ForEach(SegmentType.allCases, id: \.self) { type in
                        segmentTypeCard(type: type, isSelected: store.selectedType == type)
                    }
                }
                .padding(.top, 8)

                // Stats row
                HStack(spacing: 16) {
                    statLabel(AnnouncementBuilder.formatDistance(store.stats.distance))
                    statLabel("D+ \(Int(store.stats.elevationGain))m")
                    statLabel("\(Int((abs(store.stats.averageSlope) * 100).rounded()))%")
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TM.bgSecondary, in: RoundedRectangle(cornerRadius: 10))
                .padding(.top, 14)

                // Add milestone toggle
                Toggle(isOn: $store.addMilestone) {
                    Text("Ajouter un repere au debut")
                        .font(.body)
                        .foregroundStyle(TM.textPrimary)
                }
                .tint(TM.accent)
                .padding(.top, 14)

                Spacer()

                // CTA
                Button {
                    Haptic.success.trigger()
                    store.send(.saveButtonTapped)
                } label: {
                    Text("Valider le segment")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(TM.accent, in: Capsule())
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer", systemImage: "xmark", role: .cancel) {
                        Haptic.light.trigger()
                        store.send(.dismissTapped)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(store.isEditing ? "Modifier le segment" : "Nouveau segment")
                        .font(.headline)
                }
                if store.isEditing {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Supprimer", systemImage: "trash", role: .destructive) {
                            Haptic.warning.trigger()
                            store.send(.deleteButtonTapped)
                        }
                        .tint(TM.danger)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func segmentTypeCard(type: SegmentType, isSelected: Bool) -> some View {
        Button {
            Haptic.selection.trigger()
            store.send(.typeSelected(type))
        } label: {
            VStack(spacing: 4) {
                Image(systemName: type.milestoneType.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSelected ? type.milestoneType.color : TM.textMuted)
                Text(type.milestoneType.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? TM.textPrimary : TM.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(type.milestoneType.color.opacity(0.12))
                }
            }
        }
    }

    private func statLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .monospaced, weight: .bold))
            .foregroundStyle(TM.textSecondary)
    }
}

// MARK: - Preview Helpers
 
@MainActor
private enum PreviewData {
    /// Charge les points depuis le GPX bundlé (preview-trail.gpx)
    static var trackPoints: [TrackPoint] {
        do {
            let (parsedPoints, _) = try GPXParser.parseFromBundle(resource: "gpx_preview")
            return parsedPoints.enumerated().map { index, point in
                TrackPoint(
                    id: Int64(index + 1),
                    trailId: 1,
                    index: index,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    elevation: point.elevation,
                    distance: point.distance
                )
            }
        } catch {
            print("Preview GPX load failed: \(error)")
            return []
        }
    }

    static var trail: Trail {
        let points = trackPoints
        let distance = points.last?.distance ?? 0
        let dPlus = calculateDPlus(points: points)
        return Trail(
            id: 1,
            name: "Thou Verdun",
            createdAt: Date(),
            distance: distance,
            dPlus: dPlus
        )
    }

    private static func calculateDPlus(points: [TrackPoint]) -> Int {
        var dPlus = 0.0
        for i in 1..<points.count {
            let delta = points[i].elevation - points[i-1].elevation
            if delta > 0 { dPlus += delta }
        }
        return Int(dPlus)
    }

    static func milestones(from points: [TrackPoint]) -> [Milestone] {
        guard points.count > 500 else { return [] }
        return [
            Milestone(
                id: 1,
                trailId: 1,
                pointIndex: 200,
                latitude: points[200].latitude,
                longitude: points[200].longitude,
                elevation: points[200].elevation,
                distance: points[200].distance,
                type: .montee,
                message: "Début de la montée vers le Mont Thou",
                name: "Montée Thou"
            ),
            Milestone(
                id: 2,
                trailId: 1,
                pointIndex: 500,
                latitude: points[500].latitude,
                longitude: points[500].longitude,
                elevation: points[500].elevation,
                distance: points[500].distance,
                type: .info,
                message: "Sommet du Mont Thou, belle vue !",
                name: "Mont Thou"
            ),
        ]
    }

    static var trailDetail: TrailDetail {
        let points = trackPoints
        return TrailDetail(
            trail: trail,
            trackPoints: points,
            milestones: milestones(from: points)
        )
    }
}

private struct EditorPreviewWrapper: View {
    let milestones: [Milestone]

    var body: some View {
        NavigationStack {
            Color.clear
                .navigationDestination(isPresented: .constant(true)) {
                    let points = PreviewData.trackPoints
                    let ms = milestones.isEmpty ? [] : PreviewData.milestones(from: points)

                    EditorView(
                        store: Store(
                            initialState: {
                                var state = EditorFeature.State(trailId: 1)
                                state.trailDetail = TrailDetail(
                                    trail: PreviewData.trail,
                                    trackPoints: points,
                                    milestones: ms
                                )
                                state.milestones = ms
                                state.originalMilestones = ms
                                return state
                            }()
                        ) {
                            EditorFeature()
                        }
                    )
                }
        }
    }
}

#Preview("Editor - With Milestones") {
    EditorPreviewWrapper(milestones: PreviewData.milestones(from: PreviewData.trackPoints))
}

// MARK: - Isolated Wrapper Views (observe ScrollIndexHolder, NOT EditorView)

/// Only this view re-renders when scrollIndexHolder.index changes.
private struct MiniProfileWrapper: View {
    let trackPoints: [TrackPoint]
    let milestones: [Milestone]
    let scrollIndexHolder: ScrollIndexHolder
    let onIndexSelected: (Int) -> Void

    var body: some View {
        MiniProfileView(
            trackPoints: trackPoints,
            milestones: milestones,
            currentIndex: scrollIndexHolder.index,
            onIndexSelected: onIndexSelected
        )
    }
}

/// Only this view re-renders when scrollIndexHolder.index changes.
/// EditorView body is NOT re-evaluated.
private struct StatsOverlayWrapper: View {
    let scrollIndexHolder: ScrollIndexHolder
    let statsData: ProfileStatsData?

    var body: some View {
        if let stats = statsData,
           scrollIndexHolder.index < stats.trackPoints.count {
            ElevationStatsOverlay(
                dPlus: stats.cumulativeDPlus[scrollIndexHolder.index],
                dMinus: stats.cumulativeDMinus[scrollIndexHolder.index]
            )
        }
    }
}

private struct DistanceOverlayWrapper: View {
    let scrollIndexHolder: ScrollIndexHolder
    let statsData: ProfileStatsData?

    var body: some View {
        if let stats = statsData,
           scrollIndexHolder.index < stats.trackPoints.count {
            let point = stats.trackPoints[scrollIndexHolder.index]
            HStack(spacing: 8) {
                DistanceView(meters: point.distance)

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 0.5, height: 16)

                HStack(spacing: 4) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(TM.textTertiary)
                    Text("\(Int(point.elevation))")
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .foregroundStyle(TM.textSecondary)
                    Text("M")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(TM.textTertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: .capsule)
        }
    }
}

/// Only this view re-renders when scrollIndexHolder.index changes.
private struct ProfileStatsWrapper: View {
    let scrollIndexHolder: ScrollIndexHolder
    let statsData: ProfileStatsData?
    let milestones: [Milestone]
    var onGoToMilestone: ((Milestone) -> Void)?
    var onEditMilestone: ((Milestone) -> Void)?
    var onScrolledToMilestone: ((Milestone) -> Void)?

    var body: some View {
        if let stats = statsData,
           scrollIndexHolder.index < stats.trackPoints.count {
            ProfileStatsView(
                statsData: stats,
                currentIndex: scrollIndexHolder.index,
                milestones: milestones,
                onGoToMilestone: onGoToMilestone,
                onEditMilestone: onEditMilestone,
                onScrolledToMilestone: onScrolledToMilestone
            )
        }
    }
}

#Preview("Editor - Empty Milestones") {
    EditorPreviewWrapper(milestones: [])
}

#Preview("Milestone Sheet") {
    MilestoneSheetView(
        store: Store(
            initialState: MilestoneSheetFeature.State(
                editingMilestone: nil,
                pointIndex: 50,
                latitude: 45.0641,
                longitude: 6.4078,
                elevation: 2350,
                distance: 3500,
                selectedType: .montee,
                personalMessage: "",
                name: "",
                autoMessage: "Montée. 1 virgule 8 kilomètres à 12 pourcent. 215 mètres de dénivelé positif."
            )
        ) {
            MilestoneSheetFeature()
        }
    )
    .presentationBackground(TM.bgCard)
}
