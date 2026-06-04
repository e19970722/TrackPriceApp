# iOS/CLAUDE.md

Guidance for agents working inside the `iOS/` directory.

## What this component does

Native iOS app (Swift + SwiftUI, iOS 16+). Embeds a WKWebView browser; users long-press to enter selection mode, tap a price element, and set a target. `ElementPicker.js` is injected into the page to handle element highlighting and selection. Price history is shown via the Charts framework. Authentication via Apple Sign In and Google Sign In. Push notifications delivered through APNs / FCM.

## Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 16+) |
| State management | TCA (The Composable Architecture) |
| Package structure | Swift Package Manager (`Features/` local package) |
| Project generation | XcodeGen (`project.yml`) |
| Linting | SwiftLint (`iOS/.swiftlint.yml`) |
| Formatting | SwiftFormat (`iOS/.swiftformat`) |
| Auth | Apple Sign In + Google Sign In |
| Push | APNs / FCM |

## Directory Layout

```
iOS/
├── TrackPriceApp/           # Xcode app target (thin shell)
│   └── App/                 # Entry point, AppDelegate/scene config
├── Features/                # Local Swift Package (all product code lives here)
│   ├── Sources/Features/
│   │   ├── App/             # Root AppFeature + AppView
│   │   ├── Components/      # Reusable UI components
│   │   ├── Design/          # Design tokens (RipeLayout, RipeTypography, …)
│   │   ├── Features/        # One sub-folder per screen/feature
│   │   │   ├── Home/
│   │   │   ├── TrackerList/
│   │   │   ├── TrackerDetail/
│   │   │   ├── AddTracker/
│   │   │   ├── Items/
│   │   │   ├── Settings/
│   │   │   └── Auth/
│   │   ├── Models/          # Shared data models (Tracker, Item, …)
│   │   ├── Services/        # APIClient, dependencies
│   │   └── Resources/       # Asset catalogs, fonts
│   └── Tests/FeaturesTests/
├── project.yml              # XcodeGen config
├── .swiftlint.yml           # SwiftLint rules (active)
├── .swiftlint-fix.yml       # SwiftLint auto-fix rules
└── .swiftformat             # SwiftFormat options
```

## Commands

```bash
# Open project in Xcode
open iOS/TrackPriceApp.xcodeproj

# Regenerate .xcodeproj from project.yml (if XcodeGen installed)
xcodegen generate --spec iOS/project.yml

# Lint
swiftlint lint --config iOS/.swiftlint.yml

# Auto-fix lint
swiftlint lint --fix --config iOS/.swiftlint-fix.yml

# Format
swiftformat iOS/ --config iOS/.swiftformat
```

Build and run: `Cmd+R` in Xcode. Tests: `Cmd+U`.

## TCA Conventions

Every screen follows the `@Reducer` pattern:

```
Features/<ScreenName>/
├── <ScreenName>Feature.swift   # @Reducer: State, Action, body
└── <ScreenName>View.swift      # SwiftUI view, store: StoreOf<ScreenNameFeature>
```

- `State` and `Action` are nested types inside the `@Reducer` struct — this is intentional and expected by TCA.
- Use `@Presents` for child features presented as sheet/navigation; use `PresentationAction<ChildFeature.Action>` in the parent `Action`.
- Side effects go in `Effect.run { send in … }` blocks inside `body`. Never perform async work directly in `State`.
- `@Dependency(\.apiClient) var apiClient` — inject all external dependencies via TCA's dependency system, never instantiate them directly.

## SwiftUI Coding Rules

### Body must stay clean
`body` may only contain named subview references. Never put inline layout, `.font()`, `.padding()`, `.foregroundStyle()`, or any styling directly in `body`. Extract every visual chunk into a named `private var` or `private func`.

```swift
// WRONG
var body: some View {
    VStack(spacing: 16) {
        Text(title).font(.headline).foregroundStyle(.primary)
        Button("Tap") { store.send(.buttonTapped) }
            .padding(.horizontal, 24)
    }
}

// RIGHT
var body: some View {
    mainContent
}

private var mainContent: some View {
    VStack(spacing: 16) {
        titleLabel
        actionButton
    }
}
```

### Color assets
Never write manual `Color` extension wrappers. Use Xcode 15 auto-generated asset symbols directly:

```swift
// WRONG
extension Color {
    static let ripeGreen = Color("RipeGreen")
}

// RIGHT
Color(.ripeGreen)   // auto-generated from asset catalog
```

### No static workarounds in extensions
If a stored property is needed on a View, add it to the **main struct body**, not as a `static` in an extension. Making a property `static` purely to bypass the "stored property in extension" compiler error is a code smell — it turns instance state into global state.

```swift
// WRONG — static used only to make the extension compile
extension MyView {
    static let itemHeight: CGFloat = 60   // now shared globally
}

// RIGHT — belongs in the struct
struct MyView: View {
    private let itemHeight: CGFloat = 60
    …
}
```

Layout constants that are genuinely shared / semantic (e.g. design tokens from `RipeLayout`) belong in the `Design/` module, not as ad-hoc statics on a View.

### Access control
- Mark everything `private` unless it must be `public` (cross-module) or `internal` (same-module consumption).
- `public` is required for all types and members in the `Features` SPM package that the `TrackPriceApp` target must see.

## Formatting & Linting

- **SwiftFormat**: indent 4 spaces, max width 120, wrap arguments `before-first`.
- **SwiftLint** (`.swiftlint.yml`): see inline comments in the file for TCA-specific threshold rationale.
- `Features/.build/` is excluded from linting — never lint third-party SPM checkouts.
