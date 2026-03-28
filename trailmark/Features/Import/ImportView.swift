import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

struct ImportView: View {
    @Bindable var store: StoreOf<ImportStore>
    @State private var animationToken = UUID()
    @State private var pillsExiting = false
    @State private var uploadContentFading = false
    @State private var showProfileView = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [TM.accent.opacity(0.08), TM.bgSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if showProfileView {
                    profileResultView
                } else {
                    uploadPhaseView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if store.phase != .animatingProfile {
                        Button("common.close", systemImage: "xmark", role: .cancel) {
                            Haptic.light.trigger()
                            store.send(.dismissTapped)
                        }
                    }
                }
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(store.phase == .analyzing)
        .fileImporter(
            isPresented: Binding(
                get: { store.isShowingFilePicker },
                set: { newValue in
                    if !newValue {
                        store.send(.filePickerDismissed)
                    }
                }
            ),
            allowedContentTypes: gpxContentTypes,
            onCompletion: { result in
                switch result {
                case .success(let url):
                    store.send(.fileSelected(url.path))
                case .failure:
                    store.send(.filePickerDismissed)
                }
            }
        )
        .fullScreenCover(
            item: $store.scope(state: \.paywall, action: \.paywall)
        ) { paywallStore in
            PaywallContainerView(store: paywallStore)
        }
    }

    // MARK: - Upload Phase

    private var uploadPhaseView: some View {
        VStack(spacing: 0) {
            // Pills en haut
            trailPillsView
                .padding(.top, 16)

            // Texte centré
            VStack(spacing: 8) {
                // Titre — disparaît en fondu
                Text("import.upload.title")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TM.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(uploadContentFading ? 0 : 1)

                // Sous-titre — se transforme en texte de loading
                Text(uploadContentFading ? "import.phase.creatingProfile" : "import.upload.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(TM.textMuted)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())

                // Error message
                if let error = store.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(TM.danger)
                        .padding(.top, 4)
                }
            }
            .padding(.top, 28)
            .padding(.horizontal, 28)

            Spacer()

            // CTA en bas — disparaît en fondu
            Button {
                Haptic.medium.trigger()
                store.send(.uploadZoneTapped)
            } label: {
                Text("import.upload.cta")
                    .opacity(store.phase == .analyzing ? 0 : 1)
                    .overlay {
                        if store.phase == .analyzing {
                            ProgressView()
                        }
                    }
            }
            .primaryButton(size: .large, width: .flexible, shape: .capsule)
            .disabled(store.phase == .analyzing)
            .padding(.horizontal, 24)
            .opacity(uploadContentFading ? 0 : 1)

            Text("import.upload.sources")
                .font(.caption)
                .foregroundStyle(TM.textMuted)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .opacity(uploadContentFading ? 0 : 1)

            #if DEBUG
            if !uploadContentFading {
                Button {
                    startUploadExitAnimation()
                } label: {
                    Label("Test exit animation", systemImage: "arrow.right.to.line")
                        .font(.caption)
                }
                .tertiaryButton(size: .mini, tint: TM.textMuted)
                .padding(.bottom, 8)
            }
            #endif
        }
        .animation(.easeInOut(duration: 0.4), value: uploadContentFading)
        .onChange(of: store.phase) { _, newPhase in
            if newPhase == .animatingProfile {
                startUploadExitAnimation()
            }
        }
    }

    private func startUploadExitAnimation() {
        // Step 1: pills accelerate and exit
        pillsExiting = true

        // Step 2: after pills start moving, fade out title/button + transform subtitle
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            uploadContentFading = true

            // Step 3: after everything is gone, show profile
            try? await Task.sleep(for: .milliseconds(600))
            showProfileView = true

            // Reset for potential re-use
            pillsExiting = false
            uploadContentFading = false
        }
    }

    // MARK: - Trail Pills

    private static let trailNames: [[String]] = [
        ["UTMB", "Tour du Mont Blanc", "Diagonale des Fous", "CCC", "Échappée Belle"],
        ["Western States", "Tor des Géants", "SaintéLyon", "Templiers", "Pikes Peak"],
        ["Lavaredo", "Transgrancanaria", "Hardrock 100", "Eiger Ultra Trail", "GR20"],
        ["Cape Town Ultra", "Trail du Ventoux", "Oman by UTMB", "Patagonia Run", "MiUT"],
    ]

    private static let pillConfigs: [(reversed: Bool, duration: Double, startOffset: CGFloat)] = [
        (false, 25, 0),
        (true, 32, -60),
        (false, 28, -120),
        (true, 26, -40),
    ]

    private var trailPillsView: some View {
        VStack(spacing: 8) {
            ForEach(Array(Self.trailNames.enumerated()), id: \.offset) { index, row in
                let config = Self.pillConfigs[index]
                ScrollingPillRow(
                    names: row,
                    reversed: config.reversed,
                    duration: config.duration,
                    startOffset: config.startOffset,
                    exiting: pillsExiting
                )
            }
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.1),
                    .init(color: .black, location: 0.9),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Importing Phase

    private var analyzingPhaseView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .tint(TM.accent)

            Text("import.phase.importing")
                .font(.subheadline)
                .foregroundStyle(TM.textMuted)

            Spacer()
        }
    }

    // MARK: - Unified Profile + Result View

    private var isResult: Bool { store.phase == .result }

    private var hasMilestones: Bool {
        !store.detectedMilestones.isEmpty
    }

    /// Phases for the profile → result transition animation
    private enum ResultTransitionPhase: CaseIterable {
        case idle       // Profile drawing in progress
        case segments   // Colored segments fade in, analyzing text fades out
        case milestones // Milestones appear one by one
        case complete   // Header, buttons, explanation appear
    }

    @State private var transitionPhase: ResultTransitionPhase = .idle
    @State private var visibleMilestoneCount: Int = 0

    private var profileResultView: some View {
        let showSegments = transitionPhase != .idle
        let showMilestones = transitionPhase == .milestones || transitionPhase == .complete
        let showContent = transitionPhase == .complete

        return VStack(spacing: 0) {
            // Header — fades in during .complete
            resultHeader
                .padding(.top, 24)
                .padding(.horizontal, 20)
                .opacity(showContent ? 1 : 0)

            // Profile — just below header
            ZStack(alignment: .topTrailing) {
                // Layer 1: Drawing animation (accent color)
                RealProfileDrawingAnimation(
                    trackPoints: store.parsedTrackPoints,
                    onFinished: {
                        store.send(.profileAnimationFinished)
                    },
                    restartToken: animationToken
                )
                .frame(height: 150)
                .opacity(transitionPhase == .idle ? 1 : 0)

                // Layer 2: Colored profile WITHOUT milestones
                ElevationProfilePreview(
                    trackPoints: store.parsedTrackPoints,
                    milestones: [],
                    showMilestones: false
                )
                .frame(height: 150)
                .opacity(showSegments ? 1 : 0)

                // Layer 3: SwiftUI milestone markers (animated individually)
                if showMilestones {
                    MilestoneMarkersOverlay(
                        trackPoints: store.parsedTrackPoints,
                        milestones: store.detectedMilestones,
                        visibleCount: visibleMilestoneCount
                    )
                    .frame(height: 150)
                }

                if !store.isPremium && hasMilestones {
                    ProBadge()
                        .padding(8)
                        .opacity(showContent ? 1 : 0)
                }
            }
            .background(transitionPhase == .idle ? .clear : TM.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Phase text — changes at each step
            Group {
                switch transitionPhase {
                case .idle:
                    Text("import.phase.creatingProfile")
                case .segments, .milestones:
                    Text("import.phase.detectingMilestones")
                case .complete:
                    if hasMilestones {
                        Text("import.result.explanation")
                    } else {
                        Color.clear.frame(height: 0)
                    }
                }
            }
            .font(.subheadline)
            .foregroundStyle(TM.textMuted)
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.3), value: transitionPhase)

            Spacer()

            // Action buttons — fades in during .complete
            actionButtons
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

            #if DEBUG
            Button {
                transitionPhase = .idle
                visibleMilestoneCount = 0
                store.send(.debugReplayAnimation)
                animationToken = UUID()
            } label: {
                Label("Replay", systemImage: "arrow.counterclockwise")
                    .font(.caption)
            }
            .tertiaryButton(size: .mini, tint: TM.textMuted)
            .padding(.bottom, 8)
            .opacity(showContent ? 1 : 0)
            #endif
        }
        .onChange(of: isResult) { _, newValue in
            if newValue {
                startResultTransition()
            } else {
                transitionPhase = .idle
                visibleMilestoneCount = 0
                milestoneAnimationStartDate = nil
            }
        }
        // TimelineView-driven milestone counter (frame-synced)
        .overlay {
            if transitionPhase == .milestones, let startDate = milestoneAnimationStartDate {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    let progress = min(elapsed / totalMilestoneDuration, 1.0)
                    let eased = 0.5 * (1 - cos(Double.pi * progress))
                    let targetCount = Int(eased * Double(store.detectedMilestones.count))

                    Color.clear
                        .onChange(of: targetCount) { oldCount, newCount in
                            if newCount > visibleMilestoneCount {
                                visibleMilestoneCount = newCount
                                Haptic.light.trigger()
                            }
                        }
                        .onChange(of: progress >= 1.0) { _, finished in
                            if finished {
                                visibleMilestoneCount = store.detectedMilestones.count
                                milestoneAnimationStartDate = nil
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    transitionPhase = .complete
                                }
                            }
                        }
                }
            }
        }
    }

    @State private var milestoneAnimationStartDate: Date?
    private let totalMilestoneDuration: Double = 1.5

    private func startResultTransition() {
        let milestoneCount = store.detectedMilestones.count

        // Phase 1: colored segments appear, analyzing text fades
        withAnimation(.easeInOut(duration: 0.6)) {
            transitionPhase = .segments
        }

        if milestoneCount > 0 {
            // Phase 2: start milestone animation after segments settle
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                transitionPhase = .milestones
                milestoneAnimationStartDate = Date()
            }
        } else {
            // No milestones — skip to complete
            withAnimation(.easeInOut(duration: 0.5).delay(0.7)) {
                transitionPhase = .complete
            }
        }
    }

    private var resultHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(TM.accent)

            VStack(alignment: .leading, spacing: 4) {
                if hasMilestones {
                    Text("import.result.foundMilestones \(store.detectedMilestones.count)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TM.textPrimary)
                } else {
                    Text("import.result.imported")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TM.textPrimary)
                }

                if let trail = store.parsedTrail {
                    Text(trail.name)
                        .font(.subheadline)
                        .foregroundStyle(TM.textMuted)

                    HStack(spacing: 12) {
                        Text(String(format: "%.1f km", trail.distance / 1000))
                        Text("D+ \(trail.dPlus)m")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(TM.textMuted)
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if !hasMilestones {
            Button {
                Haptic.medium.trigger()
                store.send(.skipTapped)
            } label: {
                Text("common.continue")
            }
            .primaryButton(size: .large, width: .flexible, shape: .capsule)
        } else if store.isPremium {
            VStack(spacing: 12) {
                Button {
                    Haptic.medium.trigger()
                    store.send(.continueWithMilestonesTapped)
                } label: {
                    Text("common.continue")
                }
                .primaryButton(size: .large, width: .flexible, shape: .capsule)

                Button {
                    Haptic.light.trigger()
                    store.send(.skipTapped)
                } label: {
                    Text("import.result.skipButton")
                        .underline()
                }
                .tertiaryButton(size: .small, tint: .secondary)
            }
        } else {
            VStack(spacing: 12) {
                Button {
                    Haptic.medium.trigger()
                    store.send(.unlockTapped)
                } label: {
                    Label {
                        Text("import.result.unlockDetection")
                    } icon: {
                        Image(systemName: "lock.fill")
                    }
                }
                .primaryButton(size: .large, width: .flexible, shape: .capsule)

                Button {
                    Haptic.light.trigger()
                    store.send(.skipTapped)
                } label: {
                    Text("import.result.manualButton")
                        .underline()
                }
                .tertiaryButton(size: .small, tint: .secondary)
            }
        }
    }

    // MARK: - Content Types

    private var gpxContentTypes: [UTType] {
        var types: [UTType] = [.xml]
        if let gpxType = UTType(filenameExtension: "gpx") {
            types.insert(gpxType, at: 0)
        }
        return types
    }
}

// MARK: - Elevation Profile Preview (simplified, non-interactive)

// MARK: - Scrolling Pill Row

private struct ScrollingPillRow: View {
    let names: [String]
    let reversed: Bool
    let duration: Double
    let startOffset: CGFloat
    var exiting: Bool = false

    @State private var contentWidth: CGFloat = 0
    @State private var exitStartTime: Date?
    @State private var exitBaseOffset: CGFloat = 0

    private let exitDuration: Double = 1.5

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                HStack(spacing: 8) {
                    pillContent
                    pillContent
                }
                .fixedSize()
                .offset(x: computeShift(at: timeline.date, containerWidth: geo.size.width))
            }
        }
        .frame(height: 40)
        .clipped()
        .onChange(of: exiting) { _, isExiting in
            if isExiting {
                let time = Date().timeIntervalSinceReferenceDate
                let progress = CGFloat(time.truncatingRemainder(dividingBy: duration)) / CGFloat(duration)
                exitBaseOffset = reversed
                    ? -contentWidth + progress * contentWidth + startOffset
                    : startOffset - progress * contentWidth
                exitStartTime = Date()
            } else {
                exitStartTime = nil
            }
        }
    }

    private func computeShift(at date: Date, containerWidth: CGFloat) -> CGFloat {
        if let exitStart = exitStartTime {
            let elapsed = CGFloat(date.timeIntervalSince(exitStart))
            let progress = min(elapsed / CGFloat(exitDuration), 1.0)
            // Exponential ease-in: very slow at start, very fast at end
            let eased = pow(progress, 5)
            let exitDistance = (containerWidth + contentWidth * 2) * (reversed ? 1 : -1)
            return exitBaseOffset + eased * exitDistance
        } else {
            let time = date.timeIntervalSinceReferenceDate
            let progress = CGFloat(time.truncatingRemainder(dividingBy: duration)) / CGFloat(duration)
            return reversed
                ? -contentWidth + progress * contentWidth + startOffset
                : startOffset - progress * contentWidth
        }
    }

    private var pillContent: some View {
        HStack(spacing: 8) {
            ForEach(Array(names.enumerated()), id: \.offset) { _, name in
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(TM.textPrimary.opacity(0.2))
                    .fixedSize()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(TM.accent.opacity(0.05), in: Capsule())
                    .overlay(Capsule().strokeBorder(TM.accent.opacity(0.08), lineWidth: 1))
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    contentWidth = geo.size.width + 8
                }
            }
        )
    }
}

// MARK: - Profile Drawing Animation

private struct ProfileDrawingAnimation: View {
    // Elevation profile shape as normalized points (x: 0...1, y: 0...1 where 0=top)
    private static let profilePoints: [(CGFloat, CGFloat)] = [
        (0.00, 0.75), (0.04, 0.72), (0.08, 0.68), (0.12, 0.60),
        (0.16, 0.48), (0.20, 0.38), (0.24, 0.30), (0.28, 0.22),
        (0.32, 0.18), (0.36, 0.20), (0.40, 0.28), (0.44, 0.35),
        (0.48, 0.42), (0.52, 0.38), (0.56, 0.30), (0.60, 0.20),
        (0.64, 0.15), (0.68, 0.12), (0.72, 0.18), (0.76, 0.28),
        (0.80, 0.40), (0.84, 0.50), (0.88, 0.55), (0.92, 0.60),
        (0.96, 0.65), (1.00, 0.70),
    ]

    private let cycleDuration: Double = 6

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let progress = CGFloat(time.truncatingRemainder(dividingBy: cycleDuration)) / CGFloat(cycleDuration)

            Canvas { context, size in
                drawProfile(context: context, size: size, progress: progress)
            }
        }
    }

    private func drawProfile(context: GraphicsContext, size: CGSize, progress: CGFloat) {
        let points = Self.profilePoints.map { p in
            CGPoint(x: p.0 * size.width, y: p.1 * size.height)
        }

        let cursorX = progress * size.width
        let trailLength: CGFloat = size.width * 0.5

        guard points.count >= 2 else { return }

        for i in 1..<points.count {
            let p0 = points[i - 1]
            let p1 = points[i]

            guard p0.x <= cursorX else { break }

            let clippedEnd: CGPoint
            if p1.x <= cursorX {
                clippedEnd = p1
            } else {
                let t = (cursorX - p0.x) / (p1.x - p0.x)
                clippedEnd = CGPoint(x: cursorX, y: p0.y + t * (p1.y - p0.y))
            }

            let segmentMidX = (p0.x + clippedEnd.x) / 2
            let distFromCursor = cursorX - segmentMidX
            let opacity: Double
            if distFromCursor < trailLength * 0.3 {
                opacity = 1.0
            } else if distFromCursor < trailLength {
                opacity = Double(1.0 - (distFromCursor - trailLength * 0.3) / (trailLength * 0.7))
            } else {
                opacity = 0
            }

            guard opacity > 0 else { continue }

            var segmentPath = Path()
            segmentPath.move(to: p0)
            segmentPath.addLine(to: clippedEnd)

            context.stroke(
                segmentPath,
                with: .color(TM.accent.opacity(opacity)),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }

        // Cursor glow
        let cursorY = interpolateY(at: progress, points: Self.profilePoints) * size.height

        let glowRect = CGRect(x: cursorX - 8, y: cursorY - 8, width: 16, height: 16)
        context.fill(Path(ellipseIn: glowRect), with: .color(TM.accent.opacity(0.2)))

        let dotRect = CGRect(x: cursorX - 4, y: cursorY - 4, width: 8, height: 8)
        context.fill(Path(ellipseIn: dotRect), with: .color(TM.accent))
    }

    private func interpolateY(at progress: CGFloat, points: [(CGFloat, CGFloat)]) -> CGFloat {
        let clamped = min(max(progress, 0), 1)
        guard let lastPoint = points.last, let firstPoint = points.first else { return 0.5 }
        if clamped <= firstPoint.0 { return firstPoint.1 }
        if clamped >= lastPoint.0 { return lastPoint.1 }

        for i in 1..<points.count {
            if points[i].0 >= clamped {
                let p0 = points[i - 1]
                let p1 = points[i]
                let t = (clamped - p0.0) / (p1.0 - p0.0)
                return p0.1 + t * (p1.1 - p0.1)
            }
        }
        return lastPoint.1
    }
}

// MARK: - Real Profile Drawing Animation

private struct RealProfileDrawingAnimation: View {
    let trackPoints: [TrackPoint]
    let onFinished: () -> Void

    private let animationDuration: Double = 3.5
    @State private var startTime: Date?
    @State private var hasFinished = false
    var restartToken: UUID = UUID()

    var body: some View {
        TimelineView(.animation) { timeline in
            let progress = currentProgress(at: timeline.date)

            Canvas { context, size in
                drawRealProfile(context: context, size: size, progress: progress)
            }
            .task(id: progress >= 1.0) {
                if progress >= 1.0 && !hasFinished {
                    hasFinished = true
                    onFinished()
                }
            }
        }
        .onAppear {
            startTime = Date()
        }
        .onChange(of: restartToken) {
            startTime = Date()
            hasFinished = false
        }
    }

    private func currentProgress(at date: Date) -> CGFloat {
        guard let start = startTime else { return 0 }
        let elapsed = date.timeIntervalSince(start)
        return min(CGFloat(elapsed / animationDuration), 1.0)
    }

    private func drawRealProfile(context: GraphicsContext, size: CGSize, progress: CGFloat) {
        guard trackPoints.count >= 2 else { return }

        let padding: CGFloat = 10
        let plotRect = CGRect(
            x: padding, y: padding,
            width: size.width - padding * 2,
            height: size.height - padding * 2
        )

        let elevations = trackPoints.map(\.elevation)
        let minEle = elevations.min() ?? 0
        let maxEle = elevations.max() ?? 0
        let eleRange = max(maxEle - minEle, 1)
        let maxDist = trackPoints.last?.distance ?? 1

        // Downsample for performance (max ~200 points)
        let step = max(1, trackPoints.count / 200)
        let sampled = stride(from: 0, to: trackPoints.count, by: step).map { trackPoints[$0] }

        let points = sampled.map { pt -> CGPoint in
            let x = plotRect.minX + CGFloat(pt.distance / maxDist) * plotRect.width
            let y = plotRect.maxY - CGFloat((pt.elevation - minEle) / eleRange) * plotRect.height
            return CGPoint(x: x, y: y)
        }

        let cursorX = plotRect.minX + progress * plotRect.width

        // Draw segments in accent color
        for i in 1..<points.count {
            let p0 = points[i - 1]
            let p1 = points[i]

            guard p0.x <= cursorX else { break }

            let clippedEnd: CGPoint
            if p1.x <= cursorX {
                clippedEnd = p1
            } else {
                let t = (cursorX - p0.x) / (p1.x - p0.x)
                clippedEnd = CGPoint(x: cursorX, y: p0.y + t * (p1.y - p0.y))
            }

            // Fill under the segment
            var fillPath = Path()
            fillPath.move(to: CGPoint(x: p0.x, y: plotRect.maxY))
            fillPath.addLine(to: p0)
            fillPath.addLine(to: clippedEnd)
            fillPath.addLine(to: CGPoint(x: clippedEnd.x, y: plotRect.maxY))
            fillPath.closeSubpath()
            context.fill(fillPath, with: .color(TM.accent.opacity(0.1)))

            // Line
            var linePath = Path()
            linePath.move(to: p0)
            linePath.addLine(to: clippedEnd)
            context.stroke(
                linePath,
                with: .color(TM.accent),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
        }

        // Cursor glow (only while animating)
        if progress < 1.0 {
            let cursorY: CGFloat
            if let lastVisible = points.last(where: { $0.x <= cursorX }) {
                cursorY = lastVisible.y
            } else {
                cursorY = plotRect.midY
            }

            let glowRect = CGRect(x: cursorX - 10, y: cursorY - 10, width: 20, height: 20)
            context.fill(Path(ellipseIn: glowRect), with: .color(TM.accent.opacity(0.25)))

            let dotRect = CGRect(x: cursorX - 4, y: cursorY - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: dotRect), with: .color(TM.accent))
        }
    }
}

// MARK: - Elevation Profile Preview

private struct ElevationProfilePreview: View {
    let trackPoints: [TrackPoint]
    let milestones: [Milestone]
    var showMilestones: Bool = true

    private let paddingTop: CGFloat = 10
    private let paddingBottom: CGFloat = 10
    private let paddingLeft: CGFloat = 10
    private let paddingRight: CGFloat = 10

    var body: some View {
        Canvas { context, size in
            drawProfile(context: context, size: size)
        }
        .background(TM.bgSecondary)
    }

    private func drawProfile(context: GraphicsContext, size: CGSize) {
        guard trackPoints.count >= 2 else { return }

        let plotRect = CGRect(
            x: paddingLeft,
            y: paddingTop,
            width: size.width - paddingLeft - paddingRight,
            height: size.height - paddingTop - paddingBottom
        )

        let elevations = trackPoints.map(\.elevation)
        let minEle = elevations.min() ?? 0
        let maxEle = elevations.max() ?? 0
        let eleRange = max(maxEle - minEle, 1)
        let maxDist = trackPoints.last?.distance ?? 1

        let terrainTypes = ElevationProfileAnalyzer.classify(trackPoints: trackPoints)

        drawColoredSegments(context: context, plotRect: plotRect, minEle: minEle, eleRange: eleRange, maxDist: maxDist, terrainTypes: terrainTypes)

        if showMilestones {
            drawMilestones(context: context, plotRect: plotRect, minEle: minEle, eleRange: eleRange, maxDist: maxDist)
        }
    }

    private func drawColoredSegments(context: GraphicsContext, plotRect: CGRect, minEle: Double, eleRange: Double, maxDist: Double, terrainTypes: [TerrainType]) {
        guard trackPoints.count >= 2 else { return }

        for i in 1..<trackPoints.count {
            let prevPoint = trackPoints[i - 1]
            let currPoint = trackPoints[i]
            let terrain = terrainTypes[i]

            let x1 = plotRect.minX + CGFloat(prevPoint.distance / maxDist) * plotRect.width
            let y1 = plotRect.maxY - CGFloat((prevPoint.elevation - minEle) / eleRange) * plotRect.height
            let x2 = plotRect.minX + CGFloat(currPoint.distance / maxDist) * plotRect.width
            let y2 = plotRect.maxY - CGFloat((currPoint.elevation - minEle) / eleRange) * plotRect.height

            var fillPath = Path()
            fillPath.move(to: CGPoint(x: x1, y: plotRect.maxY))
            fillPath.addLine(to: CGPoint(x: x1, y: y1))
            fillPath.addLine(to: CGPoint(x: x2, y: y2))
            fillPath.addLine(to: CGPoint(x: x2, y: plotRect.maxY))
            fillPath.closeSubpath()

            context.fill(fillPath, with: .color(terrain.color.opacity(0.2)))

            var linePath = Path()
            linePath.move(to: CGPoint(x: x1, y: y1))
            linePath.addLine(to: CGPoint(x: x2, y: y2))

            context.stroke(linePath, with: .color(terrain.color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawMilestones(context: GraphicsContext, plotRect: CGRect, minEle: Double, eleRange: Double, maxDist: Double) {
        for (index, milestone) in milestones.enumerated() {
            let x = plotRect.minX + CGFloat(milestone.distance / maxDist) * plotRect.width
            let y = plotRect.maxY - CGFloat((milestone.elevation - minEle) / eleRange) * plotRect.height

            var dashPath = Path()
            dashPath.move(to: CGPoint(x: x, y: y))
            dashPath.addLine(to: CGPoint(x: x, y: plotRect.maxY))
            context.stroke(dashPath, with: .color(TM.accent.opacity(0.4)), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))

            let circleRect = CGRect(x: x - 5, y: y - 5, width: 10, height: 10)
            context.fill(Path(ellipseIn: circleRect), with: .color(milestone.milestoneType.color))
            context.stroke(Path(ellipseIn: circleRect), with: .color(TM.bgPrimary), lineWidth: 1.5)

            let text = Text("\(index + 1)")
                .font(.system(size: 6, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            context.draw(text, at: CGPoint(x: x, y: y), anchor: .center)
        }
    }
}

// MARK: - Milestone Markers Overlay (SwiftUI views for animated appearance)

private struct MilestoneMarkersOverlay: View {
    let trackPoints: [TrackPoint]
    let milestones: [Milestone]
    let visibleCount: Int

    private let padding: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let plotRect = CGRect(
                x: padding, y: padding,
                width: geo.size.width - padding * 2,
                height: geo.size.height - padding * 2
            )
            let elevations = trackPoints.map(\.elevation)
            let minEle = elevations.min() ?? 0
            let maxEle = elevations.max() ?? 0
            let eleRange = max(maxEle - minEle, 1)
            let maxDist = trackPoints.last?.distance ?? 1

            ForEach(Array(milestones.prefix(visibleCount).enumerated()), id: \.offset) { index, milestone in
                let x = plotRect.minX + CGFloat(milestone.distance / maxDist) * plotRect.width
                let y = plotRect.maxY - CGFloat((milestone.elevation - minEle) / eleRange) * plotRect.height

                MilestoneMarkerView(
                    color: milestone.milestoneType.color,
                    index: index + 1
                )
                .position(x: x, y: y)
            }
        }
    }
}

private struct MilestoneMarkerView: View {
    let color: Color
    let index: Int

    @State private var appeared = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Circle()
                .strokeBorder(Color.white, lineWidth: 1.5)
                .frame(width: 12, height: 12)

            Text("\(index)")
                .font(.system(size: 6, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .scaleEffect(appeared ? 1 : 0)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
                appeared = true
            }
        }
    }
}

// MARK: - Preview Helpers

@MainActor
private func loadPreviewGPX() -> (Trail, [TrackPoint], [Milestone]) {
    guard let url = Bundle.main.url(forResource: "utmb-preview", withExtension: "gpx") else {
        return (Trail(id: nil, name: "Preview", distance: 0, dPlus: 0), [], [])
    }
    do {
        let (parsedPoints, dPlus) = try GPXParser.parse(url: url)
        let trail = Trail(
            id: nil,
            name: GPXParser.trailName(from: url),
            distance: parsedPoints.last?.distance ?? 0,
            dPlus: dPlus
        )
        let trackPoints = parsedPoints.enumerated().map { index, point in
            TrackPoint(
                id: nil, trailId: 0, index: index,
                latitude: point.latitude, longitude: point.longitude,
                elevation: point.elevation, distance: point.distance
            )
        }
        let milestones = MilestoneDetector.detect(from: trackPoints, trailId: 0)
        return (trail, trackPoints, milestones)
    } catch {
        return (Trail(id: nil, name: "Preview", distance: 0, dPlus: 0), [], [])
    }
}

#Preview("Upload") {
    ImportView(
        store: Store(initialState: ImportStore.State()) {
            ImportStore()
        }
    )
}

#Preview("Upload - Loading") {
    ImportView(
        store: Store(
            initialState: ImportStore.State(phase: .analyzing)
        ) {
            ImportStore()
        }
    )
}

#Preview("Animation → Result") {
    let (trail, trackPoints, milestones) = loadPreviewGPX()
    ImportView(
        store: Store(
            initialState: {
                var state = ImportStore.State(
                    phase: .animatingProfile,
                    parsedTrail: trail,
                    parsedTrackPoints: trackPoints,
                    detectedMilestones: milestones
                )
                state.detectionFinished = true
                return state
            }()
        ) {
            ImportStore()
        }
    )
}

#Preview("Result - Free") {
    let (trail, trackPoints, milestones) = loadPreviewGPX()
    ImportView(
        store: Store(
            initialState: {
                var state = ImportStore.State(
                    phase: .result,
                    parsedTrail: trail,
                    parsedTrackPoints: trackPoints,
                    detectedMilestones: milestones
                )
                state.profileAnimationFinished = true
                state.detectionFinished = true
                return state
            }()
        ) {
            ImportStore()
        }
    )
}

#Preview("Result - Premium") {
    let (trail, trackPoints, milestones) = loadPreviewGPX()
    ImportView(
        store: Store(
            initialState: {
                var state = ImportStore.State(
                    phase: .result,
                    parsedTrail: trail,
                    parsedTrackPoints: trackPoints,
                    detectedMilestones: milestones,
                    isPremium: true
                )
                state.profileAnimationFinished = true
                state.detectionFinished = true
                return state
            }()
        ) {
            ImportStore()
        }
    )
}
