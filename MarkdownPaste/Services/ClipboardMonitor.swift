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
        // 1. Guard: is monitoring enabled?
        guard appState.isEnabled else { return }

        // 2. Guard: has clipboard changed?
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // 3. Guard: is this our own write? (marker present)
        guard pasteboard.types?.contains(.markdownPasteMarker) != true else { return }

        // 4. Guard: skip if already has rich text (HTML or RTF)
        if let types = pasteboard.types {
            if types.contains(.html) || types.contains(.rtf) {
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
        let result = converter.convert(markdown: plainText)

        // 8. Write back
        let rtfData = appState.includeRTF ? result.rtf : nil
        writer.write(plainText: plainText, html: result.html, rtf: rtfData)

        // 9. Update change count to avoid re-processing our own write
        lastChangeCount = pasteboard.changeCount

        // 10. Update app state
        appState.conversionCount += 1
        appState.lastConversionDate = Date()
    }
}
