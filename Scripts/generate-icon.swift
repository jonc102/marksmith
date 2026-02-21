#!/usr/bin/swift
import AppKit
import Foundation

let canvasSize: CGFloat = 1024
let image = NSImage(size: NSSize(width: canvasSize, height: canvasSize))

image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("No context") }

// ── Background: dark blue-grey rounded rectangle ────────────────────────────
let cornerRadius: CGFloat = 220
let bgPath = CGPath(
    roundedRect: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize),
    cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil
)
ctx.addPath(bgPath)
ctx.clip()

// Gradient: dark navy top-left → dark slate bottom-right
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradColors = [
    CGColor(colorSpace: colorSpace, components: [0.20, 0.25, 0.38, 1.0])!,
    CGColor(colorSpace: colorSpace, components: [0.10, 0.13, 0.22, 1.0])!
]
let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient,
    start: CGPoint(x: 0, y: canvasSize),
    end: CGPoint(x: canvasSize, y: 0),
    options: [])

// ── Helper: draw a rounded rect ──────────────────────────────────────────────
func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

// ── White drawing helper ─────────────────────────────────────────────────────
func fill(_ path: CGPath) {
    ctx.addPath(path)
    ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 1])!)
    ctx.fillPath()
}

func fillAlpha(_ path: CGPath, alpha: CGFloat) {
    ctx.addPath(path)
    ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, alpha])!)
    ctx.fillPath()
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT: Clipboard
// ─────────────────────────────────────────────────────────────────────────────
let clipX: CGFloat = 90
let clipY: CGFloat = 240
let clipW: CGFloat = 330
let clipH: CGFloat = 400

// Clipboard body
fill(roundedRect(CGRect(x: clipX, y: clipY, width: clipW, height: clipH), radius: 28))

// Clip cutout (dark) for clip detail at top
let cutW: CGFloat = 130
let cutH: CGFloat = 50
let cutX = clipX + (clipW - cutW) / 2
let cutY = clipY + clipH - 36
let cutPath = roundedRect(CGRect(x: cutX, y: cutY, width: cutW, height: cutH), radius: 14)
ctx.addPath(cutPath)
ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [0.15, 0.19, 0.28, 1.0])!)
ctx.fillPath()

// Clipboard inner content area (dark)
let innerX = clipX + 28
let innerY = clipY + 32
let innerW = clipW - 56
let innerH = clipH - 80
ctx.addPath(roundedRect(CGRect(x: innerX, y: innerY, width: innerW, height: innerH), radius: 12))
ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [0.15, 0.19, 0.28, 1.0])!)
ctx.fillPath()

// # symbol  (two horizontal bars, two vertical bars)
let hashX: CGFloat = innerX + 18
let hashY: CGFloat = innerY + innerH - 105
let barH: CGFloat = 18
let barW: CGFloat = 90
let vBarW: CGFloat = 16
let vBarH: CGFloat = 90
// horizontal bars
fill(roundedRect(CGRect(x: hashX, y: hashY + 54, width: barW, height: barH), radius: 5))
fill(roundedRect(CGRect(x: hashX, y: hashY + 24, width: barW, height: barH), radius: 5))
// vertical bars
fill(roundedRect(CGRect(x: hashX + 20, y: hashY, width: vBarW, height: vBarH), radius: 5))
fill(roundedRect(CGRect(x: hashX + 54, y: hashY, width: vBarW, height: vBarH), radius: 5))

// * symbol (3 lines through center)
let starX: CGFloat = innerX + 22
let starY: CGFloat = innerY + 42
let armLen: CGFloat = 38
let armW: CGFloat = 14
let cx = starX + armLen
let cy = starY + armLen
// horizontal arm
fill(roundedRect(CGRect(x: cx - armLen, y: cy - armW/2, width: armLen*2, height: armW), radius: 6))
// 60° arm
for angle in [CGFloat.pi/3, CGFloat(2 * Double.pi / 3)] {
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: angle)
    fill(roundedRect(CGRect(x: -armLen, y: -armW/2, width: armLen*2, height: armW), radius: 6))
    ctx.restoreGState()
}

// lines (representing text rows)
let lineW: CGFloat = innerW - 36
let lineH2: CGFloat = 13
let lineR: CGFloat = 6
fill(roundedRect(CGRect(x: innerX + 18, y: innerY + 18, width: lineW, height: lineH2), radius: lineR))
fill(roundedRect(CGRect(x: innerX + 18, y: innerY + 18 + 26, width: lineW * 0.7, height: lineH2), radius: lineR))

// ─────────────────────────────────────────────────────────────────────────────
// CENTER: Arrow →
// ─────────────────────────────────────────────────────────────────────────────
let arrowCX: CGFloat = 512
let arrowCY: CGFloat = 450
let shaftW: CGFloat = 140
let shaftH: CGFloat = 38
let headSize: CGFloat = 90

// Shaft
fill(roundedRect(
    CGRect(x: arrowCX - shaftW/2 - headSize*0.3,
           y: arrowCY - shaftH/2,
           width: shaftW,
           height: shaftH),
    radius: shaftH/2
))

// Arrowhead (triangle)
let arrowPath = CGMutablePath()
let tipX = arrowCX + shaftW/2 + headSize * 0.55
arrowPath.move(to: CGPoint(x: tipX, y: arrowCY))
arrowPath.addLine(to: CGPoint(x: tipX - headSize, y: arrowCY + headSize * 0.6))
arrowPath.addLine(to: CGPoint(x: tipX - headSize, y: arrowCY - headSize * 0.6))
arrowPath.closeSubpath()
fill(arrowPath)

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT: Document with folded corner
// ─────────────────────────────────────────────────────────────────────────────
let docX: CGFloat = 600
let docY: CGFloat = 220
let docW: CGFloat = 310
let docH: CGFloat = 440
let fold: CGFloat = 70

// Document body (with top-right fold cutout)
let docPath = CGMutablePath()
docPath.move(to: CGPoint(x: docX, y: docY))
docPath.addLine(to: CGPoint(x: docX + docW - fold, y: docY))
docPath.addLine(to: CGPoint(x: docX + docW, y: docY + fold))
docPath.addLine(to: CGPoint(x: docX + docW, y: docY + docH))
docPath.addLine(to: CGPoint(x: docX, y: docY + docH))
docPath.closeSubpath()
fill(docPath)

// Fold triangle (dark)
let foldPath = CGMutablePath()
foldPath.move(to: CGPoint(x: docX + docW - fold, y: docY))
foldPath.addLine(to: CGPoint(x: docX + docW, y: docY + fold))
foldPath.addLine(to: CGPoint(x: docX + docW - fold, y: docY + fold))
foldPath.closeSubpath()
ctx.addPath(foldPath)
ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [0.15, 0.19, 0.28, 0.9])!)
ctx.fillPath()

// Inner content area (dark)
let dInnerX = docX + 24
let dInnerY = docY + 28
let dInnerW = docW - 54
let dInnerH = docH - 56
ctx.addPath(roundedRect(CGRect(x: dInnerX, y: dInnerY, width: dInnerW, height: dInnerH), radius: 10))
ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [0.15, 0.19, 0.28, 1.0])!)
ctx.fillPath()

// "A" — large heading letter
let aAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 108),
    .foregroundColor: NSColor.white
]
let aStr = NSAttributedString(string: "A", attributes: aAttrs)
aStr.draw(at: CGPoint(x: dInnerX + 14, y: dInnerY + dInnerH - 125))

// Heading text lines next to A
fill(roundedRect(CGRect(x: dInnerX + 110, y: dInnerY + dInnerH - 68, width: dInnerW - 120, height: 16), radius: 6))
fill(roundedRect(CGRect(x: dInnerX + 110, y: dInnerY + dInnerH - 98, width: (dInnerW - 120) * 0.7, height: 16), radius: 6))

// Divider line
fillAlpha(roundedRect(CGRect(x: dInnerX + 10, y: dInnerY + dInnerH - 145, width: dInnerW - 20, height: 3), radius: 2), alpha: 0.4)

// "T" — body text letter
let tAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.boldSystemFont(ofSize: 72),
    .foregroundColor: NSColor.white
]
let tStr = NSAttributedString(string: "T", attributes: tAttrs)
tStr.draw(at: CGPoint(x: dInnerX + 14, y: dInnerY + dInnerH - 230))

// Body text lines
let lineStartY = dInnerY + dInnerH - 195
for i in 0..<3 {
    let w = i == 2 ? (dInnerW - 100) * 0.6 : dInnerW - 100
    fill(roundedRect(CGRect(x: dInnerX + 90, y: lineStartY - CGFloat(i) * 28, width: w, height: 14), radius: 5))
}

// Body paragraph lines at bottom
for i in 0..<3 {
    let w = i == 2 ? (dInnerW - 20) * 0.65 : dInnerW - 20
    fill(roundedRect(CGRect(x: dInnerX + 10, y: dInnerY + 50 + CGFloat(i) * 28, width: w, height: 14), radius: 5))
}

image.unlockFocus()

// ── Save as PNG ───────────────────────────────────────────────────────────────
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/tmp/AppIcon-1024.png"

if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    try! png.write(to: URL(fileURLWithPath: outputPath))
    print("Saved to \(outputPath)")
} else {
    print("ERROR: Failed to render image")
    exit(1)
}
