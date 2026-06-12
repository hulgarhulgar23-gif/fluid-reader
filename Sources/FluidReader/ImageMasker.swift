import AppKit
import UniformTypeIdentifiers

enum ImageMasker {
    static func maskedImage(from fullImage: CGImage, viewSize: CGSize, points: [CGPoint]) -> SelectionOverlayResult? {
        guard points.count > 2, viewSize.width > 0, viewSize.height > 0 else { return nil }

        let rawBounds = CGRect.bounding(points)
        guard rawBounds.width > 8, rawBounds.height > 8 else { return nil }

        let pointBounds = rawBounds
            .insetBy(dx: -8, dy: -8)
            .intersection(CGRect(origin: .zero, size: viewSize))

        guard pointBounds.width > 8, pointBounds.height > 8 else { return nil }

        let scaleX = CGFloat(fullImage.width) / viewSize.width
        let scaleY = CGFloat(fullImage.height) / viewSize.height
        let pixelRect = CGRect(
            x: floor(pointBounds.minX * scaleX),
            y: floor((viewSize.height - pointBounds.maxY) * scaleY),
            width: ceil(pointBounds.width * scaleX),
            height: ceil(pointBounds.height * scaleY)
        ).integral

        guard let croppedImage = fullImage.cropping(to: pixelRect) else { return nil }

        let width = croppedImage.width
        let height = croppedImage.height
        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.setFillColor(NSColor.white.cgColor)
        context.fill(drawRect)

        let clipPath = CGMutablePath()
        for (index, point) in points.enumerated() {
            let mapped = CGPoint(
                x: (point.x - pointBounds.minX) * scaleX,
                y: (point.y - pointBounds.minY) * scaleY
            )

            if index == 0 {
                clipPath.move(to: mapped)
            } else {
                clipPath.addLine(to: mapped)
            }
        }
        clipPath.closeSubpath()

        context.saveGState()
        context.addPath(clipPath)
        context.clip()
        context.draw(croppedImage, in: drawRect)
        context.restoreGState()

        guard let maskedImage = context.makeImage() else { return nil }
        let pngData = makePNGData(from: maskedImage)
        return SelectionOverlayResult(image: maskedImage, pngData: pngData)
    }

    static func annotatedScreenshot(
        from fullImage: CGImage,
        viewSize: CGSize,
        points: [CGPoint]
    ) -> SelectionOverlayResult? {
        guard points.count > 1, viewSize.width > 0, viewSize.height > 0 else { return nil }

        let width = fullImage.width
        let height = fullImage.height
        guard width > 0, height > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(fullImage, in: drawRect)

        let scaleX = CGFloat(width) / viewSize.width
        let scaleY = CGFloat(height) / viewSize.height
        let mappedPoints = points.map { point in
            CGPoint(x: point.x * scaleX, y: point.y * scaleY)
        }

        drawLine(mappedPoints, in: context, scale: max(scaleX, scaleY))

        guard let image = context.makeImage() else { return nil }
        let pngData = makePNGData(from: image)
        return SelectionOverlayResult(image: image, pngData: pngData)
    }

    private static func drawLine(_ points: [CGPoint], in context: CGContext, scale: CGFloat) {
        guard let first = points.first else { return }

        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.beginPath()
        context.move(to: first)
        points.dropFirst().forEach { context.addLine(to: $0) }
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.95).cgColor)
        context.setLineWidth(max(8, 8 * scale))
        context.strokePath()

        context.beginPath()
        context.move(to: first)
        points.dropFirst().forEach { context.addLine(to: $0) }
        context.setStrokeColor(NSColor.systemPink.cgColor)
        context.setLineWidth(max(4, 4 * scale))
        context.strokePath()
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

private extension CGRect {
    static func bounding(_ points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .zero }

        var minX = first.x
        var minY = first.y
        var maxX = first.x
        var maxY = first.y

        for point in points.dropFirst() {
            minX = Swift.min(minX, point.x)
            minY = Swift.min(minY, point.y)
            maxX = Swift.max(maxX, point.x)
            maxY = Swift.max(maxY, point.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
