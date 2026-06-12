import AppKit
import UniformTypeIdentifiers

enum WinCardRenderer {
    static func pngData(savedItemCount: Int, activityLogItemCount: Int) -> Data? {
        let width = 1200
        let height = 630
        let safeSaved = max(0, savedItemCount)
        let safeEvents = max(0, activityLogItemCount)
        let total = max(1, safeSaved + safeEvents)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let canvas = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(NSColor(calibratedRed: 0.07, green: 0.10, blue: 0.16, alpha: 1).cgColor)
        context.fill(canvas)

        let panel = CGRect(x: 80, y: 110, width: 1040, height: 410)
        context.setFillColor(NSColor(calibratedRed: 0.14, green: 0.20, blue: 0.30, alpha: 0.92).cgColor)
        context.addPath(CGPath(roundedRect: panel, cornerWidth: 28, cornerHeight: 28, transform: nil))
        context.fillPath()

        let trackWidth = panel.width - 120
        let savedFillWidth = (CGFloat(safeSaved) / CGFloat(total)) * trackWidth
        let eventsFillWidth = (CGFloat(safeEvents) / CGFloat(total)) * trackWidth

        let savedTrack = CGRect(x: panel.minX + 60, y: panel.maxY - 170, width: trackWidth, height: 54)
        let eventsTrack = CGRect(x: panel.minX + 60, y: panel.maxY - 272, width: trackWidth, height: 54)

        context.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.12).cgColor)
        context.addPath(CGPath(roundedRect: savedTrack, cornerWidth: 16, cornerHeight: 16, transform: nil))
        context.fillPath()
        context.addPath(CGPath(roundedRect: eventsTrack, cornerWidth: 16, cornerHeight: 16, transform: nil))
        context.fillPath()

        let savedFill = CGRect(x: savedTrack.minX, y: savedTrack.minY, width: max(18, savedFillWidth), height: savedTrack.height)
        let eventsFill = CGRect(x: eventsTrack.minX, y: eventsTrack.minY, width: max(18, eventsFillWidth), height: eventsTrack.height)

        context.setFillColor(NSColor(calibratedRed: 0.30, green: 0.84, blue: 1.0, alpha: 0.98).cgColor)
        context.addPath(CGPath(roundedRect: savedFill, cornerWidth: 16, cornerHeight: 16, transform: nil))
        context.fillPath()

        context.setFillColor(NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.72, alpha: 0.98).cgColor)
        context.addPath(CGPath(roundedRect: eventsFill, cornerWidth: 16, cornerHeight: 16, transform: nil))
        context.fillPath()

        let pulseCount = min(8, (safeSaved % 8) + 1)
        for index in 0..<pulseCount {
            let dot = CGRect(x: panel.minX + 64 + CGFloat(index) * 28, y: panel.minY + 54, width: 16, height: 16)
            context.setFillColor(NSColor(calibratedRed: 0.38, green: 0.90, blue: 1.0, alpha: 0.90).cgColor)
            context.fillEllipse(in: dot)
        }

        let sparkCount = min(8, (safeEvents % 8) + 1)
        for index in 0..<sparkCount {
            let dot = CGRect(x: panel.minX + 64 + CGFloat(index) * 28, y: panel.minY + 26, width: 12, height: 12)
            context.setFillColor(NSColor(calibratedRed: 1.0, green: 0.54, blue: 0.78, alpha: 0.90).cgColor)
            context.fillEllipse(in: dot)
        }

        guard let image = context.makeImage() else { return nil }
        return makePNGData(from: image)
    }

    private static func makePNGData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
