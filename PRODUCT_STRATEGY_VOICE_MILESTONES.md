# Product Strategy: Voice Milestone Announcements

## Executive Summary

Trail runners currently lack a tool to compose **personalized, location-triggered voice announcements** during runs. Existing running apps (Strava, Nike Run Club, Runkeeper, iSmoothRun) offer only:
- Fixed announcement templates ("You've completed 5km")
- No custom composition
- No ability to mark course-specific milestones with personal messages

TrailMark can differentiate by enabling runners to **author their own voice roadbook** — mixing free-form text with auto-calculated course data (elevation, distance, gradient) — creating a uniquely personalized trail running experience.

---

## Market Analysis

### Existing Running App Features

| App | Customization Level | Voice Cues | Custom Text? |
|-----|-------------------|-----------|-------------|
| **Strava** | Low | Distance intervals (0.5–1 km) | No |
| **Nike Run Club** | Very Low | Predefined intervals | No |
| **Runkeeper** | Medium | Time/distance intervals | No |
| **iSmoothRun** | Medium | Configurable metrics, time/distance | No |
| **TrailMark (MVP)** | **HIGH** | Location-triggered at milestones | **Yes** |

### User Need: The Gap

**Current Pain Point:**
- Trail runners stop to check their GPS watch for "which climb is this?"
- They memorize "at 12km turn left" from guidebooks
- No voice guidance tailored to the *specific* trail

**Example Use Case:**
> "I'm running the Col de Galibier. At the 8km mark, I want to hear: 'You've reached 1,850 meters elevation. Col de Galibier is at 2,642m. You're 80% of the way there. Push hard!' I don't want generic beeps."

**Why Running Apps Don't Solve This:**
- Built for road running (all kilometers look the same)
- Not designed for trail-specific landmarks
- Announcement templates are generic ("pace update")

---

## Competitive Differentiation

### TrailMark's Unique Value Proposition

**Tagline:** *"Your personalized voice roadbook for trail running"*

**Core Differentiator:** Users can **compose milestone announcements** at specific course locations, mixing:
- **Custom motivation** ("You're crushing it!")
- **Auto-calculated data** (elevation: 1,350m, distance: 12.4km, gradient: 8%)
- **Location names** (if marked: "Col de Croix")

### Competitive Advantages

1. **Trail-Specific, Not Generic**
   - Strava/Nike: "Distance 5km" — applies to every run
   - TrailMark: "You've reached Col de Croix at 1,850m elevation. The summit is 800m higher. Dig deep!" — unique to this trail

2. **Customization Speed**
   - Competitor: Adjust app settings, rerun entire course
   - TrailMark: Place a milestone on the map, type a message, done (30 seconds)

3. **Data-Driven Motivation**
   - Milestones aren't arbitrary (every 1km) — they're at real course features
   - Announce elevation gain, remaining elevation, gradient
   - Creates psychological checkpoints ("You're halfway to the summit")

4. **No Trainer Required**
   - Competitors offer coaching AI/podcasts (premium, limited)
   - TrailMark: Runner authors their own coaching cues

### Market Positioning

```
                    Customization Level
                          ↑
                          │
        Nike Run Club ────┼── iSmoothRun
        (Low)             │  (Medium)
                          │
                          │
                          │
    TrailMark ───────────→├─────── Specialized
    (High)                │        Trail Apps
                          │        (Gaia GPS)
                          │
    ◄─────────────────────┼─────────────►
    Generic/Road Running   │  Trail-Specific
                          └─────────
```

TrailMark occupies the **Trail-Specific + Customizable** quadrant, uncontested.

---

## Customer Segments

### Primary: Trail Runners on Supported Races

**Profile:**
- Age: 25-55
- Experience: Intermediate to advanced (trail running skills)
- GPS watch users (already familiar with elevation/distance data)
- Tech-comfortable but not tech-dependent (want simple interfaces)
- Motivation: Complete a known trail with personalized milestones

**Size Estimate:**
- Global trail running population: ~5-10M
- Supported races/popular trails: ~500-1000 globally
- Early adopters per trail: 50-500 runners
- TAM (Year 1): 50K-500K trail runners in TrailMark's supported trails

### Secondary: Trail Race Organizers

**Profile:**
- Want to provide participants a digital "roadbook"
- Currently use paper cue sheets or generic GPS apps
- Would pay for branded experience (custom announcements per race)

**B2B Opportunity (Phase 2):**
- Race organizer creates trail in TrailMark
- Pre-places milestone announcements (curated by race director)
- Participants download and run with curated milestones
- Optional: Race organizer sponsors voice (custom TTS voice)

---

## Product Requirements

### MVP (Phase 1): Core Feature

**User Story:**
> As a trail runner, I want to place milestones at specific course locations and compose custom voice announcements so that I receive personalized guidance during my run, tailored to the specific trail.

**Minimum Viable Feature Set:**
1. ✓ Import GPX (existing)
2. ✓ Place milestones on elevation profile or map (existing)
3. **NEW: Compose announcement** (text + variables)
4. **NEW: Auto-calculate data** (elevation, distance, gradient)
5. **NEW: Variable insertion** (blue pill UI pattern)
6. **NEW: Preview TTS** (hear the announcement before saving)
7. ✓ Trigger on GPS location during run
8. ✓ Read announcement via TTS (existing)

### Phase 2: Polish & B2B

- [ ] **Milestone templates** (by type: Climb, Descent, Refuel)
- [ ] **Favorite phrases library** (user builds reusable phrases)
- [ ] **Pronunciation hints** (user can correct TTS pronunciation)
- [ ] **Trail sharing** (users share marked milestones with others)
- [ ] **Race organizer API** (B2B: allow race directors to author milestones)
- [ ] **Analytics** (which milestones triggered, user engagement)

### Phase 3: Growth

- [ ] **Social features** (see other runners' milestone messages)
- [ ] **Leaderboards** (fastest/slowest at each milestone)
- [ ] **Community trails** (crowd-sourced milestones)
- [ ] **Wearable integration** (Apple Watch: show milestone text on watch)

---

## Metrics & Success Criteria

### MVP Launch Goals (Phase 1)

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Adoption** | 100+ signups | Early adopter validation |
| **Feature Completion** | 60%+ of users compose ≥1 milestone | Feature engagement |
| **Preview Engagement** | 40%+ tap "Preview Voice" before saving | Users testing announcements |
| **Run Completion** | 30%+ milestone triggers/run (avg) | Course-specific adoption |
| **User Satisfaction (NPS)** | 40+ | Early adopter expectations |

### Phase 2 Goals (Polish)

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Retention (Day 30)** | 50%+ | Habit formation (trail runners run weekly) |
| **Milestone Authoring Time** | <2 min/milestone | Speed benchmark vs. competitors |
| **Template Adoption** | 30%+ use templates vs. free text | UX efficiency |
| **Run Re-engagement** | 20%+ of users re-run same trail | Milestone reusability |

### B2B Goals (Phase 2-3)

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Race Organizer Adoption** | 5-10 races | Pilot partnerships |
| **Branded Trail ARR** | $500-2K/race/year | B2B monetization |
| **Participant Satisfaction** | 70%+ rate milestones as "helpful" | Race organizer retention |

---

## Monetization Strategy

### Freemium Model (MVP)

**Free Tier:**
- Create & edit up to 5 trails
- Place up to 10 milestones per trail
- Voice announcements (system TTS only)

**Premium Tier ($4.99/month or $49.99/year):**
- Unlimited trails, milestones
- **Advanced**: Custom voice selection (male/female/accent)
- **Advanced**: Batch milestone templates
- **Advanced**: Trail sharing with friends

### B2B Model (Phase 2+)

**Race Organizer Partner:**
- White-labeled trail in TrailMark
- Pre-curated milestones authored by race director
- Participants download free (race pays $200-500/event)
- Optional: Custom TTS voice (branded announcements)

**Revenue Potential:**
- Trail ultra races: 100-500 participants × $2-5 per runner = $200-2.5K per race
- 20 races in Year 2 = $4K-50K additional revenue

---

## Go-to-Market Strategy

### Launch Phase (Month 1-2)

**Target Users:** Trail runners in existing popular running communities

**Tactics:**
1. **Beta Program** (select 20-30 runners)
   - Recruit from r/trailrunning, Strava clubs, local running clubs
   - Get detailed feedback on composition UI
   - Iterate design before public launch

2. **Paid Ad (Targeted)**
   - Google Ads: "Trail running + voice guidance"
   - Reddit: r/trailrunning, r/ultrarunning
   - Budget: $500-1K initial testing

3. **Content (SEO)**
   - Blog: "5 Tips for Pacing Trail Ultras" → mention TrailMark
   - Blog: "DIY Trail Navigation: GPS + Voice Guide"
   - Target: "trail running voice guide" keyword (low competition, high intent)

### Growth Phase (Month 3-6)

**Tactics:**
1. **Race Partnerships**
   - Pitch 5-10 local/regional trail races
   - "Offer TrailMark to your participants for free" (you pay $300/race)
   - Capture 50-100 users per race

2. **Influencer** (Micro-influencers)
   - Ultra runners with 10K-50K followers
   - Seeding: Free premium access + race sponsorship mention
   - Goal: Authentic reviews, word-of-mouth

3. **Product Differentiation**
   - Launch "Shared Trails" feature (runners share milestones)
   - Use social proof in marketing

### Retention Phase (Month 6+)

**Tactics:**
1. **Community Building**
   - Discord: TrailMark users share trails, milestones, race reports
   - Monthly featured trails (voting by users)

2. **Email/Push**
   - "Your favorite trail has new milestones shared by 5 runners"
   - "Register for the xxx race and use TrailMark"

3. **Subscription Conversion**
   - Free users hit milestone limits (10 milestones)
   - Upsell: "Go unlimited with Premium" ($4.99/month)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **TTS Pronunciation** (French trail names) | Medium | Test with French TTS voice, allow pronunciation overrides (Phase 2) |
| **Small Market Size** (trail running << road running) | High | B2B partnerships with race organizers amplify reach |
| **Competitor Features** (Strava adds customization) | Medium | First-mover advantage + brand loyalty; pivot to race organizer platform |
| **Adoption Complexity** (users don't understand variables) | Medium | Provide templates, simplify UI, in-app tooltips |
| **GPS Accuracy** (mountain canyons block signal) | Medium | Allow trigger radius adjustment, fallback to manual trigger |
| **TTS Latency** (announcement delayed during run) | Medium | Pre-cache audio during editor preview, test on real device |

---

## Success Metrics Summary

### Why This Feature Matters

**For Users:**
- Solves real pain: "How do I remember where to turn/push on this trail?"
- Unique value: Personalization at the trail level, not generic
- Engagement: Composing milestones is creative, fun, motivating

**For TrailMark:**
- Differentiator: No competitor offers this
- Retention: Users return to re-run trails with milestones
- Monetization: Premium features (templates, voice selection) have clear value
- Growth: B2B partnerships unlock new user segments (race organizers, event participants)

**For Competitive Position:**
- TrailMark becomes "*the* app for personalized trail navigation"
- vs. Strava: "Generic running social"
- vs. Gaia GPS: "Beautiful maps, no voice guidance"
- vs. iSmoothRun: "Road running focused, no customization"

---

## Implementation Timeline

### MVP (8-10 weeks)

**Week 1-2: Design & Validation**
- Finalize UI/UX (Shortcuts pattern)
- Internal testing on real trail runs
- Ensure TTS latency acceptable

**Week 3-5: Development**
- TextEditor + variable insertion component
- Variable calculation logic (elevation, distance, grade)
- Template substitution at run time
- Storage schema update

**Week 6-8: Testing & Polish**
- Device testing (real GPS, real runs)
- Edge case handling (no variables, long messages, special chars)
- TTS voice options

**Week 9-10: Beta & Launch**
- 20-person beta program (feedback cycle)
- Launch to App Store

### Phase 2 (Post-Launch, 4-6 weeks)

- Milestone templates by type
- Trail sharing
- Analytics
- B2B race organizer onboarding

---

## Appendix: Competitive Feature Comparison

### Announcement Customization Comparison

**Strava (Status quo):**
```
Run Start
├─ (Trigger: Every 1 km)
│ ├─ Audio: "You've completed 1 kilometer"
│ └─ (User cannot customize)
└─ (Trigger: Run Finish)
  └─ Audio: "Run finished, X kilometers"
```

**TrailMark (Proposed):**
```
Col de Galibier Trail
├─ Milestone 1 (8 km): "You've reached {elevation}m elevation. Col de Galibier is at 2,642m. {grade}% grade. Dig in!"
├─ Milestone 2 (12 km): "Halfway to the summit! {distance}km to go."
├─ Milestone 3 (15 km): "You're at the summit! Time for a refuel."
└─ (User controls all announcements, timing, data insertion)
```

**Runkeeper (Closest competitor):**
```
Audio Cues (Settings)
├─ Interval: Every 0.5 mi / 1 km [User configurable]
├─ Voice Gender: Male / Female [User configurable]
├─ Stats Announced: Pace, Distance, Time [User configurable]
└─ (Still templated: "0.5 miles completed" — no custom text)
```

**Conclusion:** TrailMark offers **10x more customization** than any competitor, with **zero required setup** (users just type, tap, run).

---

## References

- Apple Shortcuts research: See RESEARCH_STRUCTURED_MESSAGE_COMPOSITION.md
- Design patterns: See DESIGN_MILESTONE_COMPOSITION_PATTERNS.md
- Strava audio features: https://support.strava.com/hc/en-us/articles/216917237-Audio-Announcements
- Nike Run Club customization: https://www.nike.com/help/a/customize-nrc
- iSmoothRun features: http://www.ismoothrun.com/features.html
- Runkeeper audio cues: https://runkeeper.com/cms/app/audio-cues-in-the-runkeeper-app/
