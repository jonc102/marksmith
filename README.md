# MarkdownPaste

A lightweight macOS menu bar utility that automatically converts Markdown on your clipboard to rich text, so pasting into Slack, Telegram, Notes, and other apps "just works" with formatting.

## The Problem

When you copy text from `.md` files or code editors, the clipboard only contains plain text. Pasting into apps like Slack or Apple Notes shows raw Markdown syntax — `# headings`, `**bold**`, `- lists` — instead of formatted text.

## The Solution

MarkdownPaste sits in your menu bar and watches the clipboard. When it detects Markdown content, it silently converts it to rich text (HTML + RTF) and writes it back. The next time you paste, the receiving app gets properly formatted content.

## Features

- **Automatic detection** — Weighted scoring across 15 Markdown patterns minimizes false positives
- **Full GFM support** — Headings, bold, italic, links, images, code blocks, tables, task lists, strikethrough, footnotes
- **Styled output** — System font, syntax-highlighted code blocks, bordered tables, styled blockquotes
- **Non-intrusive** — Menu bar only, no Dock icon, no windows unless you open Settings
- **Smart skip** — Ignores clipboard content that already has rich formatting (copied from web, docs, etc.)
- **Configurable sensitivity** — Adjust detection threshold from aggressive (1) to conservative (5)
- **Launch at Login** — Optional auto-start via SMAppService
- **Lightweight** — <1% CPU with 0.5s polling interval

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ (for building from source)

---

## Installation

1. Download the latest `.dmg` from [Releases](#).
2. Open it and drag MarkdownPaste to your Applications folder.
3. On first launch, macOS Gatekeeper will block the app because it is unsigned. To bypass: right-click the app in Finder → **Open** → **Open** in the dialog. You only need to do this once.

> **Why unsigned?** The app is distributed directly rather than through the Mac App Store. It makes no network connections and all processing happens locally.

After the first launch, MarkdownPaste appears as an icon in your menu bar. There is no Dock icon and no main window.

---

## Usage

1. Copy any Markdown text — from a `.md` file, a code editor, a terminal, anywhere.
2. MarkdownPaste detects and converts the Markdown within ~0.5 seconds, silently.
3. Paste into your target app — Slack, Notes, Mail, Telegram, etc. — and the content renders formatted.

You don't have to do anything differently. Copy and paste as normal.

### Menu Bar

Click the menu bar icon to open the dropdown:

| Item | Shortcut | Description |
|------|----------|-------------|
| **Enabled / Disabled** | `⌘E` | Toggle active monitoring on and off. |
| **Conversions count** | — | Number of conversions performed this session. |
| **Last:** | — | Relative time of the most recent conversion. |
| **Settings...** | `⌘,` | Open the Settings window. |
| **Quit MarkdownPaste** | `⌘Q` | Exit the app. |

The conversion count resets when you quit and relaunch.

### Settings

**General tab**

- **Enable MarkdownPaste** — Master on/off switch. Mirrored by the menu bar toggle.
- **Launch at Login** — Registers MarkdownPaste as a login item via `SMAppService`.
- **Include RTF format** — When enabled, the clipboard is written with both HTML and RTF. See [RTF vs HTML](#rtf-vs-html).

**Detection tab**

- **Detection Sensitivity** — Slider from 1 (Very Aggressive) to 5 (Very Conservative), defaulting to 2 (Normal). Controls the scoring threshold; see [Detection Sensitivity](#detection-sensitivity).

---

## What Gets Converted

MarkdownPaste supports the full GitHub Flavored Markdown (GFM) spec:

| Element | Syntax |
|---------|--------|
| Headings | `# H1` through `###### H6` |
| Bold | `**text**` |
| Italic | `*text*` |
| Strikethrough | `~~text~~` |
| Links | `[label](url)` |
| Images | `![alt](url)` |
| Inline code | `` `code` `` |
| Code blocks | ` ```lang ... ``` ` |
| Blockquotes | `> text` |
| Unordered lists | `- item`, `* item`, `+ item` |
| Ordered lists | `1. item` |
| Task lists | `- [ ] todo`, `- [x] done` |
| Tables | GFM pipe syntax |
| Horizontal rules | `---`, `***`, `___` |
| Footnotes | `[^1]` |

The output uses a styled HTML template: system font (`-apple-system`), monospace code blocks with a light grey background, bordered tables, and indented blockquotes. The original plain text is always preserved alongside the formatted versions in the clipboard.

---

## What Gets Skipped

MarkdownPaste runs a 10-step guard pipeline and skips conversion if any guard trips:

1. **App disabled** — Monitoring is off.
2. **Clipboard unchanged** — No new copy event since the last check.
3. **Our own write** — The clipboard was written by MarkdownPaste itself (detected via a private marker). Prevents infinite re-conversion loops.
4. **Semantic HTML present** — The clipboard already contains structured HTML from a browser, word processor, or rich text app. Detected by looking for tags like `<h1>`, `<p>`, `<ul>`, `<table>`, `<strong>`, etc. Correctly skips content from: Chrome/Safari, Apple Notes, Google Docs, Notion, Confluence, Word.
5. **No plain text** — The clipboard has no plain text representation.
6. **Content > 100KB** — Skipped to avoid blocking the main thread.
7. **Blank content** — Whitespace-only text.
8. **Score below threshold** — The Markdown detection score doesn't meet the configured sensitivity threshold.

**Note on IDE/editor copied code:** VS Code, Cursor, IntelliJ, and similar editors place syntax-highlighted HTML on the clipboard, but using only `<div>`, `<span>`, and `<pre>` tags with inline color styles — no semantic HTML tags. MarkdownPaste treats this as plain text, so Markdown in your code editor gets converted normally.

---

## App Compatibility

**Works well:**
Slack, Apple Notes, Mail, Telegram, Bear, TextEdit (Rich Text mode), Pages, Word.

**Paste is plain text (by design):**
Terminal, code editors (VS Code, Xcode, etc.) — these accept only plain text. The plain text representation is always preserved in the clipboard, so pasting raw Markdown into an editor still works correctly.

**Already handles Markdown natively:**
Obsidian, Typora, iA Writer — these render Markdown directly. MarkdownPaste's conversion is redundant but harmless; the app detects its own output and won't re-convert.

---

## Detection Sensitivity

The detection engine scores each clipboard change against 15 regex patterns:

| Pattern | Weight |
|---------|--------|
| Code fences (` ``` `) | 4 |
| Tables (`\|---|`) | 4 |
| Task lists (`- [ ]`) | 4 |
| Headings (`# ...`) | 3 |
| Links (`[text](url)`) | 3 |
| Images (`![alt](url)`) | 3 |
| Strikethrough (`~~text~~`) | 3 |
| Footnotes (`[^1]`) | 3 |
| Bold (`**text**`) | 2 |
| Unordered lists (`- item`) | 2 |
| Ordered lists (`1. item`) | 2 |
| Inline code (`` `code` ``) | 2 |
| Blockquotes (`> text`) | 2 |
| Horizontal rules (`---`) | 2 |
| Italic (`*text*`) | 1 |

Each pattern's contribution is capped at 3 matches. The total score is compared against the sensitivity threshold:

| Slider | Label | Threshold |
|--------|-------|-----------|
| 1 | Very Aggressive | 1 |
| 2 | Normal (default) | 2 |
| 3 | Moderate | 3 |
| 4 | Conservative | 4 |
| 5 | Very Conservative | 5 |

If you see unwanted conversions on plain text, increase the sensitivity. If valid Markdown isn't being converted, lower it.

---

## RTF vs HTML

When you paste, the receiving app picks the richest format it accepts from the clipboard:

- **RTF** — Used by most native macOS apps: Mail, Notes, Pages, Word, TextEdit. Produces the most reliable formatting in native apps.
- **HTML** — Used by web-based and Electron apps: Slack, Notion, Telegram Desktop.

By default, **Include RTF** is on and both formats are written. If you notice formatting issues in specific apps (extra spacing, font mismatches), try disabling RTF. The app will write HTML only, and apps that prefer RTF will fall back to HTML or plain text.

---

## Privacy & Performance

MarkdownPaste reads only the plain text representation of your clipboard. It makes no network connections. All detection and conversion happen locally. Clipboard content is never logged, transmitted, or persisted.

On macOS 14 (Sonoma) and later, macOS may show a one-time prompt asking whether MarkdownPaste can access the clipboard. Allow it — this is the core function of the app.

CPU usage is negligible (<1%) during idle polling. Conversion of typical Markdown documents (a few KB) completes in under 1 millisecond.

---

## Troubleshooting

**Pasting still shows raw Markdown.**
- Check the menu bar — is monitoring enabled (checkmark next to "Enabled")?
- Wait half a second after copying before pasting. The conversion runs on a 0.5s timer.
- Check the conversion count. If it's incrementing, conversion is happening but the target app may not accept rich text (e.g., a plain-text-only input field).
- If the count isn't incrementing, the content may not score above the threshold. Lower the detection sensitivity, or check whether the text contains enough Markdown patterns (a single `-` or `*` without other signals won't score enough at the default threshold).

**The app converted something it shouldn't have.**
Increase the detection sensitivity toward Conservative.

**Converted output looks wrong in a specific app.**
Try toggling "Include RTF format" off. Some apps handle HTML better than RTF.

**The app was blocked by macOS on first launch.**
Right-click → Open → Open. If System Settings > Privacy & Security shows a "blocked" prompt, click "Open Anyway." After the first launch, double-clicking works normally.

**The app disappeared from the menu bar.**
Relaunch from Applications. If "Launch at Login" was enabled, it will reappear on next login.

---

## Building from Source

### Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build

```bash
xcodegen generate
xcodebuild build -project MarkdownPaste.xcodeproj -scheme MarkdownPaste
```

### Test

```bash
xcodebuild test -project MarkdownPaste.xcodeproj -scheme MarkdownPaste
```

56 unit tests cover the detection engine (22 tests), Markdown-to-HTML converter (23 tests), and clipboard writer (11 tests).

### Release

```bash
./Scripts/build-release.sh
```

Builds and packages the app into an unsigned `.dmg`. Optionally install `create-dmg` (`brew install create-dmg`) for a drag-to-Applications layout.

For signed/notarized builds (requires Apple Developer ID):

```bash
SIGN=1 NOTARIZE=1 ./Scripts/build-release.sh
```

---

## How It Works

```
Clipboard change detected (polling every 0.5s)
  → Is this our own write? Skip (marker check)
  → Already has semantic HTML? Skip (rich content)
  → Extract plain text
  → Empty or > 100KB? Skip
  → Score against 15 weighted Markdown patterns
  → Score >= threshold? Convert!
  → Parse Markdown → AST (swift-markdown) → Styled HTML + RTF
  → Write plain text + HTML + RTF + marker back to clipboard
```

## Architecture

```
MarkdownPaste/
├── App/           # Entry point, lifecycle, shared state
├── Services/      # Detection, conversion, clipboard I/O
├── Views/         # Menu bar dropdown, settings window
├── Utilities/     # Constants, pasteboard type extensions
└── Resources/     # Info.plist, asset catalog
```

| Component | Role |
|-----------|------|
| `MarkdownDetector` | 15 regex patterns with weighted scoring (headings ×3, code blocks ×4, tables ×4, etc.) |
| `MarkdownConverter` | AST-based HTML generation via `MarkupVisitor`, CSS styling, RTF via `NSAttributedString` |
| `ClipboardMonitor` | Timer-based polling with 10-step guard pipeline (enabled → changed → marker → rich → text → size → detect → convert → write → state) |
| `ClipboardWriter` | Multi-format pasteboard write with self-detection marker |
| `AppState` | `@MainActor` singleton with `@AppStorage` preferences and `SMAppService` login management |

## License

MIT
