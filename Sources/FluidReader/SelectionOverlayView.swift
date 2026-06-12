import AppKit

enum SelectionCaptureMode {
    case lasso
    case screenshotLine
}

struct SelectionOverlayResult {
    let image: CGImage
    let pngData: Data?
}

final class SelectionOverlayView: NSView {
    private let screenImage: CGImage
    private let mode: SelectionCaptureMode
    private let onDrawStart: () -> Void
    private let onCommit: () -> Void
    private let onFinish: (SelectionOverlayResult) -> Void
    private let onCancel: () -> Void
    private var points: [CGPoint] = []
    private var isDrawing = false
    private var pointer: CGPoint?
    private let startTime = CACurrentMediaTime()
    private var animationTimer: Timer?
    private var cachedOpenPath: NSBezierPath?
    private var cachedClosedPath: NSBezierPath?
    private var cachedPathPointCount = 0

    init(
        screenImage: CGImage,
        mode: SelectionCaptureMode = .lasso,
        onDrawStart: @escaping () -> Void,
        onCommit: @escaping () -> Void,
        onFinish: @escaping (SelectionOverlayResult) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.screenImage = screenImage
        self.mode = mode
        self.onDrawStart = onDrawStart
        self.onCommit = onCommit
        self.onFinish = onFinish
        self.onCancel = onCancel
        super.init(frame: .zero)
        wantsLayer = true
        startAnimationTimer()
    }

    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        animationTimer?.invalidate()
    }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel()
        } else {
            super.keyDown(with: event)
        }
    }

    override func mouseDown(with event: NSEvent) {
        isDrawing = true
        points = [convert(event.locationInWindow, from: nil)]
        invalidateCachedPaths()
        onDrawStart()
        needsDisplay = true
    }

    override func mouseMoved(with event: NSEvent) {
        pointer = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDrawing else { return }
        let point = convert(event.locationInWindow, from: nil)
        pointer = point
        if point.distance(to: points.last ?? point) > 2 {
            points.append(point)
            invalidateCachedPaths()
            needsDisplay = true
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard isDrawing else { return }
        isDrawing = false

        let point = convert(event.locationInWindow, from: nil)
        points.append(point)
        invalidateCachedPaths()
        onCommit()

        let result: SelectionOverlayResult?
        switch mode {
        case .lasso:
            result = points.count > 4
                ? ImageMasker.maskedImage(
                    from: screenImage,
                    viewSize: bounds.size,
                    points: points
                )
                : nil
        case .screenshotLine:
            result = points.count > 2
                ? ImageMasker.annotatedScreenshot(
                    from: screenImage,
                    viewSize: bounds.size,
                    points: points
                )
                : nil
        }

        guard let result else {
            onCancel()
            return
        }

        onFinish(result)
    }

    override func draw(_ dirtyRect: NSRect) {
        let elapsed = CACurrentMediaTime() - startTime
        let intro = min(1.0, elapsed / 0.14)
        let pulse = (sin(elapsed * 9.0) + 1.0) / 2.0

        NSColor.black.withAlphaComponent(0.16 * intro).setFill()
        dirtyRect.fill()

        if let pointer, !isDrawing {
            drawPointer(at: pointer, pulse: pulse)
        }

        guard points.count > 1 else { return }
        if mode == .screenshotLine {
            drawScreenshotLine(elapsed: elapsed, pulse: pulse)
            return
        }

        let paths = currentPaths()
        let fillPath = paths.closed
        NSColor(calibratedRed: 0.28, green: 0.75, blue: 1.0, alpha: 0.12).setFill()
        fillPath.fill()

        let path = paths.open

        let glow = NSShadow()
        glow.shadowBlurRadius = 12 + pulse * 5
        glow.shadowColor = NSColor(calibratedRed: 0.10, green: 0.80, blue: 1.0, alpha: 0.42)
        glow.set()

        NSColor(calibratedRed: 0.20, green: 0.77, blue: 1.0, alpha: 0.60).setStroke()
        path.lineWidth = 8
        path.stroke()

        NSShadow().set()
        NSColor.white.withAlphaComponent(0.94).setStroke()
        path.lineWidth = 2.2
        path.stroke()

        drawGlints(elapsed: elapsed, pulse: pulse)

        if let last = points.last {
            drawPointer(at: last, pulse: pulse)
        }
    }

    private func drawScreenshotLine(elapsed: Double, pulse: Double) {
        let path = currentPaths().open

        let glow = NSShadow()
        glow.shadowBlurRadius = 10 + pulse * 4
        glow.shadowColor = NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.68, alpha: 0.48)
        glow.set()

        NSColor(calibratedRed: 1.0, green: 0.22, blue: 0.48, alpha: 0.78).setStroke()
        path.lineWidth = 7
        path.stroke()

        NSShadow().set()
        NSColor.white.withAlphaComponent(0.90).setStroke()
        path.lineWidth = 2
        path.stroke()

        drawGlints(elapsed: elapsed, pulse: pulse)

        if let last = points.last {
            drawPointer(at: last, pulse: pulse)
        }
    }

    private func drawGlints(elapsed: Double, pulse: Double) {
        guard points.count > 8 else { return }

        let count = points.count
        let lead = Int((elapsed * 30.0).truncatingRemainder(dividingBy: Double(count)))

        for step in 0..<3 {
            let index = (lead + step * max(1, count / 6)) % count
            let point = points[index]
            let size = CGFloat(7 - step * 2) + CGFloat(pulse) * 1.2
            let rect = CGRect(
                x: point.x - size / 2,
                y: point.y - size / 2,
                width: size,
                height: size
            )

            let glow = NSShadow()
            glow.shadowBlurRadius = 9
            glow.shadowColor = NSColor(calibratedRed: 0.20, green: 0.90, blue: 1.0, alpha: 0.48)
            glow.set()

            let dot = NSBezierPath(ovalIn: rect)
            NSColor.white.withAlphaComponent(0.90 - CGFloat(step) * 0.16).setFill()
            dot.fill()
        }

        NSShadow().set()
    }

    private func drawPointer(at point: CGPoint, pulse: Double) {
        let size = 24 + CGFloat(pulse) * 5
        let rect = CGRect(
            x: point.x - size / 2,
            y: point.y - size / 2,
            width: size,
            height: size
        )
        let ring = NSBezierPath(ovalIn: rect)
        NSColor.white.withAlphaComponent(0.88).setStroke()
        ring.lineWidth = 1.5
        ring.stroke()

        let dotSize: CGFloat = 5
        let dot = NSBezierPath(ovalIn: CGRect(
            x: point.x - dotSize / 2,
            y: point.y - dotSize / 2,
            width: dotSize,
            height: dotSize
        ))
        NSColor(calibratedRed: 0.35, green: 0.85, blue: 1.0, alpha: 0.90).setFill()
        dot.fill()
    }

    private func startAnimationTimer() {
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self, self.shouldAnimate else { return }
            self.needsDisplay = true
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    private var shouldAnimate: Bool {
        CACurrentMediaTime() - startTime < 0.18 || pointer != nil || points.count > 1
    }

    private func invalidateCachedPaths() {
        cachedOpenPath = nil
        cachedClosedPath = nil
        cachedPathPointCount = 0
    }

    private func currentPaths() -> (open: NSBezierPath, closed: NSBezierPath) {
        if let open = cachedOpenPath,
           let closed = cachedClosedPath,
           cachedPathPointCount == points.count {
            return (open, closed)
        }

        let open = NSBezierPath(points: points, closed: false)
        open.lineCapStyle = .round
        open.lineJoinStyle = .round

        let closed = NSBezierPath(points: points, closed: true)
        closed.lineCapStyle = .round
        closed.lineJoinStyle = .round

        cachedOpenPath = open
        cachedClosedPath = closed
        cachedPathPointCount = points.count
        return (open, closed)
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

private extension NSBezierPath {
    convenience init(points: [CGPoint], closed: Bool) {
        self.init()
        guard let first = points.first else { return }
        move(to: first)

        guard points.count > 2 else {
            for point in points.dropFirst() {
                line(to: point)
            }
            if closed {
                close()
            }
            return
        }

        for index in 1..<(points.count - 1) {
            let point = points[index]
            let next = points[index + 1]
            let mid = CGPoint(x: (point.x + next.x) / 2, y: (point.y + next.y) / 2)
            curve(to: mid, controlPoint1: point, controlPoint2: point)
        }

        if let last = points.last {
            line(to: last)
        }

        if closed {
            close()
        }
    }
}
