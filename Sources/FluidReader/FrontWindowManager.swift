import AppKit
import ApplicationServices

enum FrontWindowLayoutCommand: String, CaseIterable {
    case leftHalf
    case rightHalf
    case topLeftQuarter
    case topRightQuarter
    case bottomLeftQuarter
    case bottomRightQuarter
    case leftThird
    case centerThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds
    case topHalf
    case bottomHalf
    case maximize
    case center
    case cycleLayout
    case cycleLayoutBackward
    case undoLastMove
    case moveToNextDisplay
    case moveToPreviousDisplay

    var activityDetail: String {
        switch self {
        case .leftHalf:
            return "left-half"
        case .rightHalf:
            return "right-half"
        case .topLeftQuarter:
            return "top-left-quarter"
        case .topRightQuarter:
            return "top-right-quarter"
        case .bottomLeftQuarter:
            return "bottom-left-quarter"
        case .bottomRightQuarter:
            return "bottom-right-quarter"
        case .leftThird:
            return "left-third"
        case .centerThird:
            return "center-third"
        case .rightThird:
            return "right-third"
        case .leftTwoThirds:
            return "left-two-thirds"
        case .rightTwoThirds:
            return "right-two-thirds"
        case .topHalf:
            return "top-half"
        case .bottomHalf:
            return "bottom-half"
        case .maximize:
            return "maximize"
        case .center:
            return "center"
        case .cycleLayout:
            return "cycle-layout"
        case .cycleLayoutBackward:
            return "cycle-layout-backward"
        case .undoLastMove:
            return "undo-last-move"
        case .moveToNextDisplay:
            return "next-display"
        case .moveToPreviousDisplay:
            return "previous-display"
        }
    }
}

enum FrontWindowMoveResult: Equatable {
    case moved
    case accessibilityNotAllowed
    case noTargetApplication
    case noWindow
    case noScreen
    case noUndoMove
    case noOtherScreen
    case failed
}

enum FrontWindowCycleProfile: String, CaseIterable {
    case full
    case focus

    var activityDetail: String {
        switch self {
        case .full:
            return "cycle-profile-full"
        case .focus:
            return "cycle-profile-focus"
        }
    }

    var title: String {
        switch self {
        case .full:
            return "Full"
        case .focus:
            return "Focus"
        }
    }

    var commands: [FrontWindowLayoutCommand] {
        switch self {
        case .full:
            return WindowLayout.defaultCycleCommands
        case .focus:
            return [.leftHalf, .center, .rightHalf, .maximize]
        }
    }
}

struct FrontWindowUndoStore {
    private var framesByProcessID: [pid_t: CGRect] = [:]

    mutating func remember(_ frame: CGRect, for processID: pid_t) {
        framesByProcessID[processID] = frame.integral
    }

    func hasFrame(for processID: pid_t) -> Bool {
        framesByProcessID[processID] != nil
    }

    mutating func swapCurrentFrame(_ frame: CGRect, for processID: pid_t) -> CGRect? {
        let previous = framesByProcessID[processID]
        framesByProcessID[processID] = frame.integral
        return previous
    }
}

enum WindowLayout {
    static let defaultCycleCommands: [FrontWindowLayoutCommand] = [
        .leftHalf,
        .rightHalf,
        .topHalf,
        .bottomHalf,
        .topLeftQuarter,
        .topRightQuarter,
        .bottomLeftQuarter,
        .bottomRightQuarter,
        .leftThird,
        .centerThird,
        .rightThird,
        .leftTwoThirds,
        .rightTwoThirds,
        .maximize,
        .center
    ]

    static func targetFrame(
        command: FrontWindowLayoutCommand,
        screenFrame: CGRect,
        currentFrame: CGRect?
    ) -> CGRect {
        let halfWidth = floor(screenFrame.width / 2)
        let rightWidth = screenFrame.width - halfWidth
        let thirdWidth = floor(screenFrame.width / 3)
        let rightThirdWidth = screenFrame.width - (thirdWidth * 2)
        let twoThirdsWidth = screenFrame.width - thirdWidth
        let halfHeight = floor(screenFrame.height / 2)
        let bottomHeight = screenFrame.height - halfHeight

        switch command {
        case .leftHalf:
            return CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: halfWidth,
                height: screenFrame.height
            )
        case .rightHalf:
            return CGRect(
                x: screenFrame.minX + halfWidth,
                y: screenFrame.minY,
                width: rightWidth,
                height: screenFrame.height
            )
        case .topLeftQuarter:
            return CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: halfWidth,
                height: halfHeight
            )
        case .topRightQuarter:
            return CGRect(
                x: screenFrame.minX + halfWidth,
                y: screenFrame.minY,
                width: rightWidth,
                height: halfHeight
            )
        case .bottomLeftQuarter:
            return CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY + halfHeight,
                width: halfWidth,
                height: bottomHeight
            )
        case .bottomRightQuarter:
            return CGRect(
                x: screenFrame.minX + halfWidth,
                y: screenFrame.minY + halfHeight,
                width: rightWidth,
                height: bottomHeight
            )
        case .leftThird:
            return CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: thirdWidth,
                height: screenFrame.height
            )
        case .centerThird:
            return CGRect(
                x: screenFrame.minX + thirdWidth,
                y: screenFrame.minY,
                width: thirdWidth,
                height: screenFrame.height
            )
        case .rightThird:
            return CGRect(
                x: screenFrame.minX + thirdWidth * 2,
                y: screenFrame.minY,
                width: rightThirdWidth,
                height: screenFrame.height
            )
        case .leftTwoThirds:
            return CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: twoThirdsWidth,
                height: screenFrame.height
            )
        case .rightTwoThirds:
            return CGRect(
                x: screenFrame.minX + thirdWidth,
                y: screenFrame.minY,
                width: twoThirdsWidth,
                height: screenFrame.height
            )
        case .topHalf:
            return CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: halfHeight
            )
        case .bottomHalf:
            return CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY + halfHeight,
                width: screenFrame.width,
                height: bottomHeight
            )
        case .maximize:
            return screenFrame
        case .center:
            let size = centeredSize(currentFrame: currentFrame, screenFrame: screenFrame)
            return CGRect(
                x: screenFrame.midX - size.width / 2,
                y: screenFrame.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
        case .cycleLayout:
            return targetFrameForCycle(currentFrame: currentFrame, screenFrame: screenFrame)
        case .cycleLayoutBackward:
            return targetFrameForCycle(currentFrame: currentFrame, screenFrame: screenFrame, reverse: true)
        case .undoLastMove:
            return currentFrame ?? screenFrame
        case .moveToNextDisplay:
            return currentFrame ?? screenFrame
        case .moveToPreviousDisplay:
            return currentFrame ?? screenFrame
        }
    }

    static func targetFrameForCycle(
        currentFrame: CGRect?,
        screenFrame: CGRect,
        reverse: Bool = false,
        cycleCommands: [FrontWindowLayoutCommand]? = nil
    ) -> CGRect {
        let cycleCommands = normalizedCycleCommands(cycleCommands)
        guard let firstCommand = cycleCommands.first else { return screenFrame }
        guard let currentFrame else {
            return targetFrame(command: firstCommand, screenFrame: screenFrame, currentFrame: nil)
        }

        let normalizedCurrentFrame = currentFrame.integral
        if let currentIndex = cycleCommands.firstIndex(where: { command in
            let commandFrame = targetFrame(
                command: command,
                screenFrame: screenFrame,
                currentFrame: currentFrame
            ).integral
            return isSameLayoutFrame(commandFrame, normalizedCurrentFrame)
        }) {
            let nextIndex = reverse
                ? (currentIndex - 1 + cycleCommands.count) % cycleCommands.count
                : (currentIndex + 1) % cycleCommands.count
            let nextCommand = cycleCommands[nextIndex]
            return targetFrame(command: nextCommand, screenFrame: screenFrame, currentFrame: currentFrame)
        }

        return targetFrame(command: firstCommand, screenFrame: screenFrame, currentFrame: currentFrame)
    }

    private static func normalizedCycleCommands(_ cycleCommands: [FrontWindowLayoutCommand]?) -> [FrontWindowLayoutCommand] {
        let sourceCommands = cycleCommands ?? defaultCycleCommands
        var uniqueCommands: [FrontWindowLayoutCommand] = []
        for command in sourceCommands where defaultCycleCommands.contains(command) {
            if !uniqueCommands.contains(command) {
                uniqueCommands.append(command)
            }
        }

        return uniqueCommands.isEmpty ? defaultCycleCommands : uniqueCommands
    }

    static func targetFrameForNextDisplay(currentFrame: CGRect, screenFrames: [CGRect]) -> CGRect? {
        targetFrameForDisplayShift(currentFrame: currentFrame, screenFrames: screenFrames, offset: 1)
    }

    static func targetFrameForPreviousDisplay(currentFrame: CGRect, screenFrames: [CGRect]) -> CGRect? {
        targetFrameForDisplayShift(currentFrame: currentFrame, screenFrames: screenFrames, offset: -1)
    }

    private static func targetFrameForDisplayShift(
        currentFrame: CGRect,
        screenFrames: [CGRect],
        offset: Int
    ) -> CGRect? {
        guard screenFrames.count > 1 else { return nil }
        guard let currentScreen = bestScreenFrame(for: currentFrame, screenFrames: screenFrames),
              let currentScreenIndex = screenFrames.firstIndex(of: currentScreen) else {
            return nil
        }

        let targetIndex = (currentScreenIndex + offset + screenFrames.count) % screenFrames.count
        let targetScreen = screenFrames[targetIndex]
        return remapWindowFrame(currentFrame, from: currentScreen, to: targetScreen)
    }

    static func bestScreenFrame(for windowFrame: CGRect, screenFrames: [CGRect]) -> CGRect? {
        guard let first = screenFrames.first else { return nil }
        let windowCenter = CGPoint(x: windowFrame.midX, y: windowFrame.midY)

        if let containingScreen = screenFrames.first(where: { $0.contains(windowCenter) }) {
            return containingScreen
        }

        return screenFrames.min {
            distanceSquared(from: windowCenter, to: $0.center) < distanceSquared(from: windowCenter, to: $1.center)
        } ?? first
    }

    private static func centeredSize(currentFrame: CGRect?, screenFrame: CGRect) -> CGSize {
        let fallback = CGSize(width: floor(screenFrame.width * 0.72), height: floor(screenFrame.height * 0.72))
        let currentSize = currentFrame?.size ?? fallback
        return CGSize(
            width: min(max(currentSize.width, 320), floor(screenFrame.width * 0.92)),
            height: min(max(currentSize.height, 240), floor(screenFrame.height * 0.92))
        )
    }

    private static func remapWindowFrame(_ frame: CGRect, from sourceScreen: CGRect, to targetScreen: CGRect) -> CGRect {
        let width = min(frame.width, targetScreen.width)
        let height = min(frame.height, targetScreen.height)

        let sourceWidth = max(sourceScreen.width, 1)
        let sourceHeight = max(sourceScreen.height, 1)
        let relativeCenterX = (frame.midX - sourceScreen.minX) / sourceWidth
        let relativeCenterY = (frame.midY - sourceScreen.minY) / sourceHeight

        let targetCenterX = targetScreen.minX + (relativeCenterX * targetScreen.width)
        let targetCenterY = targetScreen.minY + (relativeCenterY * targetScreen.height)

        let x = clamp(targetCenterX - width / 2, min: targetScreen.minX, max: targetScreen.maxX - width)
        let y = clamp(targetCenterY - height / 2, min: targetScreen.minY, max: targetScreen.maxY - height)

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func clamp(_ value: CGFloat, min lowerBound: CGFloat, max upperBound: CGFloat) -> CGFloat {
        guard lowerBound <= upperBound else { return lowerBound }
        return min(max(value, lowerBound), upperBound)
    }

    private static func distanceSquared(from point: CGPoint, to otherPoint: CGPoint) -> CGFloat {
        let dx = point.x - otherPoint.x
        let dy = point.y - otherPoint.y
        return dx * dx + dy * dy
    }

    private static func isSameLayoutFrame(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.origin.x - rhs.origin.x) <= 2 &&
            abs(lhs.origin.y - rhs.origin.y) <= 2 &&
            abs(lhs.size.width - rhs.size.width) <= 2 &&
            abs(lhs.size.height - rhs.size.height) <= 2
    }
}

extension CGRect {
    fileprivate var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

enum FrontWindowManager {
    @MainActor
    private static var undoStore = FrontWindowUndoStore()
    private static let cycleProfileKey = "front-window-cycle-profile"

    static func cycleProfile(defaults: UserDefaults = .standard) -> FrontWindowCycleProfile {
        guard let rawValue = defaults.string(forKey: cycleProfileKey),
              let profile = FrontWindowCycleProfile(rawValue: rawValue) else {
            return .full
        }
        return profile
    }

    static func setCycleProfile(_ profile: FrontWindowCycleProfile, defaults: UserDefaults = .standard) {
        if profile == .full {
            defaults.removeObject(forKey: cycleProfileKey)
            return
        }
        defaults.set(profile.rawValue, forKey: cycleProfileKey)
    }

    @MainActor
    static func hasUndoMove(for application: NSRunningApplication?) -> Bool {
        guard let application, !application.isTerminated else { return false }
        return undoStore.hasFrame(for: application.processIdentifier)
    }

    @MainActor
    static func move(
        _ command: FrontWindowLayoutCommand,
        application: NSRunningApplication?,
        accessibilityTrusted: () -> Bool = PermissionStatus.accessibilityTrusted
    ) -> FrontWindowMoveResult {
        guard accessibilityTrusted() else { return .accessibilityNotAllowed }
        guard let application, !application.isTerminated else { return .noTargetApplication }
        guard let window = focusedWindow(for: application) else { return .noWindow }
        guard let currentFrame = windowFrame(window) else { return .noWindow }
        let screenFrames = accessibilityScreenFrames()
        guard !screenFrames.isEmpty else { return .noScreen }
        let processID = application.processIdentifier
        let normalizedCurrentFrame = currentFrame.integral

        let targetFrame: CGRect
        switch command {
        case .undoLastMove:
            guard let previousFrame = undoStore.swapCurrentFrame(currentFrame, for: processID) else {
                return .noUndoMove
            }
            targetFrame = previousFrame.integral
        case .cycleLayout, .cycleLayoutBackward:
            guard let screenFrame = WindowLayout.bestScreenFrame(for: currentFrame, screenFrames: screenFrames) else {
                return .noScreen
            }
            targetFrame = WindowLayout.targetFrameForCycle(
                currentFrame: currentFrame,
                screenFrame: screenFrame,
                reverse: command == .cycleLayoutBackward,
                cycleCommands: cycleProfile().commands
            ).integral
        case .moveToNextDisplay, .moveToPreviousDisplay:
            guard screenFrames.count > 1 else { return .noOtherScreen }
            let remappedFrame: CGRect?
            switch command {
            case .moveToNextDisplay:
                remappedFrame = WindowLayout.targetFrameForNextDisplay(
                    currentFrame: currentFrame,
                    screenFrames: screenFrames
                )
            case .moveToPreviousDisplay:
                remappedFrame = WindowLayout.targetFrameForPreviousDisplay(
                    currentFrame: currentFrame,
                    screenFrames: screenFrames
                )
            default:
                remappedFrame = nil
            }
            guard let remappedFrame else {
                return .noScreen
            }
            targetFrame = remappedFrame.integral
        default:
            guard let screenFrame = WindowLayout.bestScreenFrame(for: currentFrame, screenFrames: screenFrames) else {
                return .noScreen
            }
            targetFrame = WindowLayout.targetFrame(
                command: command,
                screenFrame: screenFrame,
                currentFrame: currentFrame
            ).integral
        }

        guard setFrame(targetFrame, for: window) else {
            if command == .undoLastMove {
                _ = undoStore.swapCurrentFrame(targetFrame, for: processID)
            }
            return .failed
        }

        if command != .undoLastMove, targetFrame != normalizedCurrentFrame {
            undoStore.remember(normalizedCurrentFrame, for: processID)
        }
        return .moved
    }

    @MainActor
    private static func accessibilityScreenFrames() -> [CGRect] {
        NSScreen.screens.map { convertToAccessibilityFrame($0.visibleFrame) }
    }

    private static func focusedWindow(for application: NSRunningApplication) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        var focusedValue: CFTypeRef?

        if AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedValue
        ) == .success,
           let window = accessibilityElement(from: focusedValue) {
            return window
        }

        var windowsValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsValue
        ) == .success,
              let windows = windowsValue as? [AXUIElement] else {
            return nil
        }
        return windows.first
    }

    private static func windowFrame(_ window: AXUIElement) -> CGRect? {
        guard let position = pointAttribute(kAXPositionAttribute, from: window),
              let size = sizeAttribute(kAXSizeAttribute, from: window) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    private static func setFrame(_ frame: CGRect, for window: AXUIElement) -> Bool {
        var origin = frame.origin
        var size = frame.size
        guard let positionValue = AXValueCreate(.cgPoint, &origin),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return false
        }

        let positionResult = AXUIElementSetAttributeValue(
            window,
            kAXPositionAttribute as CFString,
            positionValue
        )
        let sizeResult = AXUIElementSetAttributeValue(
            window,
            kAXSizeAttribute as CFString,
            sizeValue
        )
        return positionResult == .success && sizeResult == .success
    }

    private static func pointAttribute(_ attribute: String, from element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        guard let axValue = accessibilityValue(from: value, expectedType: .cgPoint) else {
            return nil
        }

        var point = CGPoint.zero
        return AXValueGetValue(axValue, .cgPoint, &point) ? point : nil
    }

    private static func sizeAttribute(_ attribute: String, from element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        guard let axValue = accessibilityValue(from: value, expectedType: .cgSize) else {
            return nil
        }

        var size = CGSize.zero
        return AXValueGetValue(axValue, .cgSize, &size) ? size : nil
    }

    static func accessibilityElement(from value: CFTypeRef?) -> AXUIElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    static func accessibilityValue(from value: CFTypeRef?, expectedType: AXValueType) -> AXValue? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }
        let axValue = unsafeBitCast(value, to: AXValue.self)
        guard AXValueGetType(axValue) == expectedType else {
            return nil
        }
        return axValue
    }

    @MainActor
    private static func convertToAccessibilityFrame(_ frame: CGRect) -> CGRect {
        let mainHeight = NSScreen.screens.first?.frame.height ?? frame.height
        return CGRect(
            x: frame.minX,
            y: mainHeight - frame.maxY,
            width: frame.width,
            height: frame.height
        )
    }
}
