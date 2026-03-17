# Research: Structured Message Composition on Mobile

Goal: Understand how real-world apps let users compose announcements from pre-built blocks with auto-calculated and custom data. Applied to TrailMark's milestone voice announcement feature.

Date: 2026-03-14

---

## 1. Apple Shortcuts — The Gold Standard for Variable Composition

### How It Works
Apple Shortcuts implements a **magic variable** system that lets users compose text by inserting dynamic data from previous actions.

#### Visual Design
- **Variables appear as blue pill-shaped tokens** in text fields
- When a user taps a text field, the Variables bar + keyboard appear
- Users tap "Select Variable" to see all available outputs from previous actions as visual tokens
- Variables are placed **inline in the text** (at cursor position), maintaining their blue pill appearance to distinguish from plain text

#### Interaction Pattern
1. User edits a text field (like "Text" action)
2. Taps the field → Variables bar appears automatically
3. Taps "Select Variable" → Shows all available magic variables as blue tokens
4. Taps the desired variable token → Inserts it inline at cursor position
5. Mixed: plain text + variables = "You've climbed 450m, great job!" (where "450m" is a variable token)

#### Key Design Principles
- **Discoverability**: Variables always visible in a contextual bar, not hidden in menus
- **Type Safety**: Each action output is clearly labeled with its type (Text, Number, Date, etc.)
- **Inline Insertion**: Variables stay visually distinct even when embedded in plain text
- **No Parameter Limits**: Can insert variables anywhere (not restricted to placeholders)

### Strengths
- Works excellently on phone: Variables bar is always accessible
- Clear visual distinction (blue pills) prevents confusion
- Users can mix free-form text with calculated data seamlessly
- Responsive to available data sources

### Weaknesses
- Variable insertion requires a tap + modal interaction (not drag-drop)
- For non-technical users, understanding "what variables are available" requires context exploration
- Desktop-first design that was adapted to mobile

**Source**: [Apple Shortcuts - Use Variables Guide](https://support.apple.com/guide/shortcuts/use-variables-apdd02c2780c/ios)

---

## 2. Duolingo — Drag & Drop Word Bank Pattern

### How It Works
Duolingo uses a two-pile drag-and-drop system for sentence composition.

#### Interaction Pattern
- **Word Bank**: Bottom list of word options (tiles/buttons)
- **Answer Area**: Top/center region where words are dropped
- Users drag words from bank → drop in answer area to compose sentence
- Words snap into position; some implementations allow reordering dropped words

#### Technical Details
- Built with `react-native-gesture-handler` & `react-native-reanimated`
- Customizable properties: word height, spacing, line height
- Support for RTL languages
- No word reuse unless explicitly allowed

### Why This Works
- **Tactile & Direct**: Drag-drop feels more natural than menu selection
- **Constrained Choices**: Word bank prevents typos and invalid composition
- **Visual Clarity**: Users see all options at once (no hidden menus)
- **Reversible**: Can drag words back to bank to undo

### Weaknesses
- Requires **gesture handler library** (adds dependency)
- Not great for **many options** (screen real estate limited)
- Reordering can be cumbersome on small screens
- No "free text" option (only predefined words)

**Source**: [GitHub - RafaelGoulartB/duolingo-drag-and-drop](https://github.com/RafaelGoulartB/duolingo-drag-and-drop)

---

## 3. IFTTT / Zapier — Trigger-Action Composition

### IFTTT Pattern
IFTTT uses a simple **one trigger + one action** model with parameter selection.

#### Interaction
- User selects a trigger service (e.g., "Location enters a zone")
- App shows **trigger parameters** as discrete fields (text inputs, dropdowns, etc.)
- User selects an action service (e.g., "Send notification")
- App shows **action parameters** as similar fields
- Each parameter can be mapped to trigger data or entered manually

#### Interface Design
- **Card-based layout**: Each step (trigger/action) is a card with labeled fields
- **Conditional exposure**: Shown parameters depend on previous selections
- **Dropdowns for selection**, text fields for custom input
- Mobile app: large tap targets, clear field labels

#### Limitations
- Fixed trigger → fixed action (no complex logic)
- Parameters are isolated fields, not a unified text composition

### Zapier Pattern (More Advanced)
- Allows **multiple actions** per trigger
- Supports **conditional logic** (if/then)
- Still uses field-based interface, not text composition

### Relevance to TrailMark
- Good for **discrete data insertion** (altitude, distance as separate fields)
- Poor for **free-form announcement composition** (users want to type naturally)

**Sources**:
- [IFTTT vs Zapier Research](https://latenode.com/blog/platform-comparisons-alternatives/zapier-alternatives/zapier-vs-ifttt-which-is-the-best-in-2025/)
- [Zapier Comparison](https://clickup.com/blog/zapier-vs-ifttt/)

---

## 4. Running Apps — Voice Announcement Customization

### iSmoothRun
**Voice Cue Customization:**
- Interval-based: time (every N minutes) or distance (every N km/miles)
- Selectable metrics: time, distance, pace, speed, altitude, cadence, heart rate
- Pre-recorded voice announcements (no TTS)
- Simple settings panel: toggle metrics on/off, set intervals, choose voice

**Limitations:**
- Fixed announcement templates, no custom text
- Data presentation is standardized ("500 meters", "12:45 pace")

### Nike Run Club
**Audio Feedback:**
- Binary: enable/disable voice feedback
- Limited customization: choose voice gender (male/female)
- Pre-defined announcement templates only
- No custom milestone announcements

### Strava
**Audio Cues:**
- Only for runs (not other activity types)
- Interval customization: every 0.5 km, 1 km, 0.5 mile, 1 mile
- No text customization; announcements are hardcoded
- Start/stop/pause announcements only

### Runkeeper
**Audio Cues:**
- **Most flexible of the bunch**
- Time-based or distance-based triggers
- Selectable stats: pace, heart rate, distance, etc.
- Appears to support custom text composition via event organizer features
- Voice ducking: lowers background music during announcement

**Key Insight:**
None of these apps let runners **freely compose custom milestone announcements**. They all use fixed templates. TrailMark would be differentiated if it allows:
- Pick a milestone location (on map or elevation profile)
- Type/compose a custom announcement
- Optionally insert calculated data (elevation, distance from start, grade %)
- Hear it read aloud by TTS

**Sources:**
- [iSmoothRun Features](http://www.ismoothrun.com/features.html)
- [Nike Run Club Customization](https://www.nike.com/help/a/customize-nrc)
- [Strava Audio Announcements](https://support.strava.com/hc/en-us/articles/216917237-Audio-Announcements)
- [Runkeeper Audio Cues Guide](https://runkeeper.com/cms/app/audio-cues-in-the-runkeeper-app/)

---

## 5. WhatsApp Business — Quick Replies Template Pattern

### How It Works
WhatsApp Business offers pre-saved message templates (called "Quick Replies").

#### Interface
- Up to 50 quick replies per account
- Assign a shortcut (text trigger): "/hours" → "We're open 9-5"
- During chat: type shortcut → quick reply suggestion appears → tap to insert
- **Not editable on insertion** (must edit template in settings to change)

#### Mobile Experience
- Minimal friction: type "/" → suggestion appears
- Keyboard-first interaction (chat interface)
- No variable composition at insertion time

#### Limitations
- No variables/dynamic data
- Templates are static
- Requires settings management (not inline composition)

**Why This Is Different from TrailMark Need:**
WhatsApp's model is good for **reusable static responses**. TrailMark needs **composable, calculated announcements** (with elevation, distance data).

**Source**: [WhatsApp Quick Replies Guide](https://controlhippo.com/blog/whatsapp/whatsapp-quick-reply/)

---

## 6. Typeform / Jotform — No-Code Mobile Builders

### Typeform
- 100% mobile-responsive forms
- Template library with pre-built flows
- Drag-drop builder (desktop-first, mobile viewing)
- No variable composition in final form; collection happens during form fill

### Jotform
- Drag-drop form builder on mobile (iOS 15.1+)
- Create from scratch or use 10,000+ templates
- Field types: text, email, phone, dropdown, checkbox, etc.
- Can reorder fields, customize labels

#### Mobile Design Pattern
- **Drag items from library** into canvas
- **Tap field to edit** (opens property panel)
- **Preview mode** to test on mobile layout

### Relevance to TrailMark
- Good for **structured data collection** (which milestone, what type, etc.)
- Not ideal for **text composition** (forms focus on data capture, not generation)

**Sources:**
- [Typeform Mobile Creator](https://www.typeform.com/help/a/create-forms-on-mobile-360057243192/)
- [Jotform Mobile Apps](https://www.jotform.com/products/apps/)

---

## 7. Slack Block Kit — Structured Message Composition

### How It Works (Desktop/Web, Mobile Adapted)
Slack's Block Kit is a UI framework for composing rich messages with formatted text blocks.

#### Message Composition Elements
- **Text formatting buttons**: Bold, italics, strikethrough, code, lists, blockquotes
- **Press Aa button** to reveal formatting panel
- **Use mrkdwn syntax** for semantic formatting (bold, italics, links)
- Can compose **multiple sections** (headers, body, footer)

#### Blocks in Messages
- `text_section`: Single line of formatted text
- `rich_text_block`: Complex layouts with mixed formatting
- Each block can include **rich_text** with inline formatting

#### Mobile Adaptation
- Formatting buttons appear in **bottom toolbar**
- Simpler layout than desktop (some blocks render differently)
- Still **contextually accessible** (not hidden in menus)

### Design Lessons
- **Formatting is secondary**: Composition is free-form text first
- **Toolbars stay visible** and contextual
- **Mobile-responsive**: Fewer buttons on smaller screens
- **Shift+Enter for line breaks** (not automatic new-line behavior)

**Source**: [Slack Developer Docs - Message Composition](https://docs.slack.dev/messaging/composing/)

---

## 8. Notion — Database Templates with Variables

### How It Works
Notion allows creating database templates where new entries inherit predefined properties and optional placeholder values.

#### Template + Variables Pattern
- Create a template with default property values (e.g., Priority = P1, Status = Open)
- **Button variables**: Define custom @variable fields (e.g., @UserName, @CurrentTime)
- When creating new page from template, placeholders are auto-filled
- Users can edit variables via button UI before page is created

#### Mobile Experience
- Templates shown in database view
- Tap "New" → Select template → Template properties are pre-filled
- Can edit properties inline or in expanded view
- Variables are **resolved at creation time**, not composition time

### Design Pattern
- **Templates reduce friction** for common data entry
- **Variables auto-fill** calculated values (time, user, etc.)
- **Property-based interface**: Not text composition, but structured data

### Relevance to TrailMark
- Templates are good for **milestone categories** (Climb, Descent, Refuel, Danger)
- But TrailMark needs **text composition**, not just property selection

**Source**: [Notion Database Templates Help](https://www.notion.com/help/database-templates)

---

## 9. iOS Notification Custom Actions — Parameter Model

### How It Works
iOS notifications can have **custom action buttons** with parameters, but this is developer-facing, not user-facing.

#### Developer API
- Define `UNNotificationAction` with: identifier (unique ID), title (visible text), options (foreground/destructive)
- Group actions into `UNNotificationCategory`
- When user taps action button, app receives identifier + response text (if `UNTextInputNotificationAction`)

#### Mobile Interface
- Custom action buttons appear at **bottom of notification**
- Can be inline (1-2 buttons) or expanded (up to 4)
- User sees **title only**, not parameters

#### Why This is NOT Applicable to TrailMark
- Notification actions are declarative (defined at code time, not by users)
- No user-facing composition; just selecting pre-defined actions
- Response data is simple text input, not structured

**Source**: [Apple Developer - Custom Notification Actions](https://developer.apple.com/documentation/usernotifications/declaring-your-actionable-notification-types)

---

## Summary Table: Interaction Patterns

| App | Pattern | Strengths | Weaknesses | Mobile Fit |
|-----|---------|-----------|-----------|-----------|
| **Apple Shortcuts** | Magic Variables (blue pill tokens, inline insertion) | Clear visual distinction, flexible, contextual | Requires tap+modal | Excellent |
| **Duolingo** | Drag-drop word bank | Tactile, constrained, reversible | Limited options, dependency | Very Good |
| **IFTTT/Zapier** | Trigger-action with field-based parameters | Structured, clear data flow | Not text composition, rigid | Good |
| **iSmoothRun** | Settings panel with toggle metrics | Simple, proven UX | No custom text | N/A (not for composition) |
| **Strava** | Simple cue intervals | Minimalist | No customization | N/A (not for composition) |
| **Runkeeper** | Interval + metric selection | Flexible triggers | Still templated | N/A (not for composition) |
| **WhatsApp** | Static quick reply templates | Keyboard-first, minimal friction | No variables, static | Good (but limited) |
| **Typeform/Jotform** | Drag-drop form builder | Flexible field reordering | Desktop-first, form-focused | Moderate |
| **Slack** | Formatting toolbar + free text | Composition-friendly, accessible | Some formatting hidden | Good |
| **Notion** | Templates + pre-filled properties | Reduces friction, auto-fills data | Not for text composition | Moderate |

---

## Recommendations for TrailMark Milestone Voice Announcements

### Desired Interaction Flow
1. **User places a milestone** on the elevation profile or map
2. **Milestone settings panel opens** with:
   - Milestone type dropdown (Climb, Descent, Refuel, Danger, Info)
   - **Text composition field** (the milestone message/announcement)
   - Optional: pre-filled data (elevation, distance, grade %)
3. **Composition interface options** (rank by mobile suitability):

#### Option A: Apple Shortcuts-Inspired (RECOMMENDED)
- **Text input field** where user types the announcement
- **"Insert Data" button** → shows available variables (elevation, distance, gradient)
- **Tap variable** → inserts as blue pill token inline in text
- Example: "You've reached [elevation] meters elevation. Great effort!" where [elevation] is a token
- Strength: Familiar to iOS users, clear visual distinction, flexible
- Implementation: Custom SwiftUI component with TextEditor + overlay variable selection

#### Option B: Duolingo-Inspired (Word Bank)
- **List of milestone phrases** (pre-written templates with variables)
- **Drag phrases from list** → drop into composition area in order
- Example drag options: "You've reached", "[elevation] meters", "Great job!"
- Strength: Constrained, no typos, tactile
- Weakness: Requires more predefined content, less flexible

#### Option C: Slack-Inspired (Formatting Toolbar)
- **Text field** for free composition
- **Toolbar with common variables** (elevation, distance, grade, time)
- **Tap variable button** → inserts placeholder syntax like [ELEVATION] or $elevation
- Strength: Simple, keyboard-friendly
- Weakness: Less visual distinction, harder to see which placeholders are active

#### Option D: Hybrid (Recommended for MVP)
- **Template suggestions** based on milestone type (pre-populated)
- **Text field** (editable)
- **Single "Insert Value" button** (not toolbar)
- Tap button → modal appears with available variables → tap one → inserts at cursor
- Simpler than A, more discoverable than C, less interaction than B
- Example:
  - Milestone type: "Climb"
  - Pre-filled text: "You've reached the top!"
  - User can edit to: "You've reached [elevation] meters. Perfect!"
  - Tap "Insert Value" → see options: [elevation], [distance], [grade]

---

## Technical Implementation Guidance

### Data to Auto-Calculate & Make Available
For each milestone, pre-calculate:
1. **Elevation** (m): From track point at milestone location
2. **Distance from start** (km): Cumulative distance
3. **Gradient at milestone** (%): Change in elevation / horizontal distance
4. **Time to reach** (if pace available): Extrapolated from runner's current pace
5. **Name** (optional): User-provided location name (e.g., "Col de Croix")

### Text Composition Storage
- Store milestone message in database as a **template string**:
  - Plain text: "Well done!"
  - With variables: "You've reached `{elevation}` meters at `{grade}`%"
  - On playback: Replace `{elevation}` → "1250", `{grade}` → "12" → Read: "You've reached 1250 meters at 12 percent"

### Variable Syntax Options (for storage)
1. **Curly braces**: `{elevation}`, `{distance}` (similar to Notion, widely understood)
2. **Dollar sign**: `$elevation`, `$distance` (shell/scripting convention)
3. **Brackets**: `[ELEVATION]`, `[DISTANCE]` (WhatsApp style)
4. **Double curly**: `{{elevation}}`, `{{distance}}` (Handlebars style)

**Recommendation**: Use `{elevation}`, `{distance}`, `{grade}` — widely recognized, clean syntax.

### SwiftUI Implementation Pattern (Option A Recommended)

```swift
// Pseudocode structure for Shortcuts-inspired approach

struct MilestoneCompositionView {
    @State var messageText: String = ""
    @State var showVariables: Bool = false

    let availableVariables: [MilestoneVariable] = [
        .elevation(Double), .distance(Double), .grade(Double)
    ]

    var body: some View {
        VStack {
            // Text composition field
            TextEditor(text: $messageText)
                .frame(minHeight: 100)
                .border(Color.gray)

            HStack {
                Button("Insert Data") {
                    showVariables.toggle()
                }
            }

            // Variables panel (bottom sheet or popover)
            if showVariables {
                VariableSelectionView(
                    variables: availableVariables,
                    onSelect: { variable in
                        insertVariable(variable)
                    }
                )
            }
        }
    }

    func insertVariable(_ variable: MilestoneVariable) {
        let token = "{" + variable.key + "}"
        messageText.insert(contentsOf: token, at: messageText.endIndex)
    }
}
```

### TTS Playback (at run time)
```swift
// Pseudocode for TTS with variable substitution

func playMilestoneAnnouncement(milestone: Milestone) {
    let template = milestone.message // "You've reached {elevation} meters"
    let resolved = template
        .replacingOccurrences(of: "{elevation}", with: String(Int(milestone.elevation)))
        .replacingOccurrences(of: "{distance}", with: String(format: "%.1f", milestone.distance / 1000))
        .replacingOccurrences(of: "{grade}", with: String(format: "%.0f", milestone.grade))

    speechClient.speak(resolved)
}
```

---

## Competitive Differentiation

**Current State (Running Apps):**
- iSmoothRun, Nike Run Club, Strava, Runkeeper: Fixed announcement templates
- None allow custom milestone announcements with variable data insertion

**TrailMark Opportunity:**
- "Compose your own milestone voice announcements"
- Mix free-form text + auto-calculated data (elevation, distance, grade)
- Unique to trail running use case: voice milestones tailored to specific course features

**Marketing Angle:**
- "Your personalized voice roadbook" — each milestone announcement is authored by the runner
- vs. generic "You've reached 5km" → "You've reached 1350m elevation. You're crushing it!"

---

## References & Sources

1. [Apple Shortcuts - Use Variables Guide](https://support.apple.com/guide/shortcuts/use-variables-apdd02c2780c/ios)
2. [GitHub - duolingo-drag-and-drop](https://github.com/RafaelGoulartB/duolingo-drag-and-drop)
3. [IFTTT vs Zapier Comparison](https://latenode.com/blog/platform-comparisons-alternatives/zapier-alternatives/zapier-vs-ifttt-which-is-the-best-in-2025/)
4. [iSmoothRun Features](http://www.ismoothrun.com/features.html)
5. [Nike Run Club Customization](https://www.nike.com/help/a/customize-nrc)
6. [Strava Audio Announcements](https://support.strava.com/hc/en-us/articles/216917237-Audio-Announcements)
7. [Runkeeper Audio Cues Guide](https://runkeeper.com/cms/app/audio-cues-in-the-runkeeper-app/)
8. [WhatsApp Quick Replies Guide](https://controlhippo.com/blog/whatsapp/whatsapp-quick-reply/)
9. [Typeform Mobile Creator](https://www.typeform.com/help/a/create-forms-on-mobile-360057243192/)
10. [Jotform Mobile Apps](https://www.jotform.com/products/apps/)
11. [Slack Developer Docs - Message Composition](https://docs.slack.dev/messaging/composing/)
12. [Notion Database Templates Help](https://www.notion.com/help/database-templates)
13. [Apple Developer - Custom Notification Actions](https://developer.apple.com/documentation/usernotifications/declaring-your-actionable-notification-types)
