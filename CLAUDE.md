# MarkdownPaste

macOS menu bar utility that monitors the clipboard, detects Markdown content, converts it to rich text (HTML + RTF), and writes it back so pasting renders formatted text in any app.

Swift · SwiftUI · macOS 13+ · `swift-markdown` (SPM) · XcodeGen · Bundle ID: `com.jonathancheung.MarkdownPaste`

## Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Commands

| Command | Description |
|---------|-------------|
| `xcodegen generate` | Generate `.xcodeproj` from `project.yml` |
| `xcodebuild build` | Build the app |
| `xcodebuild test` | Run all unit tests |
| `xcodebuild test -only-testing:MarkdownPasteTests/MarkdownDetectorTests` | Run a single test class |
| `./Scripts/build-release.sh` | Archive, sign, notarize, package DMG |

## Architecture

```
MarkdownPaste/
├── MarkdownPaste/
│   ├── App/           # MarkdownPasteApp.swift (@main), AppDelegate, AppState
│   ├── Views/         # MenuBarView (dropdown), SettingsView (prefs window)
│   ├── Services/      # ClipboardMonitor, MarkdownDetector, MarkdownConverter, ClipboardWriter
│   ├── Utilities/     # Constants, PasteboardTypes (marker extension)
│   └── Resources/     # Assets.xcassets, Info.plist
├── MarkdownPasteTests/
└── Scripts/
```

**Data flow**: Timer (0.5s) → changeCount changed? → marker absent? → no existing HTML/RTF? → extract plain text → detect Markdown (score >= threshold) → convert (AST → HTML + RTF) → write back with marker

## Key Files

- `App/MarkdownPasteApp.swift` — `@main` entry point, `MenuBarExtra` scene
- `App/AppState.swift` — Singleton with `@AppStorage` properties (`isEnabled`, `launchAtLogin`, `detectionSensitivity`, `includeRTF`)
- `Services/ClipboardMonitor.swift` — Timer-based polling, orchestrates the full pipeline
- `Services/MarkdownDetector.swift` — 15 weighted regex patterns, `detect(text:threshold:) -> Bool`
- `Services/MarkdownConverter.swift` — `convert(markdown:) -> (html: String, rtf: Data?)` using `MarkupVisitor`
- `Services/ClipboardWriter.swift` — `write(plainText:html:rtf:)`, always sets marker type
- `Utilities/PasteboardTypes.swift` — `NSPasteboard.PasteboardType.markdownPasteMarker` extension
- `Utilities/Constants.swift` — `pollingInterval` (0.5), `maxContentSize` (100KB), `defaultDetectionThreshold` (2)

## Interface Contracts

```swift
// AppState — singleton, consumed by all layers
class AppState: ObservableObject {
    static let shared = AppState()
    @AppStorage("isEnabled") var isEnabled: Bool                        // true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool                // false
    @AppStorage("detectionSensitivity") var detectionSensitivity: Int   // 2
    @AppStorage("includeRTF") var includeRTF: Bool                     // true
    @Published var conversionCount: Int                                 // 0
    @Published var lastConversionDate: Date?                            // nil
}

// Detector — stateless, precompiled regexes
struct MarkdownDetector {
    func detect(text: String, threshold: Int) -> Bool
    func score(text: String) -> Int
}

// Converter — uses swift-markdown AST + HTMLVisitor
struct MarkdownConverter {
    func convert(markdown: String) -> (html: String, rtf: Data?)
}

// Writer — always includes marker type
struct ClipboardWriter {
    func write(plainText: String, html: String, rtf: Data?)
}

// Monitor — owns detector, converter, writer
class ClipboardMonitor {
    init(appState: AppState)
    func start()
    func stop()
}
```

## Code Style

- Swift naming conventions (camelCase properties, PascalCase types)
- `struct` for stateless services (Detector, Converter, Writer); `class` for stateful (AppState, Monitor)
- `@AppStorage` for persisted user preferences; `@Published` for runtime-only state
- Prefer `guard` for early returns in pipeline methods
- Pre-compile `NSRegularExpression` patterns as stored properties, not per-call

## Gotchas

- **No clipboard notification API on macOS** — must poll with `Timer`; 0.5s is the sweet spot for responsiveness vs CPU
- **Infinite loop risk** — writing to pasteboard triggers changeCount bump; always write the marker type and check for it before processing
- **Sandbox disabled** — `NSPasteboard.general` requires unsandboxed access; app is distributed via DMG, not App Store
- **macOS 16+ privacy prompts** — `NSPasteboardUsageDescription` in Info.plist provides the rationale; handle `nil` pasteboard reads gracefully
- **RTF generation must happen on main thread** — `NSAttributedString(html:documentAttributes:)` uses WebKit internally
- **Content size guard** — skip clipboard content > 100KB to avoid blocking the main thread
- **Detection false positives** — single `*` or `-` in plain text can score; threshold default of 2 requires multiple pattern matches

## Testing

- `MarkdownDetectorTests` — 15+ positive cases (GFM elements), 5+ negative (plain text), edge cases (empty, whitespace, boundary)
- `MarkdownConverterTests` — all GFM elements produce correct HTML tags, RTF data is non-nil, HTML entities escaped
- `ClipboardWriterTests` — all pasteboard types written, RTF conditional, marker always present

## Implementation Plan

See `PLAN.md` for full milestones and agent task assignments.
