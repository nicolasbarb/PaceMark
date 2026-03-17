# TrailMark: Milestone Announcement Composition Design

## Design Goal
Enable trail runners to quickly compose **personalized voice announcements** for milestones, mixing custom text with auto-calculated data (elevation, distance, gradient), optimized for **small touch targets on a phone screen**.

---

## Pattern: Apple Shortcuts-Inspired (RECOMMENDED FOR MVP)

### Why This Pattern?
1. **Familiar to iOS users** — matches system behavior
2. **Handles variable insertion elegantly** — blue pill tokens keep context visible
3. **Flexible for mixed content** — free text + variables in one field
4. **Minimal UI overhead** — one button to access variables

### Interaction Flow

```
┌─────────────────────────────────────┐
│ Edit Milestone                      │
├─────────────────────────────────────┤
│                                     │
│ Milestone Type:  ◉ Climb            │
│                  ○ Descent          │
│                  ○ Refuel           │
│                  ○ Danger           │
│                  ○ Info             │
│                                     │
│ Message:                            │
│ ┌─────────────────────────────────┐ │
│ │ You've reached [elevation]      │ │
│ │ meters elevation at [grade]%    │ │
│ │ grade.                          │ │
│ │                                 │ │
│ │ Cursor here •                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [ Insert Data ▼ ]                  │
│                                     │
├─────────────────────────────────────┤
│         [Cancel]      [Save]        │
└─────────────────────────────────────┘
```

When user taps **"Insert Data"** button:

```
┌─────────────────────────────────────┐
│ Available Variables                 │
├─────────────────────────────────────┤
│                                     │
│ 🔷 elevation    1,350 m             │
│                                     │
│ 🔷 distance     12.4 km             │
│                                     │
│ 🔷 grade        8%                  │
│                                     │
│ 🔷 milestone_name  Col de Croix     │
│   (if user named it)                │
│                                     │
├─────────────────────────────────────┤
│            [Dismiss]                │
└─────────────────────────────────────┘
```

User taps `elevation` → variable **blue pill** inserted at cursor:

```
┌─────────────────────────────────────┐
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ You've reached [elevation  ]    │ │
│ │ meters elevation at [grade]%    │ │
│ │ grade. Cursor moved here •      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Legend:                             │
│  [elevation  ]  = blue pill token   │
│  [grade]        = blue pill token   │
│                                     │
└─────────────────────────────────────┘
```

### Implementation Details

#### Visual Styling
- **Blue pill token**: `background: Color.blue, opacity: 0.2, cornerRadius: 8`
- **Text**: `font: .system(.body, design: .default)` for regular text
- **Token text**: `font: .system(.subheadline, design: .monospaced)` for variable names
- **Height**: Expand TextEditor to fit content (min 100pt, max 250pt)

#### SwiftUI Code Structure

```swift
struct MilestoneMessageEditor: View {
    @State var message: String = ""
    @State var showVariableSheet = false

    let milestone: Milestone

    var availableVariables: [MilestoneVariable] {
        [
            .elevation(Int(milestone.elevation)),
            .distance(String(format: "%.1f", milestone.distance / 1000)),
            .grade(String(format: "%.0f", milestone.grade)),
            milestone.name.map { .customName($0) } ?? nil
        ].compactMap { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message").font(.headline)

            TextEditor(text: $message)
                .frame(minHeight: 100, maxHeight: 250)
                .border(Color.gray.opacity(0.3), width: 1)
                .cornerRadius(8)
                .font(.system(.body, design: .default))

            Button(action: { showVariableSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Insert Data")
                }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .sheet(isPresented: $showVariableSheet) {
            VariableSelectionSheet(
                variables: availableVariables,
                onSelect: insertVariable
            )
        }
    }

    private func insertVariable(_ variable: MilestoneVariable) {
        let tokenKey = variable.tokenKey // "elevation", "distance", etc.
        let token = "{\(tokenKey)}"
        message.append(token)
        showVariableSheet = false
    }
}

enum MilestoneVariable: Hashable {
    case elevation(Int)
    case distance(String)
    case grade(String)
    case customName(String)

    var tokenKey: String {
        switch self {
        case .elevation: return "elevation"
        case .distance: return "distance"
        case .grade: return "grade"
        case .customName: return "milestone_name"
        }
    }

    var displayValue: String {
        switch self {
        case .elevation(let m): return "\(m) m"
        case .distance(let km): return "\(km) km"
        case .grade(let pct): return "\(pct)%"
        case .customName(let name): return name
        }
    }
}

struct VariableSelectionSheet: View {
    let variables: [MilestoneVariable]
    let onSelect: (MilestoneVariable) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Available Variables").font(.headline).padding()

            List(variables, id: \.self) { variable in
                Button(action: { onSelect(variable) }) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(variable.tokenKey).font(.subheadline).fontWeight(.semibold)
                            Text(variable.displayValue).font(.caption).foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .foregroundColor(.primary)
            }
        }
    }
}
```

#### Token Rendering in TextEditor
To make blue pills visible inside the TextEditor, use `AttributedString` with custom rendering:

```swift
import Foundation

func renderMessageWithTokens(_ template: String) -> AttributedString {
    let pattern = "\\{(\\w+)\\}"
    var result = AttributedString(template)

    if let regex = try? NSRegularExpression(pattern: pattern) {
        let nsString = template as NSString
        let matches = regex.matches(in: template, range: NSRange(location: 0, length: nsString.length))

        for match in matches.reversed() {
            let range = match.range
            if let swiftRange = Range(range, in: template) {
                let startIdx = result.index(result.startIndex, offsetByCharacters: swiftRange.lowerBound.utf16Offset(in: template))
                let endIdx = result.index(startIdx, offsetByCharacters: swiftRange.count)

                result[startIdx..<endIdx].backgroundColor = .blue.opacity(0.2)
                result[startIdx..<endIdx].foregroundColor = .blue
                result[startIdx..<endIdx].font = .system(.subheadline, design: .monospaced)
            }
        }
    }

    return result
}
```

---

## Pattern: Hybrid Template + Variables (SIMPLER ALTERNATIVE)

If the above is too complex, use a simpler hybrid approach:

### Interaction Flow

```
┌─────────────────────────────────────┐
│ Edit Milestone                      │
├─────────────────────────────────────┤
│ Type: Climb                         │
│                                     │
│ Template:                           │
│ ┌─────────────────────────────────┐ │
│ │ [You've reached the peak!]      │ │
│ │ [Great job on this climb!]      │ │
│ │ [You've conquered 1,350 meters] │ │
│ │                                 │ │
│ │ Or type your own message...     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Custom Message:                     │
│ ┌─────────────────────────────────┐ │
│ │ You've reached                  │ │
│ │ [ Insert: elevation ]           │ │
│ │                                 │ │
│ │ meters elevation                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [ Insert: elevation ] [ distance ]  │
│ [ grade ]      [ milestone_name ]   │
│                                     │
├─────────────────────────────────────┤
│         [Cancel]      [Save]        │
└─────────────────────────────────────┘
```

### Pros & Cons

**Pros:**
- Simpler UI — templates reduce decision fatigue
- Buttons for each variable (no modal)
- Pre-canned phrases reduce typos
- Good for runners in a hurry

**Cons:**
- Less flexible (templates might not fit all cases)
- More button UI overhead
- Multiple taps to compose (template + custom + variables)

### Implementation

```swift
struct HybridMilestoneComposition: View {
    @State var selectedTemplate: String?
    @State var customMessage: String = ""

    let templates = [
        "You've reached the peak!",
        "Great job on this climb!",
        "You're crushing it!"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Template Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Templates").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(templates, id: \.self) { template in
                            Button(template) {
                                customMessage = template
                            }
                            .font(.caption)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                        }
                    }
                }
            }

            // Custom Message Editor
            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Message").font(.headline)
                TextEditor(text: $customMessage)
                    .frame(minHeight: 80)
                    .border(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }

            // Variable Buttons (inline)
            VStack(alignment: .leading, spacing: 8) {
                Text("Insert Data").font(.caption).foregroundColor(.gray)
                HStack(spacing: 8) {
                    VariableButton(label: "elevation") {
                        customMessage.append("{elevation}")
                    }
                    VariableButton(label: "distance") {
                        customMessage.append("{distance}")
                    }
                    VariableButton(label: "grade") {
                        customMessage.append("{grade}")
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct VariableButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption2)
                .padding(6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
    }
}
```

---

## Pattern: Word Bank Drag-Drop (MOST ENGAGING)

If resources allow, implement a Duolingo-style composable phrase system:

### Interaction Flow

```
┌─────────────────────────────────────┐
│ Build Your Announcement             │
├─────────────────────────────────────┤
│                                     │
│ Your Announcement (Drop Here):      │
│ ┌─────────────────────────────────┐ │
│ │ [You've reached]  [elevation]   │ │
│ │ [meters]  [great job]           │ │
│ │                                 │ │
│ │ Drag words here to reorder...   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Word Bank:                          │
│ ┌─────────────────────────────────┐ │
│ │ [You've reached] [elevation]    │ │
│ │ [distance] [grade] [meters]     │ │
│ │ [km] [percent] [great job]      │ │
│ │ [you're crushing it] [climb]    │ │
│ │ [descent] [refuel here]         │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│         [Preview]     [Save]        │
└─────────────────────────────────────┘
```

### Pros
- **Tactile & engaging** — users feel they're building something
- **No typos** — predefined words only
- **Reorderable** — can test different phrasings
- **Discovery-friendly** — easy to see all options

### Cons
- **High interaction overhead** — many drags
- **Dependency** — requires `gesture-handler` library
- **Maintenance** — must manage word bank per milestone type
- **Less flexible** — can't add arbitrary text

### When to Use
- If you have time for a polish iteration
- For a more "premium" feel vs. competitors
- If user testing shows template buttons feel clunky

---

## Mockup: Full Milestone Editor Screen

### Simplified (Shortcuts Pattern)

```
┌──────────────────────────────────┐
│◄ Milestone Editor                 │ X
├──────────────────────────────────┤
│ Location: 12.4 km from start     │
│ Elevation: 1,350 m               │
│ Grade: +8%                       │
│                                  │
│ Type:                            │
│ ◉ Climb  ○ Descent ○ Refuel      │
│ ○ Danger ○ Info                  │
│                                  │
│ Message:                         │
│ ┌──────────────────────────────┐ │
│ │ You've reached [elevation]   │ │
│ │ meters at [grade]% grade.    │ │
│ │ Excellent work!              │ │
│ │                              │ │
│ └──────────────────────────────┘ │
│                                  │
│ [ Insert Data ▼ ]               │
│                                  │
│ Milestone Name (Optional):       │
│ ┌──────────────────────────────┐ │
│ │ Col de Croix                 │ │
│ └──────────────────────────────┘ │
│                                  │
│         [ Preview Voice ]        │
│         [ Save ] [ Cancel ]      │
└──────────────────────────────────┘
```

### Auto-Calculated Data Visible
- Always show: **elevation, distance, grade** at the top
- These are read-only context, insertable as variables
- Helps runner understand what data is available

### Preview Voice Button
- **Tap "Preview Voice"** → reads the announcement aloud with actual values
- Uses system TTS to render template with substitutions
- Allows testing before saving

---

## Data Model

### Milestone Store Structure

```swift
struct Milestone {
    let id: Int64

    // Location
    let trailId: Int64
    let pointIndex: Int
    let latitude: Double
    let longitude: Double
    let elevation: Double      // meters
    let distance: Double       // from start, meters
    let distanceFromStart: Double { distance / 1000 } // km for display

    // Auto-calculated
    let grade: Double          // percent (e.g., 8.5)

    // User Input
    let type: MilestoneType    // enum: climb, descent, refuel, danger, info
    var message: String        // template: "You've reached {elevation} meters"
    var name: String?          // optional: "Col de Croix"

    // Computed: gradient at point
    var gradientLabel: String {
        if grade > 10 { return "Very steep" }
        if grade > 6 { return "Steep" }
        if grade > 3 { return "Moderate" }
        return "Gentle"
    }
}

enum MilestoneType: String {
    case climb, descent, refuel, danger, info

    var icon: String {
        switch self {
        case .climb: return "arrow.up"
        case .descent: return "arrow.down"
        case .refuel: return "drop.fill"
        case .danger: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var suggestedTemplates: [String] {
        switch self {
        case .climb:
            return [
                "You've reached {elevation} meters elevation!",
                "Great climb! {grade}% gradient conquered.",
                "Top of {milestone_name}! You're doing great!"
            ]
        case .descent:
            return [
                "Descending now. Watch your footing!",
                "Careful on the {grade}% descent ahead."
            ]
        case .refuel:
            return [
                "Time for a refuel stop here.",
                "Grab some water and calories here."
            ]
        case .danger:
            return [
                "Hazard ahead. Take care!"
            ]
        case .info:
            return [
                "Info: {milestone_name}"
            ]
        }
    }
}
```

### Database Storage

```sql
-- In milestone table
CREATE TABLE milestone (
    id INTEGER PRIMARY KEY,
    trailId INTEGER NOT NULL,
    pointIndex INTEGER NOT NULL,
    latitude REAL,
    longitude REAL,
    elevation REAL,
    distance REAL,          -- cumulative from start
    grade REAL,             -- calculated at insert
    type TEXT NOT NULL,
    message TEXT,           -- template: "You've reached {elevation} meters"
    name TEXT,              -- optional milestone name
    FOREIGN KEY (trailId) REFERENCES trail(id) ON DELETE CASCADE
);
```

### TTS Rendering (at run time)

```swift
func renderAnnouncement(_ milestone: Milestone) -> String {
    var result = milestone.message

    // Replace tokens with actual values
    result = result.replacingOccurrences(
        of: "{elevation}",
        with: String(Int(milestone.elevation))
    )
    result = result.replacingOccurrences(
        of: "{distance}",
        with: String(format: "%.1f", milestone.distance / 1000)
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
```

---

## UX Considerations

### Mobile Touch Targets
- **Minimum tap target**: 44pt × 44pt (iOS HIG)
- **Variable buttons**: Pad to at least 40pt height
- **TextEditor**: Min height 100pt (easier thumb typing)

### Keyboard Management
- **When TextEditor focused**: Keyboard appears, shift message composer down
- **"Insert Data" button**: Place below text field, not obscured by keyboard
- **Sheet/Modal**: Full-screen on iPhone, popover on iPad

### Context Switching
- **Don't hide calculated data**: Always show elevation/distance/grade at top
- **Pre-fill from milestone type**: If "Climb" is selected, show climb templates
- **Save drafts**: Auto-save message to DB on every keystroke (debounced)

### Error Handling
- **Invalid tokens**: If user types `{xyz}` but variable is `{elevation}`, silently ignore or warn
- **Empty message**: Allow (some runners may just use auto-alerts)
- **Long messages**: Warn if >200 characters (TTS will take >10 seconds)

---

## Testing on Real Device

### Preview TTS Before Saving
```swift
@State var isPreviewingVoice = false

Button(action: { previewVoice() }) {
    HStack {
        Image(systemName: "speaker.wave.2.fill")
        Text("Preview Voice")
    }
}

func previewVoice() {
    let rendered = renderAnnouncement(milestone)
    speechClient.speak(rendered)
}
```

### Test Scenarios
1. **Normal climb announcement**: "You've reached {elevation} meters at {grade}% grade. Well done!"
2. **Refuel stop**: "Refuel here at {distance} km"
3. **No variables**: "Almost there!"
4. **Long message**: Check TTS timing
5. **Special characters**: Emoji, accents (French names), numbers

---

## Summary: Recommended MVP Design

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| **Interaction** | Apple Shortcuts blue pills | Familiar, elegant, flexible |
| **Input** | TextEditor + "Insert Data" button | Simple, one-tap access to variables |
| **Visible Data** | Elevation, distance, grade at top | Context for composition |
| **Templates** | Optional type-based suggestions | Reduces friction but not required |
| **Preview** | "Preview Voice" button | Users can test TTS with substitutions |
| **Storage** | Template string with `{token}` syntax | Simple, portable, easy to parse |
| **Interaction Pattern** | Mobile-first (small buttons, clear labels) | Phone screen is 375pt wide, optimize for it |

---

## Edge Cases & Enhancements

### Phase 2 (Future)
1. **Voice selection**: User picks TTS voice (male/female/accent)
2. **Timing preview**: Show estimated speech duration
3. **Pronunciation help**: Tap word → hear how TTS pronounces it
4. **Sharing**: Share milestone messages in trail comments
5. **Smart templates**: ML suggestion based on milestone type + location name

### Known Limitations
- **Accents/special characters**: Ensure TTS handles French correctly
- **Number pronunciation**: "1,350 meters" → reads as "one thousand three hundred fifty meters" (OK)
- **No emoji in TTS**: Emojis are skipped by TTS (OK, milestones are about voice)
- **Token case sensitivity**: `{elevation}` vs `{Elevation}` — standardize to lowercase

---

## References

- Apple HIG Text Fields: https://developer.apple.com/design/human-interface-guidelines/text-fields
- Apple Shortcuts Variable Design: https://support.apple.com/guide/shortcuts/use-variables-apdd02c2780c/ios
- SwiftUI TextEditor: https://developer.apple.com/documentation/swiftui/texteditor
- AVSpeechSynthesizer: https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer
