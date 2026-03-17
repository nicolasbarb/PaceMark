# Quick Reference: Milestone Voice Announcements Feature

**Feature Goal**: Trail runners compose personalized voice milestones at specific trail locations, mixing custom text with auto-calculated data (elevation, distance, gradient).

---

## User Workflow

```
1. User imports GPX trail
2. User taps map/profile → places milestone at location
3. Sheet opens with:
   - Type selector (Climb/Descent/Refuel/Danger/Info)
   - Message text field (editable)
   - "Insert Data" button
   - "Preview Voice" button
4. User types message: "You've reached [elevation] meters!"
5. User taps "Insert Data" → modal shows variables:
   - {elevation}   1,350 m
   - {distance}    12.4 km
   - {grade}       8%
6. User taps {elevation} → variable inserted as blue pill token
7. Message now reads: "You've reached {elevation} meters!"
8. User taps "Preview Voice" → TTS speaks: "You've reached 1350 meters!"
9. User taps "Save" → milestone stored with template + type
10. During run: when user reaches location within 30m, TTS announces the message with values substituted
```

---

## Key Variables

| Variable | Value Example | Display | Token |
|----------|---------------|---------|-------|
| Elevation | 1,350 meters | "1350 m" | `{elevation}` |
| Distance | 12.4 kilometers | "12.4 km" | `{distance}` |
| Grade | 8.2% | "8%" | `{grade}` |
| Milestone Name | Col de Croix | "Col de Croix" | `{milestone_name}` |

---

## UI Pattern (Shortcuts-Inspired)

### Message Composition Screen

```
┌─────────────────────────────────┐
│ Edit Milestone              [X] │
├─────────────────────────────────┤
│                                 │
│ 1,350 m  |  12.4 km  |  8%      │  ← Context (always visible)
│                                 │
│ Type: ◉ Climb                   │
│                                 │
│ Message:                        │
│ ┌─────────────────────────────┐ │
│ │ You've reached {elevation}  │ │
│ │ meters at {grade}% grade    │ │
│ │                             │ │
│ │ Cursor here •               │ │
│ └─────────────────────────────┘ │
│                                 │
│ [ Insert Data ▼ ] [ Preview 🔊 ]│
│                                 │
├─────────────────────────────────┤
│       [Cancel]      [Save]      │
└─────────────────────────────────┘
```

### Variable Picker (Modal/Sheet)

```
┌─────────────────────────────────┐
│ Available Variables             │
├─────────────────────────────────┤
│                                 │
│ ◉ elevation          1,350 m    │
│                                 │
│ ◉ distance           12.4 km    │
│                                 │
│ ◉ grade              8%         │
│                                 │
│ ◉ milestone_name    Col de Croix│
│                                 │
├─────────────────────────────────┤
│            [Dismiss]            │
└─────────────────────────────────┘
```

---

## Success Metrics (MVP)

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| **Feature Adoption** | 60%+ users compose ≥1 milestone | Core feature engagement |
| **Preview Engagement** | 40%+ tap "Preview Voice" | Users testing announcements |
| **Milestone Density** | 3-5 per 10km trail | Reasonable course checkpoints |
| **NPS on Feature** | 40+ | Early adopter satisfaction |
| **Avg Composition Time** | <2 minutes/milestone | Speed vs. competitors |

---

## Competitive Differentiation

### What TrailMark Does (Unique)
- ✓ Custom text composition at specific trail locations
- ✓ Auto-calculated data (elevation, distance, gradient)
- ✓ Variable substitution in voice announcements
- ✓ Preview TTS before run
- ✓ Trail-specific roadbook (not generic intervals)

### What Competitors Do (Static)
- Strava: "You've completed 1 kilometer" (fixed)
- Nike Run Club: "Pace update" (fixed)
- Runkeeper: Configurable intervals, same template
- iSmoothRun: Metrics-based ("Your pace is 5:30/km")

---

## Composition Examples

### Climb Milestone
```
Type: Climb
Message: You've reached {elevation} meters elevation!
         The summit is at 2,642m. Keep pushing, you've got {grade}% grade ahead!

Rendered (during run):
"You've reached 1,850 meters elevation! The summit is at 2,642 meters.
Keep pushing, you've got 9% grade ahead!"
```

### Descent Milestone
```
Type: Descent
Message: Long descent ahead at {grade}% grade. Watch your footing!

Rendered:
"Long descent ahead at 6% grade. Watch your footing!"
```

### Refuel Milestone
```
Type: Refuel
Message: Refuel station at {distance} km. Grab water and calories!

Rendered:
"Refuel station at 18.5 km. Grab water and calories!"
```

### Info Milestone
```
Type: Info
Message: {milestone_name} - {elevation}m elevation, {distance}km from start

Rendered:
"Col de Croix - 2350m elevation, 24.2km from start"
```

---

## Implementation Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **MVP** | 8-10 weeks | Basic composition UI, variable insertion, TTS rendering |
| **Polish** | 4-6 weeks | Templates by type, pronunciation improvements |
| **Growth** | 8-12 weeks | Trail sharing, B2B race integrations |

---

## Technical Stack
- **UI**: SwiftUI (TextEditor + custom variable picker)
- **Architecture**: TCA (Composable Architecture)
- **Database**: SQLite-Data (template strings stored with {token} syntax)
- **TTS**: AVSpeechSynthesizer (French voice)
- **Storage**: `message TEXT` field in milestone table

---

## Rollout Strategy

### Beta Phase (Week 1-2)
- 20-30 trail runners test composition UI
- Feedback on variable insertion UX
- Edge case handling (long messages, special characters)

### Soft Launch (Week 3)
- Feature available to all TrailMark users
- In-app tutorial: "How to compose milestones"
- Email: "New feature — personalized voice announcements"

### Marketing (Week 4+)
- Blog: "Your personalized trail roadbook"
- Reddit: r/trailrunning, r/ultrarunning
- Race partnerships: "TrailMark milestones for [Event Name]"

---

## FAQ

**Q: What if a variable isn't available?**
A: Token remains unchanged. Example: `{milestone_name}` stays as-is if not set by user.

**Q: Can users type custom tokens?**
A: No. Only predefined variables (elevation, distance, grade, milestone_name) are substituted.

**Q: How long can a message be?**
A: No hard limit, but >200 characters = >10 seconds TTS playback (warn user).

**Q: What if GPS signal is lost?**
A: Milestone won't trigger (can add manual trigger option in future).

**Q: Can users share milestones?**
A: MVP: No. Phase 2: Yes (export trail with milestones, share GPX).

**Q: Does this work on Apple Watch?**
A: MVP: No. Phase 3: Display milestone text on watch + trigger audio.

**Q: What about other languages (not French)?**
A: MVP: French only (set in TTS). Phase 2: User choice of language/voice.

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| **TTS pronunciation** (French names) | Test with French voice, allow pronunciation override in Phase 2 |
| **UI complexity** (users confused by variables) | Provide templates, in-app tutorial, "Insert Data" button always visible |
| **Empty messages** (runners don't compose) | Allow optional messages, use type-based templates as fallback |
| **Long messages** | Warn if >200 chars, estimate TTS duration |
| **GPS accuracy** | 30m trigger radius, add manual trigger option |

---

## Decision Log

**Q: Why blue pill tokens (vs. other patterns)?**
A: Matches Apple Shortcuts (familiar to iOS users), visually distinct from plain text, flexible for mixed content.

**Q: Why {token} syntax (vs. $token or [TOKEN])?**
A: Matches Notion, Handlebars conventions. Clear when surrounded by text.

**Q: Why type selector (Climb/Descent/etc.)?**
A: Provides context for templates + visual differentiation in editor UI.

**Q: Why preview voice button?**
A: Users can test TTS pronunciation, hearing duration, before saving.

**Q: Why not allow free-form text only?**
A: Auto-calculated data (elevation, distance, grade) creates unique value; variables make data insertion explicit.

---

## Product Owner Checklist

- [ ] Feature user story written & accepted
- [ ] Design mockups reviewed with team
- [ ] Competitive analysis complete
- [ ] Success metrics defined
- [ ] Engineering estimate obtained (8-10 weeks)
- [ ] Marketing brief drafted
- [ ] Beta user list (20-30 early adopters)
- [ ] Release notes outline complete
- [ ] App Store screenshot/description prepared
- [ ] Support FAQ prepared

---

## Links to Detailed Docs

1. **RESEARCH_STRUCTURED_MESSAGE_COMPOSITION.md** — Deep research on Shortcuts, Duolingo, IFTTT, running apps
2. **DESIGN_MILESTONE_COMPOSITION_PATTERNS.md** — UI mockups, interaction flows, SwiftUI code sketches
3. **PRODUCT_STRATEGY_VOICE_MILESTONES.md** — Market analysis, competitive positioning, monetization
4. **IMPLEMENTATION_GUIDE_MILESTONE_MESSAGES.md** — Engineering specs, TCA reducers, database schema, testing

---

## Contact & Questions

- **Product**: Ask about feature scope, timeline, success metrics
- **Design**: Ask about UI patterns, interaction flows, edge cases
- **Engineering**: Ask about architecture, dependencies, testing
- **Marketing**: Ask about positioning, messaging, launch plan

---

**Last Updated**: 2026-03-14
**Feature Owner**: Product Manager (TrailMark)
**Status**: Design & Research Complete → Ready for Engineering Review
