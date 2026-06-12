import AppKit

@MainActor
enum WindowBounds {
    static func clampedSize(
        _ size: NSSize,
        minimum: NSSize,
        maximum: NSSize
    ) -> NSSize {
        let width = size.width.isFinite ? size.width : maximum.width
        let height = size.height.isFinite ? size.height : maximum.height
        return NSSize(
            width: max(minimum.width, min(maximum.width, width)),
            height: max(minimum.height, min(maximum.height, height))
        )
    }

    static func apply(
        to window: NSWindow,
        preferredContentSize: NSSize,
        minContentSize: NSSize,
        maxContentSize: NSSize
    ) {
        let safeMax = screenSafeMaxSize(maxContentSize)
        let safeMin = clampedSize(minContentSize, minimum: NSSize(width: 120, height: 80), maximum: safeMax)
        let safePreferred = clampedSize(preferredContentSize, minimum: safeMin, maximum: safeMax)

        window.contentMinSize = safeMin
        window.contentMaxSize = safeMax
        window.minSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: safeMin)).size
        window.maxSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: safeMax)).size

        let contentSize = window.contentLayoutRect.size
        let badWidth = !contentSize.width.isFinite || contentSize.width < safeMin.width || contentSize.width > safeMax.width
        let badHeight = !contentSize.height.isFinite || contentSize.height < safeMin.height || contentSize.height > safeMax.height
        if badWidth || badHeight {
            window.setContentSize(safePreferred)
        }

        clampOrigin(toVisibleScreen: window)
    }

    static func reset(
        _ window: NSWindow,
        preferredContentSize: NSSize,
        minContentSize: NSSize,
        maxContentSize: NSSize
    ) {
        apply(
            to: window,
            preferredContentSize: preferredContentSize,
            minContentSize: minContentSize,
            maxContentSize: maxContentSize
        )
        let safePreferred = clampedSize(
            preferredContentSize,
            minimum: window.contentMinSize,
            maximum: window.contentMaxSize
        )
        window.setContentSize(safePreferred)
        clampOrigin(toVisibleScreen: window)
    }

    static func clampOrigin(toVisibleScreen window: NSWindow, padding: CGFloat = 20) {
        guard let visible = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return }
        var frame = window.frame

        if frame.width > visible.width - padding * 2 || frame.height > visible.height - padding * 2 {
            let maxContent = screenSafeMaxSize(window.contentMaxSize, padding: padding)
            window.setContentSize(maxContent)
            frame = window.frame
        }

        let minX = visible.minX + padding
        let maxX = visible.maxX - padding - frame.width
        let minY = visible.minY + padding
        let maxY = visible.maxY - padding - frame.height
        let x = min(max(frame.origin.x, minX), max(minX, maxX))
        let y = min(max(frame.origin.y, minY), max(minY, maxY))
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private static func screenSafeMaxSize(
        _ requested: NSSize,
        padding: CGFloat = 24
    ) -> NSSize {
        guard let visible = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else {
            return requested
        }
        return NSSize(
            width: max(120, min(requested.width, visible.width - padding * 2)),
            height: max(80, min(requested.height, visible.height - padding * 2))
        )
    }
}
