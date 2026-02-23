import XCTest
@testable import Marksmith

final class ClipboardWriterTests: XCTestCase {

    private let writer = ClipboardWriter()
    private let pasteboard = NSPasteboard.general

    override func setUp() {
        super.setUp()
        pasteboard.clearContents()
    }

    // MARK: - Basic Writing

    func testWritesPlainText() {
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: nil)

        let text = pasteboard.string(forType: .string)
        XCTAssertEqual(text, "Hello")
    }

    func testWritesHTML() {
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: nil)

        let html = pasteboard.string(forType: .html)
        XCTAssertEqual(html, "<p>Hello</p>")
    }

    func testWritesRTFWhenProvided() {
        let rtfString = "{\\rtf1 Hello}"
        let rtfData = rtfString.data(using: .utf8)!

        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: rtfData)

        let data = pasteboard.data(forType: .rtf)
        XCTAssertNotNil(data, "RTF data should be written to pasteboard")
    }

    func testOmitsRTFWhenNil() {
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: nil)

        let data = pasteboard.data(forType: .rtf)
        XCTAssertNil(data, "RTF data should not be on pasteboard when not provided")
    }

    // MARK: - Marker

    func testMarkerIsAlwaysPresent() {
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: nil)

        let marker = pasteboard.string(forType: .markdownPasteMarker)
        XCTAssertNotNil(marker, "Marker type should always be present")
    }

    func testMarkerIsPresentWithRTF() {
        let rtfData = "{\\rtf1 Hello}".data(using: .utf8)!
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: rtfData)

        let marker = pasteboard.string(forType: .markdownPasteMarker)
        XCTAssertNotNil(marker, "Marker should be present even with RTF")
    }

    func testMarkerValue() {
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: nil)

        let marker = pasteboard.string(forType: .markdownPasteMarker)
        XCTAssertEqual(marker, "1", "Marker value should be '1'")
    }

    // MARK: - All Types Written

    func testAllPasteboardTypesWritten() {
        let rtfData = "{\\rtf1 Hello}".data(using: .utf8)!
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: rtfData)

        let types = pasteboard.types ?? []
        XCTAssertTrue(types.contains(.string), "Should contain .string type")
        XCTAssertTrue(types.contains(.html), "Should contain .html type")
        XCTAssertTrue(types.contains(.rtf), "Should contain .rtf type")
        XCTAssertTrue(types.contains(.markdownPasteMarker), "Should contain marker type")
    }

    func testTypesWithoutRTF() {
        writer.write(plainText: "Hello", html: "<p>Hello</p>", rtf: nil)

        let types = pasteboard.types ?? []
        XCTAssertTrue(types.contains(.string), "Should contain .string type")
        XCTAssertTrue(types.contains(.html), "Should contain .html type")
        XCTAssertFalse(types.contains(.rtf), "Should NOT contain .rtf type when nil")
        XCTAssertTrue(types.contains(.markdownPasteMarker), "Should contain marker type")
    }

    func testClearsExistingContent() {
        // Write something first
        pasteboard.clearContents()
        pasteboard.setString("old content", forType: .string)

        // Now write with our writer
        writer.write(plainText: "new", html: "<p>new</p>", rtf: nil)

        let text = pasteboard.string(forType: .string)
        XCTAssertEqual(text, "new", "Old content should be cleared")
    }

    // MARK: - Content Integrity

    func testPreservesHTMLContent() {
        let complexHTML = """
        <!DOCTYPE html><html><body><h1>Title</h1><p>Text with <strong>bold</strong></p></body></html>
        """
        writer.write(plainText: "Title\nText with bold", html: complexHTML, rtf: nil)

        let html = pasteboard.string(forType: .html)
        XCTAssertEqual(html, complexHTML)
    }

    func testPreservesPlainTextWithNewlines() {
        let text = "Line 1\nLine 2\nLine 3"
        writer.write(plainText: text, html: "<p>Line 1</p>", rtf: nil)

        let result = pasteboard.string(forType: .string)
        XCTAssertEqual(result, text)
    }
}
