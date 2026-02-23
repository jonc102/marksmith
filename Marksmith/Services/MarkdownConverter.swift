import Foundation
import Markdown
import AppKit

struct MarkdownConverter {

    func convert(markdown: String, fontSize: Int = 14) -> (html: String, rtf: Data?) {
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let bodyHTML = visitor.visit(document)
        let fullHTML = wrapInHTMLDocument(bodyHTML, fontSize: fontSize)
        let rtf = generateRTF(from: fullHTML)
        return (html: fullHTML, rtf: rtf)
    }

    // MARK: - HTML Document Wrapper

    private func wrapInHTMLDocument(_ body: String, fontSize: Int = 14) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head><style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; font-size: \(fontSize)px; line-height: 1.6; color: #333; }
        h1, h2, h3, h4, h5, h6 { margin-top: 1em; margin-bottom: 0.5em; font-weight: 600; }
        h1 { font-size: 1.8em; } h2 { font-size: 1.5em; } h3 { font-size: 1.3em; }
        code { background-color: #f0f0f0; padding: 2px 6px; border-radius: 3px; font-family: "SF Mono", Menlo, monospace; font-size: 0.9em; }
        pre { background-color: #f6f8fa; padding: 12px; border-radius: 6px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        blockquote { border-left: 4px solid #ddd; margin: 0; padding: 0 1em; color: #666; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
        th { background-color: #f6f8fa; font-weight: 600; }
        hr { border: none; border-top: 1px solid #ddd; margin: 1.5em 0; }
        a { color: #0366d6; text-decoration: none; }
        img { max-width: 100%; }
        del { color: #999; }
        ul, ol { padding-left: 2em; }
        </style></head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    // MARK: - RTF Generation

    private func generateRTF(from html: String) -> Data? {
        guard let htmlData = html.data(using: .utf8) else { return nil }
        guard let attrStr = NSAttributedString(
            html: htmlData,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) else { return nil }
        return try? attrStr.data(
            from: NSRange(location: 0, length: attrStr.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}

// MARK: - HTMLVisitor

private struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    // Track whether we are inside a table head to differentiate <th> vs <td>
    private var inTableHead = false
    // Track column alignments from the current table
    private var columnAlignments: [Table.ColumnAlignment?] = []
    private var currentColumnIndex = 0

    // MARK: - Default

    mutating func defaultVisit(_ markup: any Markup) -> String {
        var result = ""
        for child in markup.children {
            result += visit(child)
        }
        return result
    }

    // MARK: - Block Elements

    mutating func visitDocument(_ document: Document) -> String {
        return defaultVisit(document)
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        let level = heading.level
        let content = defaultVisit(heading)
        return "<h\(level)>\(content)</h\(level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        let content = defaultVisit(paragraph)
        return "<p>\(content)</p>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        let content = defaultVisit(blockQuote)
        return "<blockquote>\(content)</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let escaped = escapeHTML(codeBlock.code)
        if let language = codeBlock.language, !language.isEmpty {
            return "<pre><code class=\"language-\(escapeHTML(language))\">\(escaped)</code></pre>\n"
        }
        return "<pre><code>\(escaped)</code></pre>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        // <hr> is often stripped during HTML→RTF conversion. A border-top on a
        // near-invisible paragraph is more reliably preserved across rich-text apps.
        return "<p style=\"border-top: 1px solid #ddd; margin: 1em 0; padding: 0; font-size: 1px; line-height: 0;\">&nbsp;</p>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        return html.rawHTML
    }

    // MARK: - List Elements

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let content = defaultVisit(orderedList)
        return "<ol>\(content)</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        let content = defaultVisit(unorderedList)
        return "<ul>\(content)</ul>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        if let checkbox = listItem.checkbox {
            // Visit children inline, skipping the <p> wrapper on single-paragraph
            // items so the checkbox character and text appear on the same line.
            let content = listItem.children.map { child -> String in
                if let paragraph = child as? Paragraph {
                    return defaultVisit(paragraph)
                }
                return visit(child)
            }.joined()
            let marker = checkbox == .checked ? "&#x2611;" : "&#x2610;"
            return "<li style=\"list-style: none;\">\(marker) \(content)</li>\n"
        }
        let content = defaultVisit(listItem)
        return "<li>\(content)</li>\n"
    }

    // MARK: - Table Elements

    mutating func visitTable(_ table: Table) -> String {
        columnAlignments = table.columnAlignments
        let content = defaultVisit(table)
        columnAlignments = []
        return "<table>\(content)</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) -> String {
        inTableHead = true
        currentColumnIndex = 0
        let content = defaultVisit(tableHead)
        inTableHead = false
        return "<thead>\(content)</thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Table.Body) -> String {
        let content = defaultVisit(tableBody)
        return "<tbody>\(content)</tbody>\n"
    }

    mutating func visitTableRow(_ tableRow: Table.Row) -> String {
        currentColumnIndex = 0
        let content = defaultVisit(tableRow)
        return "<tr>\(content)</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) -> String {
        let content = defaultVisit(tableCell)
        let tag = inTableHead ? "th" : "td"

        var alignAttr = ""
        if currentColumnIndex < columnAlignments.count,
           let alignment = columnAlignments[currentColumnIndex] {
            switch alignment {
            case .left:
                alignAttr = " style=\"text-align: left;\""
            case .center:
                alignAttr = " style=\"text-align: center;\""
            case .right:
                alignAttr = " style=\"text-align: right;\""
            }
        }
        currentColumnIndex += 1

        return "<\(tag)\(alignAttr)>\(content)</\(tag)>"
    }

    // MARK: - Inline Elements

    mutating func visitText(_ text: Text) -> String {
        return escapeHTML(text.string)
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        let content = defaultVisit(strong)
        return "<strong>\(content)</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        let content = defaultVisit(emphasis)
        return "<em>\(content)</em>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        let content = defaultVisit(strikethrough)
        return "<del>\(content)</del>"
    }

    mutating func visitLink(_ link: Link) -> String {
        let content = defaultVisit(link)
        let href = link.destination ?? ""
        return "<a href=\"\(escapeHTML(href))\">\(content)</a>"
    }

    mutating func visitImage(_ image: Image) -> String {
        let alt = defaultVisit(image)
        let src = image.source ?? ""
        return "<img src=\"\(escapeHTML(src))\" alt=\"\(escapeHTML(alt))\">"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        return "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        return inlineHTML.rawHTML
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        return " "
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        return "<br>"
    }

    // MARK: - HTML Escaping

    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
