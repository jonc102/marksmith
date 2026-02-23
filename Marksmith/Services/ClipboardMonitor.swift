import AppKit

@MainActor
class ClipboardMonitor {
    private let appState: AppState
    private let detector = MarkdownDetector()
    private let converter = MarkdownConverter()
    private let writer = ClipboardWriter()

    private var timer: Timer?
    private var lastChangeCount: Int

    private let pasteboard = NSPasteboard.general

    init(appState: AppState) {
        self.appState = appState
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        // Record current change count to avoid processing existing clipboard content
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(
            withTimeInterval: Constants.pollingInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkClipboard()
            }
        }
        // Ensure timer fires during UI tracking (e.g., menu open)
        RunLoop.current.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        // 1. Guard: has clipboard changed?
        // Always track changeCount even when disabled, so that re-enabling
        // monitoring does not process clipboard content copied while paused.
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // 2. Guard: is monitoring enabled?
        guard appState.isEnabled else { return }

        // 3. Guard: is this our own write? (marker present)
        guard pasteboard.types?.contains(.markdownPasteMarker) != true else { return }

        // 4. Guard: skip if clipboard has semantically rich HTML (from browsers, docs, etc.)
        //
        // Code editors put syntax-highlighted HTML on the clipboard, but it's just
        // styled <div>/<span>/<pre> wrappers — not rendered Markdown. We only skip
        // if the HTML contains semantic tags that indicate actual rich content.
        //
        // Editor clipboard formats (all use only div/span/pre + inline styles):
        //   VS Code, Cursor, Windsurf — <div style="..."><span style="color:...">
        //   JetBrains (IntelliJ, WebStorm, PyCharm) — <pre style="..."><span style="...">
        //   Atom, Zed, TextMate — <div>/<span> with inline styles
        //   Xcode — RTF only (no HTML), handled by removing RTF-only guard
        //
        // Apps with semantic HTML (correctly skipped):
        //   Browsers, Apple Notes, Google Docs, Microsoft Office, Notion
        //
        // Plain-text-only editors (no guard needed):
        //   Terminal, Sublime Text, BBEdit, vim, emacs, nano
        if let types = pasteboard.types, types.contains(.html) {
            if let html = pasteboard.string(forType: .html), hasSemanticHTML(html) {
                return
            }
        }

        // 5. Guard: extract plain text, check size
        guard let plainText = pasteboard.string(forType: .string) else { return }
        guard plainText.count <= Constants.maxContentSize else { return }
        guard !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 6. Guard: detect Markdown
        let threshold = appState.detectionSensitivity
        guard detector.detect(text: plainText, threshold: threshold) else { return }

        // 7. Convert
        let result = converter.convert(markdown: plainText, fontSize: appState.baseFontSize)

        // 8. Write back
        let rtfData = appState.includeRTF ? result.rtf : nil
        writer.write(plainText: plainText, html: result.html, rtf: rtfData)

        // 9. Update change count to avoid re-processing our own write
        lastChangeCount = pasteboard.changeCount

        // 10. Update app state
        appState.conversionCount += 1
        appState.lastConversionDate = Date()

    }

    /// Check if HTML contains semantic content tags (from browsers, docs, etc.)
    /// vs just styled wrappers from code editors (div/span/pre with color styles).
    ///
    /// Note: <pre> is excluded because JetBrains IDEs wrap syntax-highlighted code
    /// in <pre> tags. A browser copying a rendered page will always have other
    /// semantic tags alongside <pre> (e.g., <p>, <h1>, <li>).
    private func hasSemanticHTML(_ html: String) -> Bool {
        let semanticTags = [
            "<h1", "<h2", "<h3", "<h4", "<h5", "<h6",
            "<strong", "<b>", "<b ",
            "<em>", "<i>", "<i ",
            "<ul", "<ol", "<li",
            "<table", "<blockquote",
            "<p>", "<p ",
        ]
        let lowered = html.lowercased()
        return semanticTags.contains { lowered.contains($0) }
    }
}
