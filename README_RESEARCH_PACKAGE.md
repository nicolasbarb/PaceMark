# TrailMark: Milestone Voice Announcements — Complete Research Package

**Objective**: Enable trail runners to compose personalized voice announcements for specific course milestones, blending custom text with auto-calculated data.

**Date**: 2026-03-14
**Status**: Research Complete, Ready for Engineering Review & MVP Planning

---

## Package Contents

This package contains four comprehensive documents:

### 1. **RESEARCH_STRUCTURED_MESSAGE_COMPOSITION.md** (Primary Research)
**Length**: ~5,000 words | **Audience**: Product, Design, Engineering

Deep analysis of real-world apps that implement structured message composition:
- Apple Shortcuts (magic variables, blue pill tokens)
- Duolingo (drag-drop word bank)
- IFTTT/Zapier (trigger-action composition)
- Running apps (Strava, Nike Run Club, Runkeeper, iSmoothRun)
- WhatsApp Business (quick reply templates)
- Typeform/Jotform (form builders)
- Slack (block kit message composition)
- Notion (database templates with variables)
- iOS notifications (custom actions)

**Key Insight**: No running app currently allows custom announcement composition. TrailMark can differentiate by offering user-authored, data-driven milestone announcements.

**Recommended Pattern**: Apple Shortcuts-inspired blue pill variable insertion — familiar to iOS users, flexible, works well on phone screens.

---

### 2. **DESIGN_MILESTONE_COMPOSITION_PATTERNS.md** (UI/UX Design)
**Length**: ~4,000 words | **Audience**: Design, Product, Engineering

Concrete UI mockups, interaction flows, and SwiftUI code sketches for three design options:

**Option A: Apple Shortcuts-Inspired (RECOMMENDED)**
- Text field + "Insert Data" button
- Modal sheet with available variables
- Variables appear as blue pill tokens in message
- Minimal UI overhead, familiar interaction

**Option B: Hybrid Template + Variables (Simpler Alternative)**
- Type-based templates (pre-filled suggestions)
- Custom message editor
- Inline variable buttons
- Better for users in a hurry

**Option C: Duolingo-Inspired Word Bank (Most Engaging)**
- Drag-drop phrase composition
- More interaction overhead but more engaging
- Best for future polish iteration

**Includes**:
- Full screen mockups (ASCII)
- SwiftUI code structures
- Data model for milestone types & variables
- TTS rendering logic
- Edge case handling
- Mobile UX considerations (44pt tap targets, keyboard management)

---

### 3. **PRODUCT_STRATEGY_VOICE_MILESTONES.md** (Strategy & Positioning)
**Length**: ~3,500 words | **Audience**: Product, Leadership, Marketing

Market analysis, competitive positioning, and business strategy:

**Competitive Differentiation**:
- Strava: Generic "5km" announcements
- Nike Run Club: Predefined voice feedback only
- Runkeeper: Time/distance intervals, no custom text
- iSmoothRun: Metrics-based, no personalization
- **TrailMark**: Trail-specific, user-authored, data-driven

**Value Proposition**: "Your personalized voice roadbook for trail running"

**Market Size**: 5-10M global trail runners; TAM estimate 50K-500K in Year 1

**Monetization**:
- Freemium: 5 trails / 10 milestones free
- Premium: Unlimited trails, custom voice selection ($4.99/month)
- B2B: Race organizers ($200-500 per event)

**Success Metrics**:
- 60%+ users compose ≥1 milestone
- 40%+ preview TTS before saving
- 3-5 milestones per 10km trail
- NPS 40+ early adopters
- <2 minutes average composition time

**Go-to-Market**:
- Beta program (20-30 trail runners)
- Targeted ads (Reddit, Google)
- Race partnerships
- Micro-influencer seeding

---

### 4. **IMPLEMENTATION_GUIDE_MILESTONE_MESSAGES.md** (Engineering)
**Length**: ~3,500 words | **Audience**: Engineering, Tech Lead

Complete technical specification for implementation:

**Data Model Updates**:
```swift
struct Milestone {
    let id, trailId, pointIndex: Int64
    let latitude, longitude, elevation, distance: Double
    var type: MilestoneType           // NEW
    var message: String               // NEW (template string)
    var name: String?                 // optional
}

enum MilestoneType: Climb, Descent, Refuel, Danger, Info
enum MilestoneVariable: elevation, distance, grade, milestone_name
```

**Database Schema**:
```sql
ALTER TABLE milestone ADD COLUMN type TEXT NOT NULL DEFAULT 'info';
ALTER TABLE milestone ADD COLUMN message TEXT DEFAULT '';
```

**TCA Reducers**:
- `EditorFeature` — adds milestone composition sheet
- `MilestoneCompositionFeature` — handles message editing & variable insertion
- `RunFeature` — updates for TTS rendering with variable substitution

**SwiftUI Views**:
- `MilestoneCompositionView` — main editor UI
- `VariableSelectorSheet` — modal for variable selection

**TTS Implementation**:
```swift
func renderMessage(template: String, milestone: Milestone) -> String {
    var result = template
    result = result.replacingOccurrences(of: "{elevation}", with: String(Int(milestone.elevation)))
    result = result.replacingOccurrences(of: "{distance}", with: String(format: "%.1f", milestone.distance / 1000))
    result = result.replacingOccurrences(of: "{grade}", with: String(format: "%.0f", milestone.grade))
    if let name = milestone.name {
        result = result.replacingOccurrences(of: "{milestone_name}", with: name)
    }
    return result
}
```

**Testing**:
- Unit tests for message rendering
- Integration tests for composition feature
- Device testing for TTS latency & French pronunciation

**Timeline**: 8-10 weeks MVP, 4-6 weeks polish, 8-12 weeks growth

---

### 5. **QUICK_REFERENCE_MILESTONE_VOICES.md** (At-a-Glance Guide)
**Length**: ~1,500 words | **Audience**: Everyone (product, design, eng, marketing)

One-page reference with:
- User workflow (step-by-step)
- Key variables table
- UI mockup (ASCII)
- Success metrics
- Competitive comparison
- FAQ
- Risk mitigation
- Decision log

---

## How to Use This Package

### For Product Managers
1. Read QUICK_REFERENCE (5 min)
2. Read PRODUCT_STRATEGY (20 min)
3. Use as foundation for PRD (Product Requirements Document)

### For Design
1. Read QUICK_REFERENCE (5 min)
2. Study DESIGN_PATTERNS (30 min)
3. Translate mockups to Figma designs
4. Plan design review with team

### For Engineering
1. Read QUICK_REFERENCE (5 min)
2. Review IMPLEMENTATION_GUIDE (45 min)
3. Estimate effort (should be 8-10 weeks)
4. Plan sprint breakdown

### For Marketing
1. Read QUICK_REFERENCE (5 min)
2. Skim PRODUCT_STRATEGY (15 min)
3. Draft launch messaging & positioning
4. Plan beta user recruitment

---

## Key Findings & Recommendations

### Pattern Recommendation: Apple Shortcuts-Inspired

**Why This Pattern?**
1. **Familiar to iOS Users**: Matches system behavior
2. **Flexible**: Handles mixed text + variables elegantly
3. **Mobile-Optimized**: One-button access to variables (not drowning in toolbars)
4. **Visual Clarity**: Blue pill tokens distinguish variables from plain text
5. **Scalable**: Works for 1 variable or 5 variables

**Alternative Patterns** (if time allows):
- Hybrid Template + Variables (simpler, less flexible)
- Duolingo Word Bank (more engaging, higher interaction cost)

### Variable Strategy: {token} Syntax

Token format in storage:
```
"You've reached {elevation} meters at {grade}% grade. {milestone_name} awaits!"
```

Variables available per milestone:
- `{elevation}` → "1350" (meters)
- `{distance}` → "12.4" (kilometers)
- `{grade}` → "8" (percent)
- `{milestone_name}` → "Col de Croix" (if provided by user)

### Competitive Differentiation

**Unique to TrailMark**:
- ✓ Custom text composition (not templated)
- ✓ Auto-calculated data (elevation, distance, gradient)
- ✓ Trail-specific (not generic kilometer intervals)
- ✓ Variable substitution in voice announcements
- ✓ Preview TTS before running

**Not offered by any competitor** (Strava, Nike, Runkeeper, iSmoothRun)

---

## Success Criteria (MVP)

| Area | Criteria |
|------|----------|
| **Feature Adoption** | 60%+ users place ≥1 milestone |
| **Engagement** | 40%+ preview voice before saving |
| **User Satisfaction** | NPS 40+ (early adopters) |
| **Speed** | <2 min to compose milestone |
| **Quality** | <1% error rate in variable substitution |

---

## Implementation Roadmap

### Phase 1: MVP (Weeks 1-10)
- Core composition UI (TextEditor + variable insertion)
- TTS rendering with variable substitution
- Preview voice button
- Database schema updates
- Testing on real device

### Phase 2: Polish (Weeks 11-16)
- Type-based templates
- Trail sharing
- Pronunciation improvements
- Analytics

### Phase 3: Growth (Weeks 17-28)
- B2B race organizer integration
- Community trail sharing
- Leaderboards
- Apple Watch support

---

## Decision Log

**Q: Why allow variables instead of just free-form text?**
A: Auto-calculated data (elevation, distance, gradient) is unique value. Variables make insertion explicit & discoverable.

**Q: Why type selector (Climb/Descent/etc.)?**
A: Provides context for templates, visual differentiation, and better analytics.

**Q: Why blue pill tokens?**
A: Matches Apple Shortcuts (familiar), visually distinct from plain text, works well on small screens.

**Q: Why "Insert Data" button instead of toolbar?**
A: Single tap to access variables; toolbar would clutter small screen. Interaction follows "action-discovery" pattern.

**Q: Why 30m trigger radius?**
A: GPS accuracy on trails is ±10-20m; 30m provides buffer without over-triggering. Can adjust per user in future.

**Q: Why French TTS first?**
A: TrailMark launches with French trails; can expand to other languages in Phase 2.

---

## Assumptions & Risks

### Assumptions
- Trail runners are comfortable with short text composition (validated by running app usage)
- 3-5 milestones per 10km trail is reasonable density (assumption, should validate in beta)
- GPS trigger within 30m is acceptable (depends on device accuracy in mountains)
- TTS latency <500ms is acceptable for real-time audio

### Risks & Mitigations
| Risk | Mitigation |
|------|-----------|
| TTS pronunciation (French names) | Test with French voice early; allow override in Phase 2 |
| Low adoption (users don't compose) | Provide templates as fallback; in-app tutorial |
| Competitor moves fast | First-mover advantage; differentiation on customization |
| GPS accuracy in canyons | Add manual trigger button as fallback |

---

## Next Steps

### Product
- [ ] Review research package with leadership
- [ ] Create PRD (Product Requirements Document)
- [ ] Define OKRs for feature launch
- [ ] Draft beta user recruitment plan

### Design
- [ ] Create high-fidelity mockups in Figma
- [ ] Plan interaction/animation details
- [ ] Review with engineering for feasibility
- [ ] Create design spec for handoff

### Engineering
- [ ] Review IMPLEMENTATION_GUIDE
- [ ] Estimate effort (MVP scope)
- [ ] Plan technical approach (TCA architecture, database)
- [ ] Create engineering tasks/tickets
- [ ] Schedule design review

### Marketing
- [ ] Draft positioning statement
- [ ] Create launch messaging
- [ ] Identify target communities (Reddit, Strava clubs)
- [ ] Plan beta user outreach
- [ ] Create app store screenshot copy

---

## Document Metadata

| Aspect | Value |
|--------|-------|
| **Research Date** | 2026-03-14 |
| **Package Version** | 1.0 |
| **Status** | Complete & Ready for Review |
| **Target Platform** | iOS 18+, Swift 6, SwiftUI, TCA |
| **Estimated MVP Duration** | 8-10 weeks |
| **Primary Author** | Product Manager (Research) |

---

## Appendix: Source Materials

All research materials properly cited:

### Research Sources
- [Apple Shortcuts - Use Variables](https://support.apple.com/guide/shortcuts/use-variables-apdd02c2780c/ios)
- [Duolingo Drag-and-Drop (GitHub)](https://github.com/RafaelGoulartB/duolingo-drag-and-drop)
- [Strava Audio Announcements](https://support.strava.com/hc/en-us/articles/216917237-Audio-Announcements)
- [Runkeeper Audio Cues](https://runkeeper.com/cms/app/audio-cues-in-the-runkeeper-app/)
- [Nike Run Club Customization](https://www.nike.com/help/a/customize-nrc)
- [iSmoothRun Features](http://www.ismoothrun.com/features.html)
- [Notion Database Templates](https://www.notion.com/help/database-templates)
- [Slack Block Kit](https://docs.slack.dev/messaging/composing/)
- [WhatsApp Quick Replies](https://controlhippo.com/blog/whatsapp/whatsapp-quick-reply/)
- [Typeform Mobile](https://www.typeform.com/help/a/create-forms-on-mobile-360057243192/)
- [Jotform Mobile Apps](https://www.jotform.com/products/apps/)

All sources current as of March 2026.

---

## How to Share This Package

**For Stakeholder Review**:
1. Distribute QUICK_REFERENCE + PRODUCT_STRATEGY to executives
2. Share full package with core product/design/engineering team
3. Use IMPLEMENTATION_GUIDE in technical deep-dive with engineering

**For Public/External**:
1. QUICK_REFERENCE can be shared with community (marketing)
2. PRODUCT_STRATEGY useful for partnerships/investor conversations
3. Research papers available upon request for media/analysts

---

## Questions?

**For Research Interpretation**: See RESEARCH_STRUCTURED_MESSAGE_COMPOSITION.md
**For Design Details**: See DESIGN_MILESTONE_COMPOSITION_PATTERNS.md
**For Strategy**: See PRODUCT_STRATEGY_VOICE_MILESTONES.md
**For Engineering**: See IMPLEMENTATION_GUIDE_MILESTONE_MESSAGES.md
**For Quick Answer**: See QUICK_REFERENCE_MILESTONE_VOICES.md

---

**End of Research Package Summary**

Last updated: 2026-03-14
Ready for: Product Review → Design Kickoff → Engineering Planning → Beta Launch
