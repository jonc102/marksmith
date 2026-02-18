import XCTest
@testable import MarkdownPaste

final class MarkdownDetectorTests: XCTestCase {

    private let detector = MarkdownDetector()

    // MARK: - Positive Cases (should detect as Markdown)

    func testDetectsHeadings() {
        XCTAssertTrue(detector.detect(text: "# Heading 1", threshold: 2))
        XCTAssertTrue(detector.detect(text: "## Heading 2", threshold: 2))
        XCTAssertTrue(detector.detect(text: "###### Heading 6", threshold: 2))
    }

    func testDetectsBold() {
        XCTAssertTrue(detector.detect(text: "This is **bold** text and **more bold**", threshold: 2))
    }

    func testDetectsItalic() {
        XCTAssertTrue(detector.detect(text: "This has *italic* and **bold** text", threshold: 2))
    }

    func testDetectsLinks() {
        XCTAssertTrue(detector.detect(text: "Click [here](https://example.com) for more", threshold: 2))
    }

    func testDetectsImages() {
        XCTAssertTrue(detector.detect(text: "![Alt text](image.png)", threshold: 2))
    }

    func testDetectsUnorderedList() {
        let text = """
        - Item 1
        - Item 2
        - Item 3
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    func testDetectsOrderedList() {
        let text = """
        1. First
        2. Second
        3. Third
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    func testDetectsCodeBlocks() {
        let text = """
        ```swift
        let x = 42
        ```
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    func testDetectsInlineCode() {
        XCTAssertTrue(detector.detect(text: "Use `print()` and `return` keywords", threshold: 2))
    }

    func testDetectsBlockquotes() {
        let text = """
        > This is a quote
        > With multiple lines
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    func testDetectsTables() {
        let text = """
        | Name | Age |
        |------|-----|
        | Alice | 30 |
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    func testDetectsTaskLists() {
        let text = """
        - [x] Done
        - [ ] Not done
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    func testDetectsStrikethrough() {
        XCTAssertTrue(detector.detect(text: "This is ~~deleted~~ and ~~removed~~ text", threshold: 2))
    }

    func testDetectsHorizontalRules() {
        XCTAssertTrue(detector.detect(text: "Above\n---\nBelow\n---", threshold: 2))
    }

    func testDetectsFootnotes() {
        XCTAssertTrue(detector.detect(text: "Text [^1] and [^2] references", threshold: 2))
    }

    func testDetectsFullGFMDocument() {
        let text = """
        # My Document

        This has **bold** and *italic* text.

        ## Section 2

        - Item 1
        - Item 2

        ```python
        print("hello")
        ```

        [Link](https://example.com)
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
        XCTAssertTrue(detector.score(text: text) > 10)
    }

    func testDetectsMixedPatterns() {
        let text = """
        ## Title

        Some **bold** and a [link](url).
        """
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    // MARK: - Negative Cases (should NOT detect as Markdown)

    func testRejectsPlainEnglish() {
        XCTAssertFalse(detector.detect(text: "This is just a plain English sentence with nothing special.", threshold: 2))
    }

    func testRejectsSingleLineText() {
        XCTAssertFalse(detector.detect(text: "Hello world", threshold: 2))
    }

    func testRejectsCodeWithoutBackticks() {
        XCTAssertFalse(detector.detect(text: "function foo() { return 42; }", threshold: 2))
    }

    func testRejectsURLsWithoutBrackets() {
        XCTAssertFalse(detector.detect(text: "Visit https://example.com for more info.", threshold: 2))
    }

    func testRejectsNumbersWithPeriods() {
        XCTAssertFalse(detector.detect(text: "The price is 42.99 dollars.", threshold: 2))
    }

    func testRejectsEmailAddresses() {
        XCTAssertFalse(detector.detect(text: "Send mail to user@example.com please.", threshold: 2))
    }

    // MARK: - Edge Cases

    func testEmptyString() {
        XCTAssertFalse(detector.detect(text: "", threshold: 2))
        XCTAssertEqual(detector.score(text: ""), 0)
    }

    func testWhitespaceOnly() {
        XCTAssertFalse(detector.detect(text: "   \n\t  \n  ", threshold: 2))
    }

    func testSingleAsterisk() {
        XCTAssertFalse(detector.detect(text: "I rate this 5*", threshold: 2))
    }

    func testThresholdBoundary() {
        // A single heading "# Heading" matches heading pattern once: score = 1 * 3 = 3
        XCTAssertTrue(detector.detect(text: "# Heading", threshold: 3))
        // threshold of 4 should fail since score is 3
        XCTAssertFalse(detector.detect(text: "# Heading", threshold: 4))
    }

    func testScoreCapping() {
        // Many headings should be capped at weight(3) * 3 matches = 9 for the headings pattern
        let text = """
        # H1
        # H2
        # H3
        # H4
        # H5
        """
        let score = detector.score(text: text)
        // Headings pattern: 5 matches, capped at 3 -> 3 * 3 = 9
        // Unordered list pattern might also match for lines starting with list-like chars, but # is not -, *, +
        // Score should be exactly 9 from headings alone
        XCTAssertTrue(score <= 50, "Score should be reasonable due to capping")
        XCTAssertEqual(score, 9, "5 headings capped at 3 matches * weight 3 = 9")
    }

    func testScoreConsistency() {
        let text = "# Heading\n**bold**"
        let score = detector.score(text: text)
        // Heading: 1 match * 3 = 3, Bold: 1 match * 2 = 2, total = 5
        XCTAssertEqual(score, 5)
        XCTAssertTrue(detector.detect(text: text, threshold: 5))
        XCTAssertFalse(detector.detect(text: text, threshold: 6))
    }

    func testDetectReturnsTrueWhenScoreEqualsThreshold() {
        // detect returns score >= threshold, so equal should be true
        let text = "**bold**" // score = 1 * 2 = 2
        XCTAssertEqual(detector.score(text: text), 2)
        XCTAssertTrue(detector.detect(text: text, threshold: 2))
    }

    func testZeroThresholdAlwaysDetects() {
        // Any non-empty text with at least one match should pass threshold 0
        XCTAssertTrue(detector.detect(text: "**bold**", threshold: 0))
        // Even no matches: score 0 >= 0 is true
        XCTAssertTrue(detector.detect(text: "plain text", threshold: 0))
    }
}
