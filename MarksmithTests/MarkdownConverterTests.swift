import XCTest
@testable import Marksmith

final class MarkdownConverterTests: XCTestCase {

    private let converter = MarkdownConverter()

    // MARK: - Headings

    func testHeadingsProduceCorrectTags() {
        for level in 1...6 {
            let hashes = String(repeating: "#", count: level)
            let result = converter.convert(markdown: "\(hashes) Heading \(level)")
            XCTAssertTrue(result.html.contains("<h\(level)>"), "Expected <h\(level)> tag")
            XCTAssertTrue(result.html.contains("</h\(level)>"), "Expected </h\(level)> closing tag")
        }
    }

    // MARK: - Inline Formatting

    func testBoldProducesStrong() {
        let result = converter.convert(markdown: "**bold text**")
        XCTAssertTrue(result.html.contains("<strong>bold text</strong>"))
    }

    func testItalicProducesEm() {
        let result = converter.convert(markdown: "*italic text*")
        XCTAssertTrue(result.html.contains("<em>italic text</em>"))
    }

    func testStrikethroughProducesDel() {
        let result = converter.convert(markdown: "~~deleted~~")
        XCTAssertTrue(result.html.contains("<del>deleted</del>"))
    }

    // MARK: - Links and Images

    func testLinksProduceAnchorTags() {
        let result = converter.convert(markdown: "[Example](https://example.com)")
        XCTAssertTrue(result.html.contains("<a href=\"https://example.com\">Example</a>"))
    }

    func testImagesProduceImgTags() {
        let result = converter.convert(markdown: "![Alt](image.png)")
        XCTAssertTrue(result.html.contains("<img src=\"image.png\""))
        XCTAssertTrue(result.html.contains("alt=\"Alt\""))
    }

    // MARK: - Code

    func testInlineCodeProducesCodeTag() {
        let result = converter.convert(markdown: "Use `print()`")
        XCTAssertTrue(result.html.contains("<code>print()</code>"))
    }

    func testCodeBlockProducesPreCodeTags() {
        let result = converter.convert(markdown: "```swift\nlet x = 42\n```")
        XCTAssertTrue(result.html.contains("<pre><code"))
        XCTAssertTrue(result.html.contains("language-swift"))
    }

    func testCodeBlockWithoutLanguage() {
        let result = converter.convert(markdown: "```\nsome code\n```")
        XCTAssertTrue(result.html.contains("<pre><code>"))
    }

    // MARK: - Lists

    func testUnorderedListProducesUlLi() {
        let result = converter.convert(markdown: "- Item 1\n- Item 2")
        XCTAssertTrue(result.html.contains("<ul>"))
        XCTAssertTrue(result.html.contains("<li>"))
    }

    func testOrderedListProducesOlLi() {
        let result = converter.convert(markdown: "1. First\n2. Second")
        XCTAssertTrue(result.html.contains("<ol>"))
        XCTAssertTrue(result.html.contains("<li>"))
    }

    func testTaskListProducesCheckboxes() {
        let result = converter.convert(markdown: "- [x] Done\n- [ ] Not done")
        // Unicode ballot boxes: ☑ (checked) and ☐ (unchecked)
        XCTAssertTrue(result.html.contains("&#x2611;"))
        XCTAssertTrue(result.html.contains("&#x2610;"))
    }

    // MARK: - Block Elements

    func testBlockquoteProducesBlockquoteTag() {
        let result = converter.convert(markdown: "> A quote")
        XCTAssertTrue(result.html.contains("<blockquote>"))
    }

    func testHorizontalRuleProducesHrTag() {
        let result = converter.convert(markdown: "---")
        // Rendered as a border-top paragraph for RTF compatibility
        XCTAssertTrue(result.html.contains("border-top"))
    }

    // MARK: - Tables

    func testTableProducesFullStructure() {
        let markdown = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """
        let result = converter.convert(markdown: markdown)
        XCTAssertTrue(result.html.contains("<table>"))
        XCTAssertTrue(result.html.contains("<thead>"))
        XCTAssertTrue(result.html.contains("<tbody>"))
        XCTAssertTrue(result.html.contains("<tr>"))
        XCTAssertTrue(result.html.contains("<th>"))
        XCTAssertTrue(result.html.contains("<td>"))
    }

    // MARK: - RTF Generation

    func testRTFDataIsNonNilForValidMarkdown() {
        let result = converter.convert(markdown: "# Hello\n\nSome **bold** text.")
        XCTAssertNotNil(result.rtf, "RTF data should be non-nil for valid markdown")
    }

    func testRTFDataIsNonNilForSimpleText() {
        let result = converter.convert(markdown: "Just plain text")
        XCTAssertNotNil(result.rtf)
    }

    // MARK: - HTML Escaping

    func testHTMLEntitiesAreEscaped() {
        // Use ampersand and angle brackets in a context where swift-markdown
        // parses them as Text nodes (not InlineHTML). Ampersand in regular text
        // and angle brackets inside inline code are escaped by our visitor.
        let result = converter.convert(markdown: "Tom & Jerry")
        XCTAssertTrue(result.html.contains("&amp;"), "Ampersand should be escaped")

        // Angle brackets inside code are escaped via escapeHTML in visitCodeBlock
        let codeResult = converter.convert(markdown: "`<div>`")
        XCTAssertTrue(codeResult.html.contains("&lt;div&gt;"), "Angle brackets in inline code should be escaped")
    }

    func testQuotesAreEscapedInAttributes() {
        // Quotes in link URLs are escaped by escapeHTML
        let result = converter.convert(markdown: "[link](https://example.com/a\"b)")
        XCTAssertTrue(result.html.contains("&quot;"), "Quotes in href should be escaped")
    }

    // MARK: - CSS Wrapper

    func testHTMLContainsCSSStyles() {
        let result = converter.convert(markdown: "# Test")
        XCTAssertTrue(result.html.contains("<style>"))
        XCTAssertTrue(result.html.contains("font-family"))
        XCTAssertTrue(result.html.contains("border-collapse"))
    }

    func testHTMLIsFullDocument() {
        let result = converter.convert(markdown: "# Test")
        XCTAssertTrue(result.html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(result.html.contains("<html>"))
        XCTAssertTrue(result.html.contains("</html>"))
    }

    func testHTMLContainsBodyTags() {
        let result = converter.convert(markdown: "# Test")
        XCTAssertTrue(result.html.contains("<body>"))
        XCTAssertTrue(result.html.contains("</body>"))
    }

    // MARK: - Complex Documents

    func testFullGFMDocument() {
        let markdown = """
        # Title

        Paragraph with **bold**, *italic*, and `code`.

        ## Links

        [Example](https://example.com)

        ## List

        - Item 1
        - Item 2

        > A blockquote

        ```python
        print("hello")
        ```

        | Col 1 | Col 2 |
        |-------|-------|
        | A     | B     |
        """
        let result = converter.convert(markdown: markdown)
        XCTAssertTrue(result.html.contains("<h1>"))
        XCTAssertTrue(result.html.contains("<strong>"))
        XCTAssertTrue(result.html.contains("<em>"))
        XCTAssertTrue(result.html.contains("<code>"))
        XCTAssertTrue(result.html.contains("<a href"))
        XCTAssertTrue(result.html.contains("<ul>"))
        XCTAssertTrue(result.html.contains("<blockquote>"))
        XCTAssertTrue(result.html.contains("<pre>"))
        XCTAssertTrue(result.html.contains("<table>"))
        XCTAssertNotNil(result.rtf)
    }

    // MARK: - Specific Element Content

    func testHeadingContent() {
        let result = converter.convert(markdown: "# My Title")
        XCTAssertTrue(result.html.contains("<h1>My Title</h1>"))
    }

    func testNestedFormatting() {
        let result = converter.convert(markdown: "**bold and *italic***")
        XCTAssertTrue(result.html.contains("<strong>"))
        XCTAssertTrue(result.html.contains("<em>"))
    }

    func testCodeBlockEscapesContent() {
        let result = converter.convert(markdown: "```\n<script>alert('xss')</script>\n```")
        XCTAssertTrue(result.html.contains("&lt;script&gt;"))
        XCTAssertFalse(result.html.contains("<script>alert"))
    }

    func testLineBreak() {
        // Two trailing spaces followed by newline create a hard line break
        let result = converter.convert(markdown: "Line one  \nLine two")
        XCTAssertTrue(result.html.contains("<br>"))
    }
}
