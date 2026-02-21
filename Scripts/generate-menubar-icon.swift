#!/usr/bin/swift
import AppKit
import Foundation

let sizes: [(name: String, px: Int)] = [
    ("MenuBarIcon.png", 16),
    ("MenuBarIcon@2x.png", 32)
]

for (filename, px) in sizes {
    let s = CGFloat(px)

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    let nsCtx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = nsCtx
    let ctx = nsCtx.cgContext

    ctx.clear(CGRect(x: 0, y: 0, width: s, height: s))

    // Draw "M" large and "↓" smaller so M isn't cut off
    let mFont = NSFont.boldSystemFont(ofSize: s * 0.75)
    let arrowFont = NSFont.boldSystemFont(ofSize: s * 0.45)

    let mAttrs: [NSAttributedString.Key: Any] = [.font: mFont, .foregroundColor: NSColor.black]
    let arrowAttrs: [NSAttributedString.Key: Any] = [.font: arrowFont, .foregroundColor: NSColor.black]

    let mStr = NSAttributedString(string: "M", attributes: mAttrs)
    let arrowStr = NSAttributedString(string: "↓", attributes: arrowAttrs)

    let mSize = mStr.size()
    let arrowSize = arrowStr.size()
    let totalWidth = mSize.width + arrowSize.width - 1.0

    let startX = (s - totalWidth) / 2
    let mY = (s - mSize.height) / 2
    let arrowY = mY + mSize.height - arrowSize.height  // baseline-align bottom

    mStr.draw(at: NSPoint(x: startX, y: mY))
    arrowStr.draw(at: NSPoint(x: startX + mSize.width - 1.0, y: arrowY))

    NSGraphicsContext.restoreGraphicsState()

    let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp"
    if let png = rep.representation(using: .png, properties: [:]) {
        try! png.write(to: URL(fileURLWithPath: "\(outputDir)/\(filename)"))
        print("Saved \(filename) (\(px)x\(px))")
    }
}
