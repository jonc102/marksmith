# MarkdownPaste - macOS Menu Bar App Implementation Plan

## Context

Copying text from `.md` files and pasting into apps like Slack or Telegram results in raw Markdown syntax (hashes, asterisks, etc.) appearing literally instead of rendering as formatted text. This happens because text editors only place plain text on the clipboard — without an HTML or RTF representation, receiving apps have nothing to render.

**Goal**: Build a native macOS menu bar app that automatically monitors the clipboard, detects Markdown content, converts it to rich text (HTML + RTF), and writes it back — so pasting "just works" with formatting in any app.

---

## Architecture Overview

- **App type**: Menu bar-only utility (no Dock icon, no main window)
- **Tech**: Swift + SwiftUI, macOS 13+ (Ventura) for `MenuBarExtra` and `SMAppService`
- **Bundle ID**: `com.jonathancheung.MarkdownPaste`
- **Single dependency**: Apple's `swift-markdown` (SPM) — bundles `cmark-gfm` for full GFM support
- **Distribution**: Code-signed + notarized `.dmg`

### Data Flow

```
Timer (0.5s) → changeCount changed?
  → Self-marker present? Skip
  → Already has HTML/RTF? Skip
  → Extract plain text
  → MarkdownDetector: heuristic score ≥ threshold?
  → MarkdownConverter: MD → AST → HTML (styled) + RTF
  → ClipboardWriter: write .string + .html + .rtf + .marker back
```

---

## Project Structure

```
MarkdownPaste/
├── MarkdownPaste.xcodeproj
├── MarkdownPaste/
│   ├── App/
│   │   ├── MarkdownPasteApp.swift       # @main, MenuBarExtra scene
│   │   ├── AppDelegate.swift            # Lifecycle, start/stop monitor
│   │   └── AppState.swift               # @AppStorage-backed shared state
│   ├── Views/
│   │   ├── MenuBarView.swift            # Dropdown: toggle, status, quit
│   │   └── SettingsView.swift           # Preferences: General + Detection tabs
│   ├── Services/
│   │   ├── ClipboardMonitor.swift       # Timer-based NSPasteboard polling
│   │   ├── MarkdownDetector.swift       # Regex heuristic scoring (15 patterns)
│   │   ├── MarkdownConverter.swift      # swift-markdown → HTML + RTF
│   │   └── ClipboardWriter.swift        # NSPasteboardItem multi-format write
│   ├── Utilities/
│   │   ├── Constants.swift
│   │   └── PasteboardTypes.swift        # Custom marker type extension
│   └── Resources/
│       ├── Assets.xcassets/             # Menu bar icon (SF Symbol template)
│       └── Info.plist                   # LSUIElement=YES, NSPasteboardUsageDescription
├── MarkdownPasteTests/
│   ├── MarkdownDetectorTests.swift
│   ├── MarkdownConverterTests.swift
│   └── ClipboardWriterTests.swift
├── Scripts/
│   └── build-release.sh                # Archive, sign, notarize, DMG
└── README.md
```

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Clipboard monitoring | Polling (0.5s Timer) | macOS has no clipboard change notification API. <1% CPU. |
| Loop prevention | Marker pasteboard type + changeCount | Dual strategy prevents all re-processing of own writes |
| Skip rich content | Check for existing .html/.rtf | Don't re-process content copied from web/docs |
| Markdown parser | Apple's swift-markdown | Official, bundles cmark-gfm, full GFM, HTMLFormatter built-in |
| RTF generation | NSAttributedString pipeline | Built into AppKit, no extra dependency |
| Sandboxing | Disabled | Clipboard monitoring requires general pasteboard access; distributing via DMG (not App Store) |
| Min macOS version | 13.0 (Ventura) | Required for MenuBarExtra and SMAppService APIs |

---

## Edge Cases Handled

- **Self-triggered changes**: Marker type + changeCount tracking prevents infinite loops
- **Already-rich clipboard**: Skipped if .html or .rtf already present
- **Very large content**: Skip if >100KB to avoid blocking main thread
- **Non-text clipboard** (images, files): `guard let plainText` returns early
- **macOS 16 privacy prompts**: NSPasteboardUsageDescription provides rationale; graceful nil handling if denied
- **False positive detection**: Low default threshold (2) catches most Markdown; user can increase to 5 for conservative mode

---

## Development Milestones

### Milestone 1: Project Skeleton
**Goal**: Xcode project builds and runs as an empty menu bar app.

- [ ] Create Xcode project directory structure
- [ ] Create `project.yml` (XcodeGen) with macOS 13 deployment target
- [ ] Add `swift-markdown` SPM dependency (`https://github.com/swiftlang/swift-markdown.git`)
- [ ] Create `Info.plist` with `LSUIElement = true` and `NSPasteboardUsageDescription`
- [ ] Create `Assets.xcassets` with `AppIcon.appiconset`
- [ ] Create `MarkdownPaste.entitlements` (no sandbox)
- [ ] Create `Constants.swift` — app name, bundle ID, polling interval, max content size, default threshold
- [ ] Create `PasteboardTypes.swift` — `NSPasteboard.PasteboardType.markdownPasteMarker` extension
- [ ] Create `AppState.swift` — singleton with `@AppStorage` properties: `isEnabled`, `launchAtLogin`, `detectionSensitivity`, `includeRTF`, plus `@Published conversionCount` and `lastConversionDate`
- [ ] Create minimal `MarkdownPasteApp.swift` — `@main`, `MenuBarExtra` with SF Symbol `doc.richtext`, `.menu` style
- [ ] Create stub `AppDelegate.swift` — `NSApplicationDelegateAdaptor`, empty lifecycle methods

**Acceptance**: `xcodegen generate && xcodebuild build` succeeds. App appears in menu bar with icon.

---

### Milestone 2: Markdown Detection Engine
**Goal**: `MarkdownDetector` correctly identifies Markdown content with weighted scoring.

- [ ] Create `MarkdownDetector.swift` with pre-compiled `NSRegularExpression` patterns:
  - Headings `^#{1,6}\s+.+` (weight 3)
  - Bold `\*\*[^*]+\*\*` (weight 2)
  - Italic `(?<![*])\*[^*]+\*(?![*])` (weight 1)
  - Links `\[([^\]]+)\]\(([^)]+)\)` (weight 3)
  - Images `!\[([^\]]*?)\]\(([^)]+)\)` (weight 3)
  - Unordered lists `^\s*[-*+]\s+.+` (weight 2)
  - Ordered lists `^\s*\d+\.\s+.+` (weight 2)
  - Code blocks `` ^``` `` (weight 4)
  - Inline code `` `[^`]+` `` (weight 2)
  - Blockquotes `^>\s+.+` (weight 2)
  - Tables `\|[-:]+\|` (weight 4)
  - Task lists `^\s*-\s+\[[ xX]\]\s+` (weight 4)
  - Strikethrough `~~[^~]+~~` (weight 3)
  - Horizontal rules `^-{3,}$|^\*{3,}$|^_{3,}$` (weight 2)
  - Footnotes `\[\^\d+\]` (weight 3)
- [ ] Implement `score(text:) -> Int` — sum weighted matches, cap each pattern at `weight * 3` matches
- [ ] Implement `detect(text:threshold:) -> Bool` — score ≥ threshold
- [ ] Create `MarkdownDetectorTests.swift`:
  - Positive: heading-only, bold+italic, full GFM doc, code blocks, tables, task lists (15+ cases)
  - Negative: plain English, single-line text, code without backticks, URLs without brackets (5+ cases)
  - Edge: empty string, whitespace only, single `*`, threshold boundary cases

**Acceptance**: All unit tests pass. Detector runs in <5ms on typical documents.

---

### Milestone 3: Markdown-to-Rich-Text Converter
**Goal**: `MarkdownConverter` transforms Markdown into styled HTML and RTF using `swift-markdown` AST.

- [ ] Create `MarkdownConverter.swift` with `convert(markdown:) -> (html: String, rtf: Data?)`
- [ ] Implement `HTMLVisitor` conforming to `MarkupVisitor` protocol (Result = String):
  - Document, Heading (h1-h6), Paragraph, Text (with HTML escaping)
  - Strong (`<strong>`), Emphasis (`<em>`), Strikethrough (`<del>`)
  - Link (`<a href>`), Image (`<img src>`)
  - InlineCode (`<code>`), CodeBlock (`<pre><code>`)
  - BlockQuote (`<blockquote>`), ThematicBreak (`<hr>`)
  - OrderedList (`<ol>`), UnorderedList (`<ul>`), ListItem (`<li>` with checkbox support)
  - Table (`<table>`), TableHead (`<thead>`), TableBody (`<tbody>`), TableRow (`<tr>`), TableCell (`<th>`/`<td>`)
  - SoftBreak (space), LineBreak (`<br>`), HTMLBlock (passthrough)
- [ ] Implement CSS styling wrapper: system font, code background `#f0f0f0`, table borders, blockquote left-border, monospace for code
- [ ] Implement RTF generation: styled HTML → `NSAttributedString(html:documentAttributes:)` → `.data(from:documentAttributes: [.documentType: .rtf])`
- [ ] Create `MarkdownConverterTests.swift`:
  - Headings produce `<h1>`–`<h6>` tags
  - Bold/italic produce `<strong>`/`<em>`
  - Links produce `<a>` with correct href
  - Code blocks produce `<pre><code>` with language class
  - Tables produce full `<table>` structure
  - GFM task lists produce checkboxes
  - RTF data is non-nil for valid markdown
  - HTML entities are properly escaped (`<`, `>`, `&`, `"`)

**Acceptance**: All unit tests pass. Converter handles all GFM elements. RTF output is valid. Runs in <100ms.

---

### Milestone 4: Clipboard Read/Write Integration
**Goal**: `ClipboardWriter` and `ClipboardMonitor` form the complete clipboard pipeline.

- [ ] Create `ClipboardWriter.swift`:
  - `write(plainText:html:rtf:)` method
  - Creates single `NSPasteboardItem` with `.string`, `.html`, optional `.rtf`, and `.markdownPasteMarker`
  - Uses `pasteboard.clearContents()` then `pasteboard.writeObjects([item])`
- [ ] Create `ClipboardMonitor.swift`:
  - Holds references to `AppState`, `MarkdownDetector`, `MarkdownConverter`, `ClipboardWriter`
  - `start()`: record initial `changeCount`, create `Timer.scheduledTimer` at 0.5s on `.common` RunLoop mode
  - `stop()`: invalidate timer
  - `checkClipboard()` pipeline:
    1. Guard `appState.isEnabled`
    2. Guard `changeCount != lastChangeCount`, update `lastChangeCount`
    3. Guard marker type NOT present (self-detection)
    4. Guard `.html` and `.rtf` NOT already present (skip rich content)
    5. Guard `plainText` exists and `count ≤ 100KB`
    6. Guard `detector.detect(text:threshold:)` passes
    7. Call `converter.convert(markdown:)`
    8. Call `writer.write(plainText:html:rtf:)` — pass RTF only if `appState.includeRTF`
    9. Update `lastChangeCount` to new `pasteboard.changeCount`
    10. Increment `appState.conversionCount`, set `appState.lastConversionDate`
- [ ] Create `ClipboardWriterTests.swift`:
  - Verifies all pasteboard types are written (`.string`, `.html`, `.markdownPasteMarker`)
  - Verifies RTF is included when requested, omitted when not
  - Verifies marker type is always present
- [ ] Wire `AppDelegate.applicationDidFinishLaunching` to create and start `ClipboardMonitor`

**Acceptance**: Copy raw Markdown from Terminal → paste into TextEdit → renders as formatted text. Copying from web browser (already rich) is not re-processed. No infinite loops.

---

### Milestone 5: Menu Bar UI & Settings
**Goal**: Full menu bar dropdown and Settings window with General + Detection tabs.

- [ ] Create `MenuBarView.swift` (menu-style dropdown):
  - Toggle: "Enabled" / "Disabled" with checkmark, bound to `appState.isEnabled`
  - Divider
  - Status: "Conversions: N" and "Last: [relative time]" (disabled menu items)
  - Divider
  - "Settings..." menu item → opens Settings window (`NSApp.sendAction(Selector(("showSettingsWindow:")))`)
  - "Quit MarkdownPaste" menu item → `NSApplication.shared.terminate(nil)`
- [ ] Create `SettingsView.swift` with `TabView`:
  - **General tab**:
    - Toggle: "Enable MarkdownPaste" bound to `appState.isEnabled`
    - Toggle: "Launch at Login" bound to `appState.launchAtLogin` (uses `SMAppService.mainApp.register/unregister`)
    - Toggle: "Include RTF format" bound to `appState.includeRTF`
  - **Detection tab**:
    - Slider: "Detection Sensitivity" (1=Aggressive … 5=Conservative) bound to `appState.detectionSensitivity`
    - Help text explaining sensitivity levels
- [ ] Update `MarkdownPasteApp.swift`:
  - Add `Settings` scene with `SettingsView`
  - Pass `appState` as `@EnvironmentObject`

**Acceptance**: Menu bar shows toggle, status, and settings. Settings window opens with two tabs. Toggling "Enabled" stops/starts clipboard monitoring. Launch at Login registers/unregisters with `SMAppService`.

---

### Milestone 6: Project Configuration & Build
**Goal**: Project builds from clean checkout. Build script produces signed DMG.

- [ ] Finalize `project.yml` with all source files, test target, and signing configuration
- [ ] Create `Scripts/build-release.sh`:
  - `xcodebuild archive` with Release configuration
  - `xcodebuild -exportArchive` with `ExportOptions.plist` (method: `developer-id`)
  - `create-dmg` to package `.app` into `.dmg`
  - `xcrun notarytool submit` + `xcrun stapler staple`
- [ ] Create `ExportOptions.plist` (method: `developer-id`)
- [ ] Verify clean build: `xcodegen generate && xcodebuild build`
- [ ] Verify tests pass: `xcodebuild test`

**Acceptance**: `build-release.sh` produces a signed, notarized `.dmg`. App installs and runs on a clean Mac.

---

## Agent Task Assignment

Tasks are designed for parallel execution by independent agents. Dependencies are noted.

### Agent A: Project Foundation
**Scope**: Milestone 1 (all items)
**Depends on**: Nothing
**Outputs**: Project skeleton that compiles and runs as empty menu bar app

### Agent B: Core Engine
**Scope**: Milestone 2 + Milestone 3
**Depends on**: Milestone 1 directory structure (can stub imports)
**Outputs**: `MarkdownDetector.swift`, `MarkdownConverter.swift`, and their test files

### Agent C: Clipboard Integration
**Scope**: Milestone 4
**Depends on**: Agent B's interfaces (detector/converter signatures)
**Outputs**: `ClipboardWriter.swift`, `ClipboardMonitor.swift`, `ClipboardWriterTests.swift`, wired `AppDelegate`

### Agent D: UI Layer
**Scope**: Milestone 5
**Depends on**: Agent A's `AppState.swift` (properties and types)
**Outputs**: `MenuBarView.swift`, `SettingsView.swift`, updated `MarkdownPasteApp.swift`

### Integration (Sequential)
**Scope**: Milestone 6
**Depends on**: All agents complete
**Outputs**: Final `project.yml`, build verification, build script

---

## Interface Contracts

These signatures must be respected across all agents:

### AppState (Agent A defines, all agents consume)
```swift
class AppState: ObservableObject {
    static let shared = AppState()
    @AppStorage("isEnabled") var isEnabled: Bool              // default: true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool      // default: false
    @AppStorage("detectionSensitivity") var detectionSensitivity: Int  // default: 2
    @AppStorage("includeRTF") var includeRTF: Bool            // default: true
    @Published var conversionCount: Int                        // default: 0
    @Published var lastConversionDate: Date?                   // default: nil
}
```

### MarkdownDetector (Agent B defines, Agent C consumes)
```swift
struct MarkdownDetector {
    func detect(text: String, threshold: Int) -> Bool
    func score(text: String) -> Int
}
```

### MarkdownConverter (Agent B defines, Agent C consumes)
```swift
struct MarkdownConverter {
    func convert(markdown: String) -> (html: String, rtf: Data?)
}
```

### ClipboardWriter (Agent C defines internally)
```swift
struct ClipboardWriter {
    func write(plainText: String, html: String, rtf: Data?)
}
```

### ClipboardMonitor (Agent C defines, Agent A/D wires)
```swift
class ClipboardMonitor {
    init(appState: AppState)
    func start()
    func stop()
}
```

### PasteboardTypes (Agent A defines, Agent C consumes)
```swift
extension NSPasteboard.PasteboardType {
    static let markdownPasteMarker: NSPasteboard.PasteboardType
}
```

### Constants (Agent A defines, all agents consume)
```swift
enum Constants {
    static let pollingInterval: TimeInterval  // 0.5
    static let maxContentSize: Int            // 100_000
    static let defaultDetectionThreshold: Int // 2
}
```

---

## Documentation Maintenance

`CLAUDE.md` and `README.md` must be kept in sync as implementation proceeds. Update them at each milestone:

| Milestone | CLAUDE.md Updates | README.md Updates |
|-----------|-------------------|-------------------|
| 1 — Skeleton | Confirm architecture matches actual files; update commands if project.yml changes | No changes needed |
| 2 — Detection | Update Key Files if interfaces changed; add any new gotchas discovered | No changes needed |
| 3 — Converter | Update Interface Contracts if signatures evolved; note any threading gotchas | No changes needed |
| 4 — Clipboard | Update data flow if pipeline changed; add integration gotchas | No changes needed |
| 5 — UI & Settings | Update Key Files with final view files; confirm settings list | Update Features section if any were added/cut |
| 6 — Build & Release | Verify all Commands work as documented; remove "planned" qualifiers | Update Installation with actual release link; confirm build-from-source steps work |

**Rule**: Before marking a milestone as complete, verify that CLAUDE.md and README.md accurately reflect the current state of the codebase. Remove any references to planned/future structure that now exists.

---

## Verification Plan

1. **Unit tests**: `xcodebuild test` — detector covers 15+ positive, 5+ negative, edge cases; converter tests all GFM elements
2. **Manual QA matrix**:
   - Copy `# Heading\n**bold**\n- list` from Terminal → paste in Slack → should render formatted
   - Copy plain English sentence → paste → should remain plain text (not converted)
   - Copy from web browser (already rich) → paste → original behavior preserved
   - Copy GFM table → paste in Apple Notes → should render as table
   - Toggle app off → copy Markdown → paste → should remain raw (no conversion)
3. **Performance**: Detector <5ms, converter <100ms on typical documents
4. **Distribution**: Install from DMG on clean Mac, verify launch-at-login, verify Gatekeeper accepts notarized app
