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

## Installation

Download the latest `.dmg` from [Releases](#), open it, and drag MarkdownPaste to Applications.

## Usage

1. MarkdownPaste appears as a document icon in your menu bar
2. Copy any Markdown text (from a `.md` file, terminal, editor, etc.)
3. Paste into Slack, Telegram, Notes, or any rich text app — it renders formatted

### Menu Bar Controls

- **Toggle** — Enable/disable conversion on the fly
- **Status** — See how many conversions have been performed
- **Settings** — Adjust detection sensitivity, launch at login, RTF inclusion
- **Quit** — Exit the app

## Building from Source

### Prerequisites

- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build

```bash
xcodegen generate
xcodebuild build
```

### Test

```bash
xcodebuild test
```

### Release

```bash
./Scripts/build-release.sh
```

This archives, code-signs, notarizes, and packages the app into a `.dmg`.

## How It Works

```
Clipboard change detected (polling every 0.5s)
  → Is this our own write? Skip (marker check)
  → Already has HTML/RTF? Skip (rich content)
  → Extract plain text
  → Score against 15 Markdown patterns
  → Score >= threshold? Convert!
  → Parse Markdown → AST → Styled HTML + RTF
  → Write plain text + HTML + RTF + marker back to clipboard
```

## License

MIT
