# Marksmith — Milestone 8 QA Checklist

**Build**: Debug
**macOS target**: 13+
**Tester**: Jonathan Cheung
**Date**: 2026-02-21

Mark each item `[x]` when it passes, `[!]` when it fails (add notes below the item).

---

## 1. Installation & First Launch

- [x] App launches without crashing
- [x] `M↓` icon appears in menu bar (template image — adapts to light/dark menu bar)
- [x] No Dock icon appears (LSUIElement app)
- [x] Clicking the icon opens the dropdown menu

---

## 2. Menu Bar Dropdown

- [x] **Enabled** state shows checkmark + "Enabled" label
- [x] **Disabled** state shows "Disabled" label (no checkmark)
- [x] Toggling enable/disable with `⌘E` keyboard shortcut works
- [x] "No conversions yet" shows on first launch (before any conversion)
- [x] After a conversion: "Conversions: N" and "Last: X ago" appear
- [x] "Settings..." button is present
- [x] `⌘,` keyboard shortcut opens Settings
- [x] "Quit Marksmith" button is present
- [x] `⌘Q` keyboard shortcut quits the app

---

## 3. Settings Window — Open & Raise

- [x] Clicking "Settings..." opens the Settings window
- [x] Settings window comes to the front over other apps
- [x] Opening Settings while it's already in the background brings it to the front (the fix from this session)
- [x] `⌘,` shortcut also raises an already-open Settings window
- [x] Settings window has the correct size (~640×440)

---

## 4. Settings — General Tab

- [x] "General" is selected by default in the sidebar
- [x] **Enable Marksmith** toggle reflects current state
  - [x] Toggling off stops conversions (copy Markdown → no enrichment)
  - [x] Toggling on resumes conversions
- [x] **Launch at Login** toggle works
  - [!] Toggle on → app appears in Login Items (verify in System Settings > General > Login Items) — wrong icon (TC-04b)
  - [x] Toggle off → app removed from Login Items
- [x] **Include RTF Format** toggle works
  - [x] Toggle off → pasting in TextEdit (Plain Text mode) works but RTF apps may lose formatting
  - [!] Toggle on → pasting in RTF-aware apps (Pages, Mail) renders formatting — fails in Pages (TC-04c)
- [!] **Notify on Conversion** toggle works — unresponsive when permission denied, no feedback (TC-04d)
  - [x] Toggle on → macOS prompts for notification permission on first conversion
  - [!] After granting permission, a notification fires on each Markdown conversion — fires to Notification Centre only, no banner (TC-04e)
  - [x] Toggle off → no notifications fire
- [x] **Output Font Size** picker has three options: Small (12px), Medium (14px), Large (18px)
  - [x] Changing font size affects the rendered output (paste into Pages/TextEdit and compare)

---

## 5. Settings — Detection Tab

- [x] Detection sensitivity slider has 5 steps (1–5)
  - [x] Step 1: "Very Aggressive (threshold: 1)"
  - [x] Step 2: "Normal (threshold: 2)"
  - [x] Step 3: "Moderate (threshold: 3)"
  - [x] Step 4: "Conservative (threshold: 4)"
  - [x] Step 5: "Very Conservative (threshold: 5)"
- [x] Explanatory text is visible below the slider card
- [x] At threshold 1: plain text with a single `*` or `-` triggers conversion (expected false positive)
- [x] At threshold 5: only heavily marked-up Markdown triggers conversion

---

## 6. Settings — Support Tab

- [x] "Support" tab is visible and selectable in sidebar
- [x] "Buy Me a Coffee" row is present
- [x] Clicking it opens `https://buymeacoffee.com/jonc102` in the default browser

---

## 7. Core Conversion — GFM Pattern Coverage

For each test: copy the snippet, wait ~1 second, paste into a rich text app (TextEdit in Rich Text mode, Pages, or Mail).

### Headings
```
# Heading 1
## Heading 2
### Heading 3
```
- [x] Pastes with H1, H2, H3 styling (progressively smaller)

### Bold & Italic
```
**bold text** and *italic text*
```
- [x] "bold text" is bold; "italic text" is italic

### Strikethrough
```
~~strikethrough~~
```
- [!] Text renders with strikethrough — works in Apple Notes, fails in Google Docs (TC-07a)

### Inline Code
```
Use `code` here
```
- [x] `` `code` `` renders in monospace with grey background

### Code Block
````
```python
def hello():
    print("world")
```
````
- [x] Renders as a code block with monospace font and `#f6f8fa` background

### Unordered List
```
- Item one
- Item two
- Item three
```
- [x] Renders as a bulleted list

### Ordered List
```
1. First
2. Second
3. Third
```
- [x] Renders as a numbered list

### Task List
```
- [x] Done
- [ ] Not done
```
- [!] Renders with checkboxes (checked and unchecked) — renders as bullet points (TC-07b)

### Blockquote
```
> This is a blockquote
```
- [!] Renders with left border and indented grey text — works in Apple Notes, fails in Google Docs and Notion (TC-07c)

### Horizontal Rule
```
---
```
- [!] Renders as a horizontal dividing line — fails in Notion and Apple Notes (TC-07d)

### Link
```
[OpenAI](https://openai.com)
```
- [x] "OpenAI" renders as a blue hyperlink

### Table
```
| Name  | Age |
|-------|-----|
| Alice | 30  |
| Bob   | 25  |
```
- [x] Renders as a formatted table with header row

### Mixed document
```markdown
# My Doc

This has **bold**, *italic*, and `code`.

- Item A
- Item B

> A quote

| Col1 | Col2 |
|------|------|
| a    | b    |
```
- [x] Full document pastes with all elements formatted correctly

---

## 8. Negative Cases — Plain Text Must NOT Convert

Copy each snippet and verify the paste is still plain text (no formatting applied, conversion count does not increment).

- [x] Plain prose: `The quick brown fox jumps over the lazy dog`
- [x] URL only: `https://example.com` 
- [x] Email: `user@example.com`
- [x] Single bullet: `- one item` (at default sensitivity 2)
- [x] Single asterisk: `a * b` (at default sensitivity 2)
- [x] Numbers: `1. only one line`
- [x] Code without surrounding text: `x = 1` (no backticks)

---

## 9. Guard Rail Cases

- [x] **Re-processing prevention**: After a conversion, copying the same text again immediately does NOT trigger a second conversion (marker guard works)
- [x] **Large content**: Copy >100KB of text → no conversion, no crash
- [x] **Empty clipboard**: Clear clipboard (copy a single space, then delete) → no crash
- [!] **Monitor off during copy**: Disable monitoring, copy Markdown, re-enable → the already-copied content is NOT converted (change count guard works) — FAILS (TC-09a)
- [x] **Whitespace-only**: Copy `   \n   ` → no conversion

---

## 10. Source App Exclusions (Semantic HTML Guard)

Copy from each app and verify the clipboard is NOT converted (these apps put semantic HTML on the clipboard already).

- [x] Safari (select text on a webpage, copy) → pastes rich text as-is, no double-conversion
- [x] Chrome (select text on a webpage, copy) → same
- [x] Apple Notes (copy formatted text) → not converted
- [x] Google Docs (copy formatted text) → not converted

Copy from code editors and verify Markdown **IS** converted (editors put only span/div HTML, not semantic HTML):

- [x] VS Code: copy Markdown source text → converts
- [x] Cursor: copy Markdown source text → converts
- [x] Xcode: copy Markdown source text → converts

---

## 11. Paste Destination App Coverage

Paste a converted Markdown snippet (e.g., `**bold** and *italic*`) into each app and verify formatting renders:

- [x] **TextEdit** (Rich Text mode) — bold and italic visible
- [!] **Pages** — bold and italic visible — FAILS, raw Markdown pasted (TC-04c)
- [x] **Mail** (compose window) — bold and italic visible
- [x] **Notion** (web) — formatting renders
- [x] **Slack** — formatting renders (or gracefully falls back to plain text)
- [x] **Terminal** — pastes as plain Markdown source (expected; Terminal is plain-text)
- [x] **VS Code** — pastes as plain Markdown source (expected)

---

## 12. Quit & Relaunch

- [x] Quitting via "Quit Marksmith" exits the app cleanly
- [x] Quitting via `⌘Q` from dropdown exits cleanly
- [x] Relaunching: all settings persist (enable state, sensitivity, font size, RTF toggle)
- [x] Conversion count resets to 0 on relaunch (runtime-only state — expected)

---

## 13. Edge / Regression Cases

- [x] Rapid clipboard changes (copy multiple things quickly) → no crash, no incorrect conversion
- [x] Settings window: switching tabs (General → Detection → Support → General) works without layout glitches
- [x] Resizing the Settings window doesn't break layout
- [x] Menu bar icon remains visible after display sleep/wake
- [x] Menu bar icon remains visible after connecting/disconnecting an external display

---

## Notes

_Record any failures, unexpected behaviour, or observations here._

```
[~] TC-04a: Toggle controls appear grey when window is not focused — NOT A BUG
    Root cause: Standard macOS behaviour — controls are rendered in a muted/
                grey style when the window is inactive (not the key window).
                Clicking the window to focus it restores accent colours.
    Resolution: Expected OS behaviour, no fix required.

[!] TC-04b: Wrong app icon shown in macOS Login Items
    Steps: Toggle "Launch at Login" ON in Settings → General, then open
           System Settings > General > Login Items
    Expected: Marksmith custom app icon (M↓ design)
    Actual: Generic/incorrect icon displayed next to "Marksmith" in
            the Login Items list
    Note: Likely the debug build lacks a properly bundled icon asset, or
          SMAppService is referencing the wrong bundle; verify with a
          release build

[!] TC-04c: Converted Markdown pastes as raw plain text in Pages
    Steps: 1. Enable Marksmith (RTF ON or OFF)
           2. Copy a Markdown snippet (e.g. QA checklist with **bold** and [ ])
           3. Wait for conversion (count incremented, time reset — confirmed)
           4. Paste into Pages
    Expected: Formatted rich text — bold rendered, lists formatted, etc.
    Actual: Raw Markdown source pasted (**asterisks** and [ ] visible as-is)
    Tested: RTF ON (top paste) and RTF OFF (bottom paste) — identical failure
    Scope: Pages-specific. TextEdit (Rich Text mode) renders correctly with
           both RTF ON and OFF — conversion pipeline is working.
    Root cause (likely): Pages ignores public.html and RTF in favour of its
           own internal pasteboard format (com.apple.iWork.pasteboardtype);
           when that is absent it falls back to plain text, skipping HTML/RTF.

[!] TC-04d: No feedback when "Notify on Conversion" toggle is blocked by denied permission
    Root cause: When notification permission is denied in System Settings,
                the toggle is silently unresponsive with no explanation.
    Expected: Toggle should detect denied permission and show actionable
              feedback, e.g. an inline warning "Notifications are disabled in
              System Settings" with a button/link to open Notifications prefs
    Actual: Toggle appears interactive but does nothing; user has no indication
            that permission is the cause or how to fix it
    Resolution: Enabling notifications in System Settings → Notifications →
                Marksmith restores toggle functionality — confirmed working
    Severity: UX issue — functionality works once permission is granted, but
              discoverability is poor for users who denied the initial prompt

[!] TC-04e: Conversion notifications appear in Notification Centre but do not
            banner/pop-up on desktop
    Steps: Enable "Notify on Conversion", grant permission, trigger a conversion
    Expected: A temporary banner notification appears on screen as conversion happens
    Actual: No banner appears; notification is only visible in Notification Centre
            sidebar after the fact
    System Settings: Desktop ✓, Notification Centre ✓, Alert Style = Temporary
    Note: Desktop is checked, Alert Style = Temporary, Focus mode confirmed OFF
          — banners should fire but don't. Root cause: notification delivery
          options in code likely missing .banner from UNNotificationPresentationOptions;
          notifications are being delivered silently to Notification Centre only

[!] TC-04f: App icon missing in notifications and Notification Centre
    Steps: Trigger a conversion notification
    Expected: Marksmith app icon shown alongside notification
    Actual: Empty/blank grid placeholder icon displayed
    Related: Same root cause as TC-04b — debug build lacks properly bundled
             icon asset; verify with a release build

[!] TC-07a: Strikethrough does not render in Google Docs
    Steps: Copy ~~strikethrough~~, wait for conversion, paste into Google Docs
    Expected: Text renders with strikethrough formatting
    Actual: No strikethrough — likely plain text fallback
    Note: Strikethrough confirmed working in Apple Notes. Google Docs uses its
          own internal clipboard format (similar to Pages) and may ignore the
          HTML/RTF strikethrough styling. May be a Google Docs limitation
          rather than a Marksmith bug — investigate HTML output for
          strikethrough tag used (<s> vs <del> vs <strike>)

[!] TC-07b: Task list items render as bullet points instead of checkboxes
    Steps: Copy "- [x] Done\n- [ ] Not done", wait for conversion, paste
           into a rich text app (Apple Notes confirmed)
    Expected: Checked and unchecked checkbox items rendered visually
    Actual: Both items render as plain bullet points; checkbox state lost
    Root cause (likely): HTMLVisitor in MarkdownConverter.swift may not
          have a visitTaskListItem implementation, or is falling back to
          standard list item rendering without injecting checkbox HTML
          (e.g. <input type="checkbox" disabled checked>)

[!] TC-07c: Blockquote does not render in Google Docs or Notion
    Steps: Copy "> This is a blockquote", wait for conversion, paste into
           Google Docs and Notion
    Expected: Text renders with blockquote styling (left border, indented)
    Actual: Blockquote formatting not applied in either app
    Note: Confirmed working in Apple Notes. Google Docs and Notion both use
          their own internal clipboard formats and may strip <blockquote>
          styling. Likely an app-specific limitation consistent with TC-04c
          and TC-07a; not necessarily a Marksmith bug

[!] TC-07d: Horizontal rule does not render in Notion or Apple Notes
    Steps: Copy "---", wait for conversion, paste into Notion and Apple Notes
    Expected: A horizontal dividing line rendered
    Actual: No horizontal rule rendered in either app
    Note: Unlike TC-07c, this also fails in Apple Notes (which passed
          blockquote). May indicate an issue with <hr> rendering in the
          HTML output or RTF conversion, rather than purely an app
          compatibility issue — worth inspecting the generated HTML

[!] TC-09a: Re-enabling monitoring converts pre-existing clipboard content
    Steps: 1. Enable Marksmith
           2. Toggle monitoring OFF via menu bar
           3. Copy a Markdown snippet while monitoring is off
           4. Toggle monitoring back ON (without copying anything new)
    Expected: Already-copied content is NOT converted; monitor should
              establish a new changeCount baseline on re-enable
    Actual: Conversion fires immediately on re-enable — count increments
            and clipboard is enriched with RTF despite no new copy event
    Root cause: ClipboardMonitor records changeCount when the timer fires;
                when paused and resumed, the stale changeCount delta is
                treated as a new copy event instead of being snapshotted
                as the new baseline on start()

[enhancement] ENH-01: Replace checkmark enable/disable with inline toggle in menu bar dropdown
    Current: "✓ Enabled" / "Disabled" as a plain menu item with ⌘E shortcut
    Requested: A row with label on the left and a blue iOS-style Toggle on
               the right (consistent with BetterDisplay's menu bar UI style)
    Design:
      ┌─────────────────────────────────┐
      │  Marksmith          [●    ] │  ← toggle right-aligned, blue when ON
      ├─────────────────────────────────┤
      │  Conversions: 6                 │
      │  Last: 5 min. ago               │
      ├─────────────────────────────────┤
      │  Settings...            ⌘,      │
      │  Quit Marksmith     ⌘Q      │
      └─────────────────────────────────┘
    Notes: ⌘E shortcut should be preserved. Requires replacing the Button/
           Label menu item with a custom SwiftUI view inside MenuBarExtra
           that hosts a Toggle control
```

---

## Bug Fix Verification — Round 2

**Build**: Debug (post-fix)
**Date**: 2026-02-21
**Fixes under test**: TC-09a, TC-07b, TC-07d, TC-04e, TC-04d

---

### V1 — TC-09a: Monitor re-enable must not convert pre-existing clipboard

- [x] Enable Marksmith
- [x] Toggle monitoring **OFF** via menu bar (`⌘E`)
- [x] Copy a Markdown snippet (e.g. `**bold** and *italic*`) while monitoring is off
- [x] Toggle monitoring back **ON** — conversion count must NOT increment
- [x] Wait 5 seconds — count must remain unchanged
- [x] Copy a new Markdown snippet — conversion fires as expected (confirms normal operation still works)

---

### V2 — TC-07b: Task list renders checkboxes (☑/☐), not bullet points

Copy the following, wait ~1s, paste into Apple Notes (Rich Text):

```
- [x] Done
- [ ] Not done
```

- [x] "Done" has a checked ballot box (☑) and no bullet point
- [x] "Not done" has an unchecked ballot box (☐) and no bullet point

---

### V3 — TC-07d: Horizontal rule renders as a visible dividing line

Copy the following, wait ~1s, paste into Apple Notes:

```
Above

---

Below
```

- [x] A visible horizontal line appears between "Above" and "Below"

---

### V4 — TC-04e & TC-04d: Notifications — REMOVED

Notifications feature removed entirely. Banners were unreliable on macOS and
the feature was deemed more annoying than useful. The "Notify on Conversion"
toggle and all UNUserNotificationCenter code have been stripped from the app.
