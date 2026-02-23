import XCTest
@testable import Marksmith

// MARK: - Fixtures

private let typicalMarkdown = """
# Project Overview

This document describes the **Marksmith** utility for macOS.

## Features

- Automatic clipboard monitoring
- Full **GFM** support including *italic*, ~~strikethrough~~, and `inline code`
- Configurable detection sensitivity
- Lightweight: <1% CPU at 0.5s polling interval

## Architecture

| Component | Role |
|-----------|------|
| `MarkdownDetector` | 15 weighted regex patterns |
| `MarkdownConverter` | AST → HTML + RTF |
| `ClipboardMonitor` | Timer-based 10-step guard pipeline |
| `ClipboardWriter` | Multi-format pasteboard write |

## Code Example

```swift
let detector = MarkdownDetector()
let result = detector.detect(text: content, threshold: 2)
```

## Task List

- [x] Detection engine
- [x] Converter
- [x] Clipboard writer
- [ ] Performance profiling

> **Note**: The app is distributed as an unsigned DMG for v1.0.

See [GitHub](https://github.com/jonc102/markdown-copy-tool) for source.
"""

private let largeMarkdown: String = {
    // Builds ~50KB of realistic Markdown content
    let section = """

## Section

Paragraph with **bold**, *italic*, and `inline code`. Also a [link](https://example.com).

| Column A | Column B | Column C |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

```swift
func example() -> String {
    return "Hello, world!"
}
```

- [x] Task one
- [ ] Task two
- [ ] Task three

> Blockquote with some content that goes on for a while to pad the size.

---

"""
    return (0..<60).map { i in "# Heading \(i)\n" + section }.joined()
}()

// MARK: - Performance Tests

final class MarkdownPerformanceTests: XCTestCase {

    private let detector = MarkdownDetector()
    private let converter = MarkdownConverter()

    // MARK: Detector

    func testDetectorPerformanceTypical() {
        // Target: <5ms per call
        measure {
            _ = detector.score(text: typicalMarkdown)
        }
    }

    func testDetectorPerformanceLarge() {
        // Verifies the detector stays fast even near the 100KB guard boundary
        measure {
            _ = detector.score(text: largeMarkdown)
        }
    }

    // MARK: Converter

    func testConverterPerformanceTypical() {
        // Target: <100ms per call
        measure {
            _ = converter.convert(markdown: typicalMarkdown)
        }
    }

    func testConverterPerformanceLarge() {
        // Verifies conversion completes in reasonable time on large input
        measure {
            _ = converter.convert(markdown: largeMarkdown)
        }
    }

    // MARK: Size Guard

    func testLargeMarkdownSize() {
        // Confirm the large fixture is substantial but stays under the 100KB guard
        let bytes = largeMarkdown.utf8.count
        XCTAssertGreaterThan(bytes, 20_000, "Fixture should be at least 20KB for a meaningful test")
        XCTAssertLessThan(bytes, Constants.maxContentSize, "Fixture must stay under the 100KB guard")
    }
}
