# Implementation Guide: Milestone Message Composition & Variable Substitution

## Overview

This guide provides the technical architecture for implementing the milestone announcement composition feature in TrailMark. It covers:
- Data model updates
- UI component implementation (Shortcuts-inspired pattern)
- Message template storage and rendering
- TTS playback with variable substitution

**Target**: iOS 18+, Swift 6, SwiftUI, TCA, SQLite-Data

---

## 1. Data Model Updates

### Models.swift — New Types

```swift
import Foundation

/// Milestone type enum with auto-suggested templates
enum MilestoneType: String, Codable {
    case climb
    case descent
    case refuel
    case danger
    case info

    var icon: String {
        switch self {
        case .climb: return "arrow.up"
        case .descent: return "arrow.down"
        case .refuel: return "drop.fill"
        case .danger: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .climb: return Color(hex: "ef4444")
        case .descent: return Color(hex: "3b82f6")
        case .refuel: return Color(hex: "10b981")
        case .danger: return Color(hex: "f59e0b")
        case .info: return Color(hex: "8b5cf6")
        }
    }

    /// Suggested message templates for quick composition
    var suggestedTemplates: [String] {
        switch self {
        case .climb:
            return [
                "You've reached {elevation} meters elevation!",
                "Great climb! {grade}% gradient conquered.",
                "Top of {milestone_name}! You're doing great!",
                "Push hard to {elevation}m!"
            ]
        case .descent:
            return [
                "Descending now. Watch your footing!",
                "Careful on the {grade}% descent ahead.",
                "Long descent ahead. Take it easy."
            ]
        case .refuel:
            return [
                "Refuel stop here at {distance} km.",
                "Great pace! Grab some water and calories.",
                "Fueling station at {elevation}m elevation."
            ]
        case .danger:
            return [
                "Hazard ahead. Stay alert!",
                "Technical section. Focus!"
            ]
        case .info:
            return [
                "You're at {milestone_name}.",
                "{milestone_name} ({elevation}m elevation)."
            ]
        }
    }
}

/// Available variables for milestone messages
enum MilestoneVariable: Hashable, Identifiable {
    case elevation(meters: Int)
    case distance(kilometers: Double)
    case grade(percent: Double)
    case milestoneName(String)

    var id: String { tokenKey }

    /// The key used in template strings: {elevation}, {distance}, etc.
    var tokenKey: String {
        switch self {
        case .elevation: return "elevation"
        case .distance: return "distance"
        case .grade: return "grade"
        case .milestoneName: return "milestone_name"
        }
    }

    /// Display label and value
    var displayLabel: String {
        switch self {
        case .elevation: return "elevation"
        case .distance: return "distance"
        case .grade: return "grade"
        case .milestoneName: return "milestone_name"
        }
    }

    var displayValue: String {
        switch self {
        case .elevation(let m): return "\(m) m"
        case .distance(let km): return String(format: "%.1f km", km)
        case .grade(let pct): return String(format: "%.0f%%", pct)
        case .milestoneName(let name): return name
        }
    }
}

/// Core Milestone model
/// Updated: now includes message template and type
struct Milestone: Identifiable, Equatable, Hashable {
    let id: Int64
    let trailId: Int64
    let pointIndex: Int
    let latitude: Double
    let longitude: Double
    let elevation: Double       // meters
    let distance: Double        // cumulative from start, meters

    // NEW: Milestone configuration
    var type: MilestoneType     // climb, descent, refuel, danger, info
    var message: String         // template: "You've reached {elevation} meters!"
    var name: String?           // optional: "Col de Croix"

    /// Computed property: distance from start in km
    var distanceFromStartKm: Double {
        distance / 1000
    }

    /// Computed property: gradient at this point
    /// Calculated during import or editing
    var grade: Double {
        // This will be set during import or milestone creation
        // For now, placeholder
        0.0
    }

    /// Generate available variables for this milestone
    var variables: [MilestoneVariable] {
        var vars: [MilestoneVariable] = [
            .elevation(meters: Int(elevation)),
            .distance(kilometers: distanceFromStartKm),
            .grade(percent: grade)
        ]
        if let name = name {
            vars.append(.milestoneName(name))
        }
        return vars
    }

    /// Render message by substituting variables with actual values
    func renderMessage() -> String {
        var result = message
        for variable in variables {
            let token = "{\(variable.tokenKey)}"
            let value = variable.displayValue.split(separator: " ").first.map(String.init) ?? ""
            result = result.replacingOccurrences(of: token, with: value)
        }
        return result
    }
}

/// Draft for creating new milestones
extension Milestone {
    static func draft(
        trailId: Int64,
        pointIndex: Int,
        latitude: Double,
        longitude: Double,
        elevation: Double,
        distance: Double
    ) -> Milestone {
        Milestone(
            id: 0,
            trailId: trailId,
            pointIndex: pointIndex,
            latitude: latitude,
            longitude: longitude,
            elevation: elevation,
            distance: distance,
            type: .info,
            message: "",
            name: nil
        )
    }
}
```

### Database Schema Update

```sql
-- Migration: Add message composition columns to milestone table
-- Version: 3 (increment from previous version)

ALTER TABLE milestone
ADD COLUMN type TEXT NOT NULL DEFAULT 'info';

ALTER TABLE milestone
ADD COLUMN message TEXT DEFAULT '';

-- Note: name column likely already exists; if not:
-- ALTER TABLE milestone ADD COLUMN name TEXT;

-- Index for efficient queries by milestone type
CREATE INDEX idx_milestone_type ON milestone(trailId, type);
```

---

## 2. Database Client Updates

### AppDatabase.swift — Schema Migration

```swift
import SQLiteData

extension AppDatabase {
    /// Update migrations to version 3: Add message composition
    static var migrator: Migrator {
        Migrator { db in
            // Existing migrations (versions 1-2)...

            // Migration 3: Add milestone message composition
            try db.executeSQL("""
                ALTER TABLE milestone ADD COLUMN type TEXT NOT NULL DEFAULT 'info';
            """)

            try db.executeSQL("""
                ALTER TABLE milestone ADD COLUMN message TEXT DEFAULT '';
            """)

            try db.executeSQL("""
                CREATE INDEX idx_milestone_type ON milestone(trailId, type);
            """)
        }
    }
}
```

### Milestone Table Extension (SQLite-Data)

```swift
// In Models.swift, add StructuredQueries @Table macro

import SQLiteData

extension Milestone {
    @Table("milestone")
    struct Table {
        @Column(as: "id")         var id: Int64
        @Column(as: "trailId")    var trailId: Int64
        @Column(as: "pointIndex") var pointIndex: Int
        @Column(as: "latitude")   var latitude: Double
        @Column(as: "longitude")  var longitude: Double
        @Column(as: "elevation")  var elevation: Double
        @Column(as: "distance")   var distance: Double
        @Column(as: "type")       var type: String       // NEW
        @Column(as: "message")    var message: String    // NEW
        @Column(as: "name")       var name: String?
    }

    /// Insert a new milestone with message
    static func create(
        trailId: Int64,
        pointIndex: Int,
        latitude: Double,
        longitude: Double,
        elevation: Double,
        distance: Double,
        type: MilestoneType,
        message: String,
        name: String? = nil,
        db: DatabaseClient
    ) async throws {
        try await db.execute { db in
            try Milestone.Table(
                id: 0, // auto-increment
                trailId: trailId,
                pointIndex: pointIndex,
                latitude: latitude,
                longitude: longitude,
                elevation: elevation,
                distance: distance,
                type: type.rawValue,
                message: message,
                name: name
            ).insert(into: db)
        }
    }

    /// Update a milestone's message, type, and name
    static func update(
        id: Int64,
        type: MilestoneType,
        message: String,
        name: String?,
        db: DatabaseClient
    ) async throws {
        try await db.execute { db in
            try Milestone.Table
                .where { $0.id == id }
                .update { $0.type.set(to: type.rawValue) }
                .update { $0.message.set(to: message) }
                .update { $0.name.set(to: name) }
                .execute(db)
        }
    }
}
```

---

## 3. Editor Feature Reducer (TCA)

### EditorFeature.swift — Message Composition State

```swift
import ComposableArchitecture

@Reducer
struct EditorFeature {
    @ObservableState
    struct State: Equatable {
        // Existing state...
        var trail: Trail?
        var trackPoints: [TrackPoint] = []
        var milestones: [Milestone] = []

        // NEW: Message composition state
        @Presents var milestoneCompositionSheet: MilestoneCompositionFeature.State?

        var selectedMilestoneForComposition: Milestone?
    }

    enum Action {
        // Existing actions...

        // NEW: Message composition actions
        case presentCompositionSheet(milestone: Milestone)
        case milestoneComposition(PresentationAction<MilestoneCompositionFeature.Action>)
        case saveMilestoneMessage(id: Int64, type: MilestoneType, message: String, name: String?)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .presentCompositionSheet(milestone):
                state.milestoneCompositionSheet = MilestoneCompositionFeature.State(
                    milestone: milestone
                )
                return .none

            case .milestoneComposition(.presented(.savePressed)):
                // Handle save via composition feature
                return .none

            case let .saveMilestoneMessage(id, type, message, name):
                return .run { send in
                    @Dependency(\.databaseClient) var db
                    try await Milestone.update(
                        id: id,
                        type: type,
                        message: message,
                        name: name,
                        db: db
                    )

                    // Refresh milestones
                    // (dispatch action to reload from DB)
                }

            default:
                return .none
            }
        }
        .ifLet(\.$milestoneCompositionSheet, action: \.milestoneComposition) {
            MilestoneCompositionFeature()
        }
    }
}
```

### New Feature: MilestoneCompositionFeature

```swift
import ComposableArchitecture

@Reducer
struct MilestoneCompositionFeature {
    @ObservableState
    struct State: Equatable {
        let milestone: Milestone

        // Composition state
        var messageText: String = ""
        var selectedType: MilestoneType
        var milestoneName: String?

        // UI state
        var showVariablePicker: Bool = false
        var isPreviewingVoice: Bool = false
        var previewError: String?

        init(milestone: Milestone) {
            self.milestone = milestone
            self.messageText = milestone.message
            self.selectedType = milestone.type
            self.milestoneName = milestone.name
        }

        var availableVariables: [MilestoneVariable] {
            [
                .elevation(meters: Int(milestone.elevation)),
                .distance(kilometers: milestone.distanceFromStartKm),
                .grade(percent: milestone.grade),
                milestoneName.map { .milestoneName($0) }
            ].compactMap { $0 }
        }

        var renderedMessage: String {
            var result = messageText
            for variable in availableVariables {
                let token = "{\(variable.tokenKey)}"
                let value = variable.displayValue.split(separator: " ").first.map(String.init) ?? ""
                result = result.replacingOccurrences(of: token, with: value)
            }
            return result
        }
    }

    enum Action {
        case messageChanged(String)
        case typeChanged(MilestoneType)
        case nameChanged(String)
        case showVariablePicker
        case variableSelected(MilestoneVariable)
        case hideVariablePicker
        case previewVoicePressed
        case previewVoiceCompleted
        case savePressed
        case cancelPressed
    }

    @Dependency(\.speechClient) var speechClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .messageChanged(text):
                state.messageText = text
                return .none

            case let .typeChanged(type):
                state.selectedType = type
                return .none

            case let .nameChanged(name):
                state.milestoneName = name.isEmpty ? nil : name
                return .none

            case .showVariablePicker:
                state.showVariablePicker = true
                return .none

            case .hideVariablePicker:
                state.showVariablePicker = false
                return .none

            case let .variableSelected(variable):
                let token = "{\(variable.tokenKey)}"
                state.messageText.append(token)
                state.showVariablePicker = false
                return .none

            case .previewVoicePressed:
                state.isPreviewingVoice = true
                return .run { send in
                    let rendered = state.renderedMessage
                    try await speechClient.speak(rendered)
                    await send(.previewVoiceCompleted)
                }

            case .previewVoiceCompleted:
                state.isPreviewingVoice = false
                return .none

            case .savePressed, .cancelPressed:
                return .none
            }
        }
    }
}
```

---

## 4. UI Views

### MilestoneCompositionView

```swift
import SwiftUI
import ComposableArchitecture

struct MilestoneCompositionView: View {
    @Bindable var store: StoreOf<MilestoneCompositionFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header: Context Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Milestone Details").font(.headline)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Elevation", systemImage: "arrow.up").font(.caption).foregroundColor(.gray)
                                Text("\(Int(store.milestone.elevation)) m")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.semibold)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 4) {
                                Label("Distance", systemImage: "figure.walk").font(.caption).foregroundColor(.gray)
                                Text(String(format: "%.1f km", store.milestone.distanceFromStartKm))
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.semibold)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 4) {
                                Label("Grade", systemImage: "chart.line.uptrend.xyaxis").font(.caption).foregroundColor(.gray)
                                Text(String(format: "%.0f%%", store.milestone.grade))
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Milestone Type Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type").font(.headline)

                        Picker("Milestone Type", selection: $store.selectedType) {
                            ForEach([MilestoneType.climb, .descent, .refuel, .danger, .info], id: \.self) { type in
                                Label(type.rawValue.capitalized, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Milestone Name (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name (Optional)").font(.headline)
                        TextField("e.g., Col de Croix", text: .init(
                            get: { store.milestoneName ?? "" },
                            set: { store.send(.nameChanged($0)) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    // Message Composition
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message").font(.headline)

                        TextEditor(text: $store.messageText)
                            .frame(minHeight: 100, maxHeight: 250)
                            .border(Color.gray.opacity(0.3), width: 1)
                            .cornerRadius(8)
                            .font(.system(.body, design: .default))
                            .onChange(of: store.messageText) { oldValue, newValue in
                                store.send(.messageChanged(newValue))
                            }

                        // Insert Data Button
                        HStack {
                            Button(action: {
                                store.send(.showVariablePicker)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle")
                                    Text("Insert Data")
                                }
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button(action: {
                                store.send(.previewVoicePressed)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text("Preview")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(store.isPreviewingVoice || store.messageText.isEmpty)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.send(.savePressed)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        store.send(.cancelPressed)
                    }
                }
            }
            .sheet(isPresented: $store.showVariablePicker) {
                VariableSelectorSheet(
                    variables: store.availableVariables,
                    onSelect: { variable in
                        store.send(.variableSelected(variable))
                    }
                )
            }
        }
    }
}

struct VariableSelectorSheet: View {
    let variables: [MilestoneVariable]
    let onSelect: (MilestoneVariable) -> Void

    var body: some View {
        NavigationStack {
            List(variables, id: \.id) { variable in
                Button(action: { onSelect(variable) }) {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(variable.displayLabel)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(variable.displayValue)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Text("{\(variable.tokenKey)}")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .contentShape(Rectangle())
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Available Variables")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let sampleMilestone = Milestone(
        id: 1,
        trailId: 1,
        pointIndex: 50,
        latitude: 45.2,
        longitude: 6.7,
        elevation: 1350,
        distance: 12400,
        type: .climb,
        message: "You've reached {elevation} meters!",
        name: "Col de Croix"
    )

    let store = StoreOf<MilestoneCompositionFeature>(
        initialState: MilestoneCompositionFeature.State(milestone: sampleMilestone)
    ) {
        MilestoneCompositionFeature()
    }

    MilestoneCompositionView(store: store)
}
```

---

## 5. TTS Rendering & Playback

### SpeechClient Update

```swift
import Dependencies

extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}

protocol SpeechClient: Sendable {
    func speak(_ text: String) async throws
    func stop() async
}

// Update the existing speech client implementation to handle milestone playback

final class RealSpeechClient: SpeechClient, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) async throws {
        // Ensure audio session configured for background
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .playback,
            mode: .voicePrompt,
            options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
        )
        try audioSession.setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR") // French by default
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        return await withCheckedContinuation { continuation in
            let delegate = SpeechDelegate { result in
                continuation.resume()
            }
            synthesizer.delegate = delegate
            synthesizer.speak(utterance)
        }
    }

    func stop() async {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onCompletion: () -> Void

    init(onCompletion: @escaping () -> Void) {
        self.onCompletion = onCompletion
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        onCompletion()
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        onCompletion()
    }
}

extension SpeechClient where Self == RealSpeechClient {
    static var live: Self { RealSpeechClient() }
}
```

### RunFeature Update — Milestone Playback

```swift
@Reducer
struct RunFeature {
    @ObservableState
    struct State: Equatable {
        var trail: Trail?
        var milestones: [Milestone] = []
        var userLocation: CLLocationCoordinate2D?

        // Track which milestones have been triggered
        var triggeredMilestoneIds: Set<Int64> = []
    }

    enum Action {
        case locationUpdated(CLLocationCoordinate2D)
        case checkMilestoneProximity
        case milestoneTriggered(Milestone)
    }

    @Dependency(\.speechClient) var speechClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .locationUpdated(location):
                state.userLocation = location
                return .send(.checkMilestoneProximity)

            case .checkMilestoneProximity:
                guard let userLocation = state.userLocation else { return .none }

                var effects: [Effect<Action>] = []

                for milestone in state.milestones {
                    // Skip if already triggered
                    guard !state.triggeredMilestoneIds.contains(milestone.id) else { continue }

                    let milestoneCoord = CLLocationCoordinate2D(
                        latitude: milestone.latitude,
                        longitude: milestone.longitude
                    )

                    let distance = CLLocation(
                        latitude: userLocation.latitude,
                        longitude: userLocation.longitude
                    ).distance(from: CLLocation(
                        latitude: milestoneCoord.latitude,
                        longitude: milestoneCoord.longitude
                    ))

                    // Trigger if within 30 meters
                    if distance < 30 {
                        effects.append(.send(.milestoneTriggered(milestone)))
                    }
                }

                return .merge(effects)

            case let .milestoneTriggered(milestone):
                state.triggeredMilestoneIds.insert(milestone.id)

                // Render message with variable substitution
                let renderedMessage = renderMessage(
                    template: milestone.message,
                    milestone: milestone
                )

                return .run { _ in
                    try await speechClient.speak(renderedMessage)
                }
            }
        }
    }

    private func renderMessage(template: String, milestone: Milestone) -> String {
        var result = template

        // Replace tokens with actual values
        result = result.replacingOccurrences(
            of: "{elevation}",
            with: String(Int(milestone.elevation))
        )
        result = result.replacingOccurrences(
            of: "{distance}",
            with: String(format: "%.1f", milestone.distanceFromStartKm)
        )
        result = result.replacingOccurrences(
            of: "{grade}",
            with: String(format: "%.0f", milestone.grade)
        )
        if let name = milestone.name {
            result = result.replacingOccurrences(
                of: "{milestone_name}",
                with: name
            )
        }

        return result
    }
}
```

---

## 6. Edge Cases & Error Handling

### Template Token Validation

```swift
/// Validate that all tokens in message are valid variables
func validateMessageTemplate(_ message: String, availableVariables: [MilestoneVariable]) -> [String] {
    let pattern = "\\{(\\w+)\\}"
    var errors: [String] = []

    if let regex = try? NSRegularExpression(pattern: pattern) {
        let nsString = message as NSString
        let matches = regex.matches(in: message, range: NSRange(location: 0, length: nsString.length))

        for match in matches {
            if let range = Range(match.range(at: 1), in: message) {
                let tokenKey = String(message[range])
                let isValid = availableVariables.contains { $0.tokenKey == tokenKey }
                if !isValid {
                    errors.append("Unknown variable: {\(tokenKey)}")
                }
            }
        }
    }

    return errors
}

// Usage in composition view
if let error = validateMessageTemplate(store.messageText, availableVariables: store.availableVariables).first {
    Text(error).font(.caption).foregroundColor(.red)
}
```

### TTS Pronunciation Edge Cases

```swift
/// Handle French-specific pronunciation (Phase 2)
func improvePronounciation(_ text: String) -> String {
    var result = text

    // Add spacing around numbers for better pronunciation
    // "1350m" -> "1350 meters"
    result = result.replacingOccurrences(
        of: "([0-9]+)m\\b",
        with: "$1 meters",
        options: .regularExpression
    )

    // "Col de Galibier" -> keep as-is (TTS handles French)
    // Future: Add pronunciation hints {elevation:one-thousand-three-fifty}

    return result
}
```

### Message Length Warnings

```swift
let maxRecommendedLength = 200

if store.messageText.count > maxRecommendedLength {
    Text("Message is long. TTS will take ~\(store.messageText.count / 20) seconds to speak.")
        .font(.caption)
        .foregroundColor(.orange)
}
```

---

## 7. Testing

### Unit Tests: Message Rendering

```swift
import XCTest

final class MilestoneMessageRenderingTests: XCTestCase {
    func testSimpleSubstitution() {
        let milestone = Milestone(
            id: 1, trailId: 1, pointIndex: 0,
            latitude: 0, longitude: 0,
            elevation: 1350, distance: 12400,
            type: .climb,
            message: "You've reached {elevation} meters!",
            name: nil
        )

        let rendered = milestone.renderMessage()
        XCTAssertEqual(rendered, "You've reached 1350 meters!")
    }

    func testMultipleVariables() {
        let milestone = Milestone(
            id: 1, trailId: 1, pointIndex: 0,
            latitude: 0, longitude: 0,
            elevation: 1350, distance: 12400,
            type: .climb,
            message: "{elevation}m at {distance}km with {grade}% grade",
            name: nil
        )

        let rendered = milestone.renderMessage()
        XCTAssertEqual(rendered, "1350m at 12.4km with 0% grade")
    }

    func testMissingVariable() {
        let milestone = Milestone(
            id: 1, trailId: 1, pointIndex: 0,
            latitude: 0, longitude: 0,
            elevation: 1350, distance: 12400,
            type: .climb,
            message: "You're at {milestone_name}",
            name: nil
        )

        let rendered = milestone.renderMessage()
        // Token remains unchanged if variable not provided
        XCTAssertEqual(rendered, "You're at {milestone_name}")
    }
}
```

### Integration Tests: Composition Feature

```swift
@MainActor
final class MilestoneCompositionTests: XCTestCase {
    func testVariableInsertion() async {
        let sampleMilestone = Milestone(
            id: 1, trailId: 1, pointIndex: 50,
            latitude: 45.2, longitude: 6.7,
            elevation: 1350, distance: 12400,
            type: .climb,
            message: "",
            name: nil
        )

        let store = TestStore(
            initialState: MilestoneCompositionFeature.State(milestone: sampleMilestone)
        ) {
            MilestoneCompositionFeature()
        }

        await store.send(.messageChanged("You've reached "))
        await store.send(.variableSelected(.elevation(meters: 1350))) {
            $0.messageText = "You've reached {elevation}"
            $0.showVariablePicker = false
        }
    }
}
```

---

## 8. Rollout Plan

### Phase 1: MVP (Week 6-10)
- [ ] Database schema migration (version 3)
- [ ] Models update (MilestoneType, MilestoneVariable)
- [ ] EditorFeature & MilestoneCompositionFeature reducers
- [ ] MilestoneCompositionView UI
- [ ] TTS rendering in RunFeature
- [ ] Testing & device validation

### Phase 2: Polish (Week 11-14)
- [ ] Template suggestions by type
- [ ] Trail sharing (export milestones)
- [ ] Pronunciation hints (Phase 2+)
- [ ] Analytics tracking

### Deployment Checklist
- [ ] Database migration tested on simulator + device
- [ ] TTS latency verified (<500ms)
- [ ] French pronunciation acceptable
- [ ] Edge cases handled (empty message, special chars)
- [ ] App Store review guidelines met
- [ ] Release notes written

---

## 9. References

- [Apple Shortcuts Variables](https://support.apple.com/guide/shortcuts/use-variables-apdd02c2780c/ios)
- [AVSpeechSynthesizer Documentation](https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer)
- [TCA Documentation](https://pointfreeco.github.io/swift-composable-architecture/)
- [SQLite-Data](https://github.com/pointfreeco/sqlite-data)
- Design guide: See DESIGN_MILESTONE_COMPOSITION_PATTERNS.md
