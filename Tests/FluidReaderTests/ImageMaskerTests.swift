import AppKit
import XCTest
@testable import FluidReader

final class ImageMaskerTests: XCTestCase {
    func testMaskedImageUsesViewToPixelScale() throws {
        let image = try makeImage(width: 200, height: 200)
        let points = [
            CGPoint(x: 30, y: 30),
            CGPoint(x: 45, y: 30),
            CGPoint(x: 45, y: 45),
            CGPoint(x: 30, y: 45),
            CGPoint(x: 30, y: 30)
        ]

        let result = try XCTUnwrap(ImageMasker.maskedImage(
            from: image,
            viewSize: CGSize(width: 100, height: 100),
            points: points
        ))

        XCTAssertEqual(result.image.width, 62)
        XCTAssertEqual(result.image.height, 62)
        XCTAssertNotNil(result.pngData)
    }

    func testMaskedImageRejectsTinyPick() throws {
        let image = try makeImage(width: 50, height: 50)
        let points = [
            CGPoint(x: 1, y: 1),
            CGPoint(x: 2, y: 1),
            CGPoint(x: 2, y: 2)
        ]

        let result = ImageMasker.maskedImage(
            from: image,
            viewSize: CGSize(width: 50, height: 50),
            points: points
        )

        XCTAssertNil(result)
    }

    func testAnnotatedScreenshotKeepsFullImageSize() throws {
        let image = try makeImage(width: 120, height: 80)
        let result = try XCTUnwrap(ImageMasker.annotatedScreenshot(
            from: image,
            viewSize: CGSize(width: 60, height: 40),
            points: [
                CGPoint(x: 10, y: 10),
                CGPoint(x: 30, y: 20),
                CGPoint(x: 50, y: 30)
            ]
        ))

        XCTAssertEqual(result.image.width, 120)
        XCTAssertEqual(result.image.height, 80)
        XCTAssertNotNil(result.pngData)
    }

    private func makeImage(width: Int, height: Int) throws -> CGImage {
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
            throw TestImageError.couldNotMakeImage
        }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        guard let image = context.makeImage() else {
            throw TestImageError.couldNotMakeImage
        }

        return image
    }
}

private enum TestImageError: Error {
    case couldNotMakeImage
}
