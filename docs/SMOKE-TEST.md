# Smoke Test Checklist — v1.2.0

## Installation

- [ ] Download `Marksmith.dmg` from [GitHub Releases](https://github.com/jonc102/marksmith/releases/tag/v1.2.0)
- [ ] Open DMG, drag Marksmith to Applications
- [ ] Bypass Gatekeeper: System Settings > Privacy & Security > Security > Open Anyway
- [ ] App appears in menu bar (no Dock icon)

## Menu Bar Dropdown

- [ ] Toggle switch enables/disables monitoring
- [ ] Conversion count shows after a conversion
- [ ] "About Marksmith" opens About window
- [ ] "Send Feedback..." opens email client with subject "Marksmith v1.2.0 Feedback"
- [ ] "Settings..." opens Settings window
- [ ] "Quit Marksmith" exits the app

## Conversion

- [ ] Copy `# Hello\n**bold**\n- item` from a plain text source (Terminal, code editor)
- [ ] Wait ~0.5s, paste into a rich text app (Notes, Slack, TextEdit) — should render formatted
- [ ] Conversion count increments in menu bar
- [ ] Copy plain English sentence — should NOT convert
- [ ] Copy rich text from a browser — original formatting preserved, no re-conversion

## Settings > General

- [ ] Enable/disable toggle works (mirrored in menu bar)
- [ ] Launch at Login toggles without error
- [ ] Include RTF toggle works (disable, copy Markdown, paste — still works via HTML)
- [ ] Output Font Size picker changes output size

## Settings > Detection

- [ ] Sensitivity slider moves between 1–5
- [ ] At 5 (Very Conservative), simple Markdown is NOT converted
- [ ] At 1 (Very Aggressive), simple Markdown IS converted

## Settings > Support

- [ ] "Buy Me a Coffee" opens https://buymeacoffee.com/jonc102
- [ ] "Report a Bug" opens GitHub Issues with bug report template
- [ ] "Request a Feature" opens GitHub Issues with feature request template

## About Window

- [ ] Shows app icon, "Marksmith", "Version 1.2.0"
- [ ] "View on GitHub" opens https://github.com/jonc102/marksmith
- [ ] "Send Feedback" opens email client with subject "Marksmith v1.2.0 Feedback"

## Edge Cases

- [ ] Rapid copy-paste (multiple copies in <0.5s) — no crash, no infinite loop
- [ ] Copy Markdown, then copy plain text — second paste has no leftover rich text
- [ ] App stays responsive during large Markdown conversion
