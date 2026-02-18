# MarkdownPaste

## Project Overview

macOS menu bar utility that monitors the clipboard, detects Markdown content, converts it to rich text (HTML + RTF), and writes it back so pasting renders formatted text in any app.

## Tech Stack

- **Language**: Swift
- **UI**: SwiftUI (MenuBarExtra, macOS 13+)
- **Markdown Parser**: Apple's `swift-markdown` (SPM) — bundles cmark-gfm for full GFM support
- **RTF Generation**: AppKit's NSAttributedString pipeline
- **Build Tool**: XcodeGen (`project.yml` → `.xcodeproj`)
- **Bundle ID**: `com.jonathancheung.MarkdownPaste`

## Project Structure

```
MarkdownPaste/
├── MarkdownPaste/
│   ├── App/           # App entry point, delegate, shared state
│   ├── Views/         # Menu bar dropdown, settings window
│   ├── Services/      # Clipboard monitor, detector, converter, writer
│   ├── Utilities/     # Constants, pasteboard type extensions
│   └── Resources/     # Assets, Info.plist
├── MarkdownPasteTests/
└── Scripts/           # Build/release automation
```

## Key Architecture

- **Clipboard monitoring**: Timer-based polling (0.5s) — macOS has no clipboard change notification API
- **Loop prevention**: Custom marker pasteboard type + changeCount tracking
- **Skip rich content**: If clipboard already has HTML/RTF, don't re-process
- **Detection**: Weighted regex scoring across 15 Markdown patterns
- **Conversion**: swift-markdown AST → styled HTML → RTF via NSAttributedString
- **No sandbox**: Required for general pasteboard access; distributed via DMG

## Build & Run

```bash
# Generate Xcode project
xcodegen generate

# Build
xcodebuild build

# Run tests
xcodebuild test

# Release build (sign + notarize + DMG)
./Scripts/build-release.sh
```

## Conventions

- Minimum deployment target: macOS 13.0 (Ventura)
- No Dock icon (LSUIElement = true)
- Settings stored via @AppStorage (UserDefaults)
- All clipboard operations go through ClipboardWriter to ensure marker is always set
- Max content size: 100KB (skip larger content to avoid blocking main thread)

## Implementation Plan

See `PLAN.md` for full milestones, interface contracts, and agent task assignments.
