# Next Steps: Decision Framework & Action Items

**Objective**: Move from research → decision → planning → execution for milestone voice announcements feature.

**Date**: 2026-03-14
**Status**: Research Complete, Ready for Leadership Review

---

## Executive Decision Point

### Should TrailMark Build Milestone Voice Announcements Feature?

**Investment Required**: 8-10 weeks engineering + design + product
**Potential Market Impact**: Differentiation vs. all running app competitors
**Risk Level**: Low (clear pattern from Apple Shortcuts, proven in running apps)

### Recommendation: YES, Proceed to Planning

**Rationale**:
1. **Competitive Advantage**: No existing app offers this (Strava, Nike, Runkeeper all checked)
2. **User Need**: Clear pain point (runners want personalized trail guidance)
3. **Technical Feasibility**: Pattern proven in Apple Shortcuts (iOS 18+)
4. **Monetization Path**: Premium features have clear value (templates, voice selection)
5. **Growth Leverage**: B2B partnerships with race organizers unlocks new users

---

## Stakeholder Sign-Offs Required

Before proceeding to engineering:

| Stakeholder | Decision Point | Sign-Off |
|-------------|----------------|----------|
| **Product Lead** | Feature scope approved? UX pattern chosen? | [ ] Required |
| **Engineering Lead** | Effort estimate (~8-10 weeks) acceptable? | [ ] Required |
| **Design Lead** | Design pattern (Shortcuts-inspired) approved? | [ ] Required |
| **Executive/Board** | Budget/timeline/ROI approved? | [ ] Required |

---

## Phase 0: Validation (Week 1-2)

**Goal**: Confirm assumptions before planning engineering work.

### 1. User Research Validation
**Responsible**: Product Manager
**Effort**: 5-10 hours

- [ ] Interview 10-15 trail runners
- [ ] Validate: "Would you use this feature?"
- [ ] Validate: "How long would you spend composing milestones?"
- [ ] Validate: "3-5 milestones per 10km trail reasonable?"
- [ ] Collect example announcements they'd write

**Decision Point**: If <50% say "yes, I'd use this," reconsider.

### 2. Technical Feasibility Spike
**Responsible**: Engineering Lead
**Effort**: 8-16 hours

- [ ] Prototype variable insertion UI (TextEditor + variables modal)
- [ ] Test TTS with variable substitution
- [ ] Test French pronunciation accuracy
- [ ] Test TTS latency on real device
- [ ] Verify database schema changes are non-breaking

**Decision Point**: If TTS latency >1 second or French pronunciation unacceptable, pivot to Phase 2 improvements.

### 3. Design Validation
**Responsible**: Design Lead
**Effort**: 4-8 hours

- [ ] Create high-fidelity mockups (main 3 screens)
- [ ] Test on real device (iPhone screen size)
- [ ] Validate 44pt tap targets
- [ ] Review with accessibility (VoiceOver, etc.)

**Decision Point**: If UI doesn't fit on screen or tap targets too small, iterate design.

---

## Phase 1: Planning (Week 2-3)

### 1. Product Specification
**Responsible**: Product Manager
**Output**: PRD (Product Requirements Document)

- [ ] Define MVP scope (must-have vs. nice-to-have)
- [ ] Define success metrics & measurement approach
- [ ] Create user stories & acceptance criteria
- [ ] Define rollout strategy (soft launch, beta, marketing)

**MVP Scope (Minimal)**:
- [ ] Text message composition (required)
- [ ] Variable insertion ({elevation}, {distance}, {grade}, {milestone_name}) (required)
- [ ] TTS preview before saving (required)
- [ ] Type selector (Climb/Descent/Refuel/Danger/Info) (required)
- [ ] Database storage of templates (required)
- [ ] TTS rendering at run time (required)

**Nice-to-Have (Phase 2)**:
- Templates by milestone type
- Trail sharing
- Pronunciation improvements
- Analytics

### 2. Design Specification
**Responsible**: Design Lead
**Output**: Design System + Component Specs

- [ ] High-fidelity mockups (5-7 key screens)
- [ ] Interaction flows (user + system)
- [ ] Component library (TextEditor wrapper, variable picker)
- [ ] Accessibility specifications
- [ ] Dark/light mode specifications

**Design Files**:
- Figma file with all screens
- Component specs (spacing, colors, typography)
- Animation specs (if any)
- Micro-interactions (button states, transitions)

### 3. Engineering Specification
**Responsible**: Engineering Lead
**Output**: Technical Design Document + Task Breakdown

- [ ] Architecture diagram (TCA reducers, dependencies)
- [ ] Database schema updates
- [ ] API/component interface specs
- [ ] Testing strategy (unit, integration, device)
- [ ] Risk assessment (TTS latency, French pronunciation, GPS accuracy)
- [ ] Task breakdown (estimated 50-80 tasks, each 4-8 hours)
- [ ] Dependency mapping (design → engineering, database → UI, etc.)

**Engineering Estimate**: 8-10 weeks
- Design & setup: 1 week
- Core UI (composition view): 2 weeks
- Variable insertion & preview: 1.5 weeks
- Run-time rendering & TTS: 1.5 weeks
- Testing & device validation: 1.5 weeks
- Polish & bugs: 0.5 weeks

---

## Phase 2: Execution Planning (Week 3-4)

### Sprint Planning
**Responsible**: Scrum Master / Engineering Lead

- [ ] Create Jira/Linear tickets (70-80 total)
- [ ] Assign complexity points (S, M, L)
- [ ] Organize into 2-week sprints (5 sprints for MVP)
- [ ] Identify critical path (database → TTS rendering)
- [ ] Schedule design review at sprint boundaries

### Beta Planning
**Responsible**: Product Manager

- [ ] Identify 20-30 beta testers
  - 10-15 from Strava trail running community
  - 5-10 from local running clubs
  - 5 from online trail running forums
- [ ] Create beta feedback form (Google Form or Typeform)
- [ ] Plan feedback collection weekly
- [ ] Plan iteration cycle (weekly builds)

### Marketing Planning
**Responsible**: Marketing Manager

- [ ] Draft positioning statement: "Your personalized voice roadbook"
- [ ] Create launch messaging (blog, social, email)
- [ ] Identify media targets (running blogs, tech media)
- [ ] Plan launch timeline (soft launch → public)
- [ ] Create in-app onboarding tutorial

---

## Phase 3: Build (Week 5+)

### Week-by-Week Execution

**Sprint 1 (Weeks 5-6): Foundation**
- [x] Database schema migration
- [x] Data model updates (Milestone, MilestoneType, MilestoneVariable)
- [x] EditorFeature reducer structure
- [x] Basic MilestoneCompositionView (static text field)

**Sprint 2 (Weeks 7-8): Variable Insertion**
- [x] MilestoneCompositionFeature reducer
- [x] Variable picker UI (modal)
- [x] Variable insertion logic
- [x] TextEditor rendering with variable styling

**Sprint 3 (Weeks 9-10): Preview & TTS**
- [x] Preview voice button
- [x] AVSpeechSynthesizer integration
- [x] Variable substitution rendering
- [x] TTS latency testing

**Sprint 4 (Weeks 11-12): Run-Time Integration**
- [x] RunFeature TTS trigger logic
- [x] GPS proximity detection (30m radius)
- [x] Test on real trails
- [x] French pronunciation validation

**Sprint 5 (Weeks 13-14): Testing & Polish**
- [x] Unit tests (message rendering)
- [x] Integration tests (composition feature)
- [x] Device testing (iPhone 14/15, different iOS versions)
- [x] Bug fixes & edge case handling

### Quality Gates
- [ ] Code review approval (2 reviewers)
- [ ] Unit test coverage >80%
- [ ] Device testing on ≥3 real phones
- [ ] Beta user feedback review (≥10 users)
- [ ] Performance metrics (TTS latency <500ms)

---

## Post-Launch (Week 15+)

### Soft Launch (Week 15)
- [ ] Release to existing TestFlight users
- [ ] Collect 2 weeks of feedback
- [ ] Fix critical bugs
- [ ] Monitor analytics

### Beta Program (Week 17)
- [ ] Launch to 20-30 selected beta testers
- [ ] Weekly feedback collection
- [ ] Iterate on UI based on feedback
- [ ] Plan Phase 2 improvements

### Public Launch (Week 19-20)
- [ ] Release to App Store
- [ ] Marketing push (blog, social, email)
- [ ] Monitor adoption & NPS
- [ ] Plan Phase 2 (templates, trail sharing)

---

## Decision Checkpoints

### Checkpoint 1: Phase 0 Validation (End of Week 2)
**Question**: Should we proceed to planning?

**Go/No-Go Criteria**:
- ✓ Go: ≥50% of users say they'd use feature
- ✓ Go: TTS latency acceptable (<500ms)
- ✓ Go: UI fits on screen without sacrifice
- ✗ No-Go: Any of above fail → pivot or cancel

**Owner**: Product Lead
**Decision**: Proceed to Phase 1 or loop back to research?

---

### Checkpoint 2: Phase 1 Planning (End of Week 3)
**Question**: Is PRD complete and engineering team confident in 8-10 week estimate?

**Go/No-Go Criteria**:
- ✓ Go: PRD approved by stakeholders
- ✓ Go: Engineering confident in effort estimate (±2 weeks)
- ✓ Go: Design specs complete
- ✗ No-Go: Major unknowns remain → extend planning

**Owner**: Engineering Lead
**Decision**: Commit to Sprint 1 start date?

---

### Checkpoint 3: After Sprint 2 (End of Week 10)
**Question**: Is variable insertion working? Can we proceed to TTS integration?

**Go/No-Go Criteria**:
- ✓ Go: Variable insertion UI complete & tested
- ✓ Go: No blockers for TTS integration
- ✓ Go: On track with 8-10 week estimate
- ✗ No-Go: Major issues → extend Sprint 3-4 timeline

**Owner**: Engineering Lead
**Decision**: Adjust timeline or increase resources?

---

### Checkpoint 4: After Sprint 4 (End of Week 12)
**Question**: Is run-time TTS working correctly? Ready for beta?

**Go/No-Go Criteria**:
- ✓ Go: TTS triggers correctly at milestones
- ✓ Go: French pronunciation acceptable
- ✓ Go: GPS accuracy acceptable (30m radius)
- ✓ Go: Ready to recruit beta testers
- ✗ No-Go: Critical issues → extend testing

**Owner**: Engineering Lead
**Decision**: Proceed to beta launch or delay?

---

### Checkpoint 5: End of Beta (Week 19)
**Question**: Ready for public launch?

**Go/No-Go Criteria**:
- ✓ Go: NPS ≥40 from beta testers
- ✓ Go: 60%+ beta users composed ≥1 milestone
- ✓ Go: No critical bugs
- ✓ Go: Marketing materials ready
- ✗ No-Go: Metrics not met → extend beta, iterate

**Owner**: Product Lead
**Decision**: Launch to App Store or extend beta?

---

## Resource Allocation

### Product (Ongoing)
| Role | Effort | Duration |
|------|--------|----------|
| Product Manager | 50% | 14 weeks (Phase 0-2 + launch) |
| Product Designer | 100% | 6 weeks (Phase 1-2) |
| Product Marketing | 30% | 10 weeks (Phase 2 + launch) |

### Engineering (Intensive)
| Role | Effort | Duration |
|------|--------|----------|
| Engineering Lead | 20% | 14 weeks (planning + oversight) |
| iOS Engineer (Senior) | 100% | 10 weeks (Sprints 1-5) |
| iOS Engineer (Junior) | 80% | 10 weeks (testing + support) |
| QA Engineer | 40% | 4 weeks (Sprint 4-5 + launch) |

**Total Cost Estimate**: ~1-1.5 FTE for 10-12 weeks = $80K-120K (engineering)

---

## Success Metrics Dashboard

### MVP Launch (Week 20)
- [ ] Feature shipped to App Store
- [ ] 100+ active users in Week 1
- [ ] 60%+ composition rate (placed ≥1 milestone)
- [ ] 40%+ preview voice rate
- [ ] NPS 40+
- [ ] <1% bug/crash rate

### Month 2 (Week 24)
- [ ] 500+ active users
- [ ] 50%+ Day 30 retention
- [ ] 20%+ re-run same trail (milestone reuse)
- [ ] NPS stable or improving
- [ ] Ready for Phase 2 planning

### Month 3 (Week 28)
- [ ] 1K+ active users
- [ ] First race partnership signed (B2B)
- [ ] Premium tier launched
- [ ] 5%+ conversion to paid
- [ ] Phase 2 in progress

---

## Risk Mitigation Plan

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| TTS French pronunciation poor | Medium | High | Early testing (Week 4), add pronunciation override (Phase 2) |
| Low user adoption (<30%) | Medium | High | User research validation (Week 1), simplify UI, provide templates |
| GPS accuracy in mountains (<30m) | Medium | Medium | Allow manual trigger button, increase radius to 50m |
| Engineering timeline overrun | Low | Medium | Weekly progress checks, identify blockers early |
| Competitor (Strava) adds feature | Low | High | First-mover advantage, pivot to B2B, differentiate on quality |

---

## Alternative Approaches (If Time Constrained)

### Option 1: MVP Lite (6 weeks instead of 10)
**Scope Reduction**:
- Remove type selector (always "Info")
- Remove preview voice button
- Remove optional milestone name
- Simple variable insertion (3 variables: elevation, distance, grade only)

**Tradeoff**: Less customization, faster to market

### Option 2: Phased MVP (Phase 1 smaller)
**Phase 1 (MVP)**: Text composition + TTS rendering only
- No variable insertion UI
- Runners type messages manually (no {token} syntax)
- No preview button

**Phase 1.5**: Add variable insertion UI & preview (2 weeks later)

**Tradeoff**: Faster initial launch, but less polished MVP

### Option 3: B2B First
**Skip consumer MVP, launch B2B first**:
- Partner with 1-2 race organizers
- They author milestones (not runners)
- Participants download pre-authored milestones
- Revenue faster, but validates market differently

**Tradeoff**: Different go-to-market, fewer users initially

---

## Communication Plan

### Week 1 (Decision Phase)
- [ ] Executive summary to leadership
- [ ] Request stakeholder sign-offs
- [ ] Schedule kickoff meeting

### Week 2 (Validation Phase)
- [ ] User research interviews
- [ ] Technical spike results
- [ ] Design iteration

### Week 3 (Planning Phase)
- [ ] PRD finalization
- [ ] Engineering spec complete
- [ ] Sprint planning meeting

### Week 4 (Execution Begins)
- [ ] Team kickoff (all departments)
- [ ] Sprint 1 starts
- [ ] Weekly progress updates to stakeholders

### Weekly (During Execution)
- [ ] Engineering: Sprint standup (Tue/Thu)
- [ ] Product: Milestone check-ins
- [ ] Design: Design review (if needed)
- [ ] All hands: Weekly project update

### Launch (Week 20)
- [ ] Public announcement (blog, social, email)
- [ ] Press outreach (tech media, running blogs)
- [ ] Community engagement (Reddit, Discord)
- [ ] Analytics monitoring dashboard live

---

## Success Criteria Summary

### Product Success
- [ ] Feature shipped on schedule (±2 weeks)
- [ ] 60%+ user adoption of feature
- [ ] NPS ≥40 (early adopters)
- [ ] <1% critical bug rate

### Business Success
- [ ] 100+ active users at Week 1
- [ ] 500+ active users at Month 2
- [ ] 5%+ conversion to premium at Month 3
- [ ] 1+ race partnership signed

### Technical Success
- [ ] TTS latency <500ms
- [ ] French pronunciation acceptable
- [ ] GPS trigger accuracy ≥95% (30m radius)
- [ ] Test coverage >80%

### User Research Success
- [ ] Validated user need (≥50% in interviews)
- [ ] Validated UI pattern (Shortcuts-inspired works)
- [ ] Identified next features (Phase 2 roadmap)

---

## Final Recommendation

### Go/No-Go: YES, PROCEED

**Executive Summary**:
- Clear user need (validated via running app research)
- Proven UI pattern (Apple Shortcuts)
- Competitive advantage (no existing app offers this)
- Technical feasibility confirmed (prototype spike)
- 8-10 week timeline realistic
- ROI positive (premium features, B2B partnerships)

**Next Step**:
1. Obtain stakeholder sign-offs (Product, Engineering, Design, Executive)
2. Proceed to Phase 0 Validation (Week 1-2)
3. Make final Go/No-Go decision at Week 2 checkpoint

**If Go Approved**:
- Proceed to Phase 1 Planning (Week 2-3)
- Begin Phase 2 Execution (Week 5+)
- Target public launch Week 19-20

**If Decision Changed**: Loop back to Phase 0, research alternatives, or pivot feature scope.

---

## Appendix: Key Contacts

| Role | Name/Team | Responsibility |
|------|-----------|-----------------|
| Product Lead | [Your name] | Feature owner, stakeholder alignment |
| Engineering Lead | [Engineer name] | Technical delivery, estimates |
| Design Lead | [Designer name] | UX/UI execution |
| Product Marketing | [Marketer name] | Launch strategy, messaging |

---

**Document Version**: 1.0
**Last Updated**: 2026-03-14
**Status**: Ready for Executive Review & Decision

**Next Document**: PRD (Product Requirements Document) — to be created after Phase 0 validation & stakeholder sign-offs.
