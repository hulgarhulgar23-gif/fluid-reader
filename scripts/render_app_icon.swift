// Renders the Fluid Reader app icon as a 1024x1024 PNG.
// Run via scripts/generate_app_icon.sh, not directly.
import AppKit
import CoreGraphics
import Foundation

let canvas: CGFloat = 1024

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: render_app_icon <output.png>\n".utf8))
    exit(1)
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
guard let context = CGContext(
    data: nil,
    width: Int(canvas),
    height: Int(canvas),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    FileHandle.standardError.write(Data("could not create bitmap context\n".utf8))
    exit(1)
}

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r / 255, g / 255, b / 255, a])!
}

// Background squircle following the macOS Big Sur icon grid:
// content occupies ~824pt of the 1024pt canvas.
let inset: CGFloat = 100
let plate = CGRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)
let plateRadius: CGFloat = 185

let platePath = CGPath(roundedRect: plate, cornerWidth: plateRadius, cornerHeight: plateRadius, transform: nil)

// Soft drop shadow.
context.saveGState()
context.setShadow(
    offset: CGSize(width: 0, height: -12),
    blur: 36,
    color: rgba(10, 16, 36, 0.35)
)
context.addPath(platePath)
context.setFillColor(rgba(20, 36, 90))
context.fillPath()
context.restoreGState()

// Vertical gradient: deep indigo to bright cyan-teal.
context.saveGState()
context.addPath(platePath)
context.clip()
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        rgba(37, 56, 141),
        rgba(28, 110, 196),
        rgba(38, 178, 204)
    ] as CFArray,
    locations: [0.0, 0.55, 1.0]
)!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: canvas / 2, y: plate.maxY),
    end: CGPoint(x: canvas / 2, y: plate.minY),
    options: []
)

// Subtle top sheen.
let sheen = CGGradient(
    colorsSpace: colorSpace,
    colors: [rgba(255, 255, 255, 0.18), rgba(255, 255, 255, 0.0)] as CFArray,
    locations: [0.0, 1.0]
)!
context.drawLinearGradient(
    sheen,
    start: CGPoint(x: canvas / 2, y: plate.maxY),
    end: CGPoint(x: canvas / 2, y: plate.maxY - plate.height * 0.45),
    options: []
)
context.restoreGState()

// Glyph: three text lines; the middle one is wrapped in a rounded
// selection marquee, echoing "draw around any screen content to read it".
func fillRoundedBar(_ rect: CGRect, radius: CGFloat, color: CGColor) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.addPath(path)
    context.setFillColor(color)
    context.fillPath()
}

let barHeight: CGFloat = 64
let barRadius: CGFloat = 32
let lineGap: CGFloat = 132
let glyphLeft: CGFloat = 268
let glyphRight: CGFloat = canvas - 268
let middleY = canvas / 2 - barHeight / 2

let white = rgba(255, 255, 255, 0.96)
let faded = rgba(255, 255, 255, 0.72)

// Top line.
fillRoundedBar(
    CGRect(x: glyphLeft, y: middleY + lineGap, width: glyphRight - glyphLeft, height: barHeight),
    radius: barRadius,
    color: faded
)
// Bottom line (shorter).
fillRoundedBar(
    CGRect(x: glyphLeft, y: middleY - lineGap, width: (glyphRight - glyphLeft) * 0.62, height: barHeight),
    radius: barRadius,
    color: faded
)
// Middle line (highlighted).
fillRoundedBar(
    CGRect(x: glyphLeft, y: middleY, width: glyphRight - glyphLeft, height: barHeight),
    radius: barRadius,
    color: white
)

// Selection marquee around the middle line, in warm amber.
let marquee = CGRect(
    x: glyphLeft - 56,
    y: middleY - 44,
    width: glyphRight - glyphLeft + 112,
    height: barHeight + 88
)
let marqueePath = CGPath(roundedRect: marquee, cornerWidth: 56, cornerHeight: 56, transform: nil)
context.addPath(marqueePath)
context.setStrokeColor(rgba(255, 196, 87))
context.setLineWidth(26)
context.strokePath()

guard let image = context.makeImage() else {
    FileHandle.standardError.write(Data("could not render image\n".utf8))
    exit(1)
}
let rep = NSBitmapImageRep(cgImage: image)
guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("could not encode png\n".utf8))
    exit(1)
}
try png.write(to: outputURL)
