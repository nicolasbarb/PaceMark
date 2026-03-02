# Editor Sheet Apple Maps Style - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor EditorView avec une sheet style Apple Maps : mini-profil toujours visible, liste expandable, interaction carte préservée.

**Architecture:** Custom SwiftUI detent pour la position mini (~200pt), sync bidirectionnelle entre picker et detent, ElevationProfileView adapté en mode compact.

**Tech Stack:** SwiftUI, CustomPresentationDetent, TCA (The Composable Architecture)

---

## Task 1: Créer le Custom Detent

**Files:**
- Modify: `trailmark/Views/EditorView.swift:1-10`

**Step 1: Ajouter le custom detent en haut du fichier**

```swift
import SwiftUI
import ComposableArchitecture
import MapKit

// MARK: - Custom Detent

/// Detent pour la position mini (profil compact)
struct MiniProfileDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        // Header(60) + Picker(50) + MiniProfil(80) + padding(20)
        210
    }
}

struct EditorView: View {
    // ... reste du code
```

**Step 2: Build pour vérifier la syntaxe**

Run: `xcodebuild -scheme trailmark -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(error:|BUILD)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add trailmark/Views/EditorView.swift
git commit -m "feat(editor): add MiniProfileDetent for compact sheet position"
```

---

## Task 2: Refactorer le state de EditorView

**Files:**
- Modify: `trailmark/Views/EditorView.swift:5-12`

**Step 1: Remplacer les state variables**

Remplacer:
```swift
private let profilHeight: PresentationDetent = .height(300)
@State private var selectedDetent: PresentationDetent = .height(80)
```

Par:
```swift
@State private var selectedDetent: PresentationDetent = .custom(MiniProfileDetent.self)

enum EditorTab: String, CaseIterable {
    case profil = "Profil"
    case reperes = "Repères"
}
@State private var selectedTab: EditorTab = .profil
```

**Step 2: Build pour vérifier**

Run: `xcodebuild -scheme trailmark -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(error:|BUILD)"`
Expected: BUILD SUCCEEDED (avec warnings sur code inutilisé)

**Step 3: Commit**

```bash
git add trailmark/Views/EditorView.swift
git commit -m "refactor(editor): replace detent state with EditorTab enum"
```

---

## Task 3: Ajouter le mode compact à ElevationProfileView

**Files:**
- Modify: `trailmark/Views/Components/ElevationProfileView.swift:71-92`

**Step 1: Ajouter le paramètre isCompact**

Modifier la struct pour accepter un mode compact:
```swift
struct ElevationProfileView: View {
    let trackPoints: [TrackPoint]
    let milestones: [Milestone]
    @Binding var cursorPointIndex: Int?
    let onTap: (Int) -> Void
    var isCompact: Bool = false  // Nouveau paramètre

    @State private var dragLocation: CGPoint?
    @State private var tooltipData: TooltipData?
    @State private var lastHapticIndex: Int?
```

**Step 2: Masquer le header en mode compact**

Dans le body, wrapper le header avec une condition:
```swift
var body: some View {
    VStack(spacing: 0) {
        ZStack(alignment: .topLeading) {
            TM.bgSecondary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Mini header - masqué en mode compact
                if !isCompact {
                    HStack {
                        Text("PROFIL")
                            .font(.system(.caption2, design: .monospaced, weight: .semibold))
                            .tracking(1)
                            .foregroundStyle(TM.textMuted)

                        Spacer()

                        Text("Tap = repère")
                            .font(.system(size: 9))
                            .foregroundStyle(TM.textMuted)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                }

                // Canvas - reste identique
                GeometryReader { geometry in
                    // ...
                }
            }
        }
    }
}
```

**Step 3: Build et vérifier**

Run: `xcodebuild -scheme trailmark -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(error:|BUILD)"`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add trailmark/Views/Components/ElevationProfileView.swift
git commit -m "feat(profile): add isCompact mode to hide header"
```

---

## Task 4: Créer le contenu de la nouvelle sheet

**Files:**
- Modify: `trailmark/Views/EditorView.swift` (remplacer le contenu de la sheet)

**Step 1: Créer EditorSheetContent**

Ajouter après `MiniProfileDetent`:
```swift
// MARK: - Editor Sheet Content

private struct EditorSheetContent: View {
    @Bindable var store: StoreOf<EditorFeature>
    let detail: TrailDetail
    @Binding var selectedTab: EditorView.EditorTab
    @Binding var selectedDetent: PresentationDetent

    var body: some View {
        VStack(spacing: 0) {
            // Header avec nom du parcours
            headerView

            // Picker Profil / Repères
            pickerView

            // Mini profil (toujours visible)
            ElevationProfileView(
                trackPoints: detail.trackPoints,
                milestones: store.milestones,
                cursorPointIndex: Binding(
                    get: { store.cursorPointIndex },
                    set: { store.send(.cursorMoved($0)) }
                ),
                onTap: { index in
                    store.send(.profileTapped(index))
                },
                isCompact: true
            )
            .frame(height: 80)

            // Liste des repères (si expanded)
            if selectedDetent == .large {
                Divider()
                    .background(TM.border)

                ReperesContentView(store: store)
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            withAnimation(.snappy(duration: 0.3)) {
                selectedDetent = newTab == .reperes ? .large : .custom(MiniProfileDetent.self)
            }
        }
        .onChange(of: selectedDetent) { _, newDetent in
            withAnimation(.snappy(duration: 0.2)) {
                selectedTab = newDetent == .large ? .reperes : .profil
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 2) {
            Text(detail.trail.name)
                .font(.headline)
                .foregroundStyle(TM.textPrimary)

            TrailStatsView(distanceKm: detail.distKm, dPlus: detail.trail.dPlus)
        }
        .padding(.vertical, 12)
    }

    private var pickerView: some View {
        HStack(spacing: 8) {
            ForEach(EditorView.EditorTab.allCases, id: \.self) { tab in
                Button {
                    Haptic.light.trigger()
                    selectedTab = tab
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: tab == .profil ? "chart.xyaxis.line" : "mappin.and.ellipse")
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab == .reperes ? "\(tab.rawValue) (\(store.milestones.count))" : tab.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? TM.textPrimary : TM.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ? TM.accent.opacity(0.15) : Color.clear,
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(selectedTab == tab ? TM.accent : TM.border, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}
```

**Step 2: Build pour vérifier la syntaxe**

Run: `xcodebuild -scheme trailmark -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(error:|BUILD)"`
Expected: Possible errors about EditorTab scope - will fix in next step

**Step 3: Commit (même si build échoue, c'est un checkpoint)**

```bash
git add trailmark/Views/EditorView.swift
git commit -m "feat(editor): add EditorSheetContent component"
```

---

## Task 5: Mettre à jour EditorView pour utiliser la nouvelle sheet

**Files:**
- Modify: `trailmark/Views/EditorView.swift` (body de EditorView)

**Step 1: Remplacer le contenu de la sheet**

Dans le body de EditorView, remplacer tout le bloc `.sheet(isPresented:)`:
```swift
.sheet(isPresented: .constant(true)) {
    EditorSheetContent(
        store: store,
        detail: detail,
        selectedTab: $selectedTab,
        selectedDetent: $selectedDetent
    )
    .presentationDetents([.custom(MiniProfileDetent.self), .large], selection: $selectedDetent)
    .presentationBackgroundInteraction(.enabled(upThrough: .custom(MiniProfileDetent.self)))
    .presentationDragIndicator(.hidden)
    .presentationBackground(TM.bgSecondary)
    .interactiveDismissDisabled()
    .sheet(
        item: $store.scope(state: \.milestoneSheet, action: \.milestoneSheet)
    ) { sheetStore in
        MilestoneSheetView(store: sheetStore)
            .presentationDetents([.large])
            .presentationBackground(TM.bgCard)
    }
}
```

**Step 2: Build complet**

Run: `xcodebuild -scheme trailmark -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(error:|warning:|BUILD)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add trailmark/Views/EditorView.swift
git commit -m "feat(editor): wire up new sheet with custom detents"
```

---

## Task 6: Nettoyer le code inutilisé

**Files:**
- Modify: `trailmark/Views/EditorView.swift`

**Step 1: Supprimer EditorBottomPanel**

Supprimer tout le bloc `private struct EditorBottomPanel: View { ... }` (lignes ~320-625) qui n'est plus utilisé.

**Step 2: Supprimer les références aux anciens detents**

Chercher et supprimer toute référence à:
- `profilHeight`
- `.height(80)`
- `.height(300)`

**Step 3: Build final**

Run: `xcodebuild -scheme trailmark -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(error:|warning:|BUILD)"`
Expected: BUILD SUCCEEDED (sans warnings sur EditorView)

**Step 4: Commit**

```bash
git add trailmark/Views/EditorView.swift
git commit -m "chore(editor): remove unused EditorBottomPanel code"
```

---

## Task 7: Tester et ajuster

**Files:**
- Modify: `trailmark/Views/EditorView.swift` (si nécessaire)

**Step 1: Lancer la preview**

Ouvrir Xcode, afficher la preview "Editor - With Milestones"

**Step 2: Vérifier les comportements**

- [ ] Sheet démarre en position mini (~210pt)
- [ ] Tap sur "Repères" → sheet anime vers large
- [ ] Tap sur "Profil" → sheet anime vers mini
- [ ] Swipe up/down → sync avec le picker
- [ ] Tap sur le mini-profil → ouvre MilestoneSheet
- [ ] Interaction avec la carte en position mini

**Step 3: Ajuster les hauteurs si nécessaire**

Si le mini-profil est trop petit/grand, ajuster dans `MiniProfileDetent.height()`:
```swift
static func height(in context: Context) -> CGFloat? {
    // Ajuster selon les tests visuels
    210  // ou 200, 220, etc.
}
```

**Step 4: Commit final**

```bash
git add -A
git commit -m "feat(editor): finalize Apple Maps-style sheet implementation"
```

---

## Summary

| Task | Description | Fichiers |
|------|-------------|----------|
| 1 | Custom Detent | EditorView.swift |
| 2 | Refactor state | EditorView.swift |
| 3 | Mode compact profil | ElevationProfileView.swift |
| 4 | EditorSheetContent | EditorView.swift |
| 5 | Wire up sheet | EditorView.swift |
| 6 | Cleanup | EditorView.swift |
| 7 | Test & adjust | EditorView.swift |
