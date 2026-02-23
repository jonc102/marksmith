import AppKit

struct ClipboardWriter {

    private let pasteboard = NSPasteboard.general

    func write(plainText: String, html: String, rtf: Data?) {
        pasteboard.clearContents()

        let item = NSPasteboardItem()
        item.setString(plainText, forType: .string)
        item.setString(html, forType: .html)

        if let rtfData = rtf {
            item.setData(rtfData, forType: .rtf)
        }

        // Always set marker to prevent re-processing our own writes
        item.setString("1", forType: .markdownPasteMarker)

        pasteboard.writeObjects([item])
    }
}
