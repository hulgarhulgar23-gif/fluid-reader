import AppKit
import ApplicationServices

enum FrontWindowLayoutCommand: String, CaseIterable, Identifiable {
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

    var id: String { rawValue }

    static let cycleEligibleCommands: [FrontWindowLayoutCommand] = [
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

    var actionID: String {
        switch self {
        case .cycleLayoutBackward:
            return "window-previous-layout"
        default:
            return "window-\(activityDetail)"
        }
    }

    var title: String {
        switch self {
        case .leftHalf:
            return "Window Left Half"
        case .rightHalf:
            return "Window Right Half"
        case .topLeftQuarter:
            return "Window Top Left Quarter"
        case .topRightQuarter:
            return "Window Top Right Quarter"
        case .bottomLeftQuarter:
            return "Window Bottom Left Quarter"
        case .bottomRightQuarter:
            return "Window Bottom Right Quarter"
        case .leftThird:
            return "Window Left Third"
        case .centerThird:
            return "Window Center Third"
        case .rightThird:
            return "Window Right Third"
        case .leftTwoThirds:
            return "Window Left Two Thirds"
        case .rightTwoThirds:
            return "Window Right Two Thirds"
        case .topHalf:
            return "Window Top Half"
        case .bottomHalf:
            return "Window Bottom Half"
        case .maximize:
            return "Window Maximize"
        case .center:
            return "Window Center"
        case .cycleLayout:
            return "Window Cycle Layout"
        case .cycleLayoutBackward:
            return "Window Previous Layout"
        case .undoLastMove:
            return "Window Undo Last Move"
        case .moveToNextDisplay:
            return "Window Next Display"
        case .moveToPreviousDisplay:
            return "Window Previous Display"
        }
    }

    var shortTitle: String {
        switch self {
        case .leftHalf:
            return "Left Half"
        case .rightHalf:
            return "Right Half"
        case .topLeftQuarter:
            return "Top Left Quarter"
        case .topRightQuarter:
            return "Top Right Quarter"
        case .bottomLeftQuarter:
            return "Bottom Left Quarter"
        case .bottomRightQuarter:
            return "Bottom Right Quarter"
        case .leftThird:
            return "Left Third"
        case .centerThird:
            return "Center Third"
        case .rightThird:
            return "Right Third"
        case .leftTwoThirds:
            return "Left Two Thirds"
        case .rightTwoThirds:
            return "Right Two Thirds"
        case .topHalf:
            return "Top Half"
        case .bottomHalf:
            return "Bottom Half"
        case .maximize:
            return "Maximize"
        case .center:
            return "Center"
        case .cycleLayout:
            return "Cycle Layout"
        case .cycleLayoutBackward:
            return "Previous Layout"
        case .undoLastMove:
            return "Undo Last Move"
        case .moveToNextDisplay:
            return "Next Display"
        case .moveToPreviousDisplay:
            return "Previous Display"
        }
    }

    var subtitle: String {
        switch self {
        case .leftHalf:
            return "Move front window to the left half"
        case .rightHalf:
            return "Move front window to the right half"
        case .topLeftQuarter:
            return "Move front window to the top-left quarter"
        case .topRightQuarter:
            return "Move front window to the top-right quarter"
        case .bottomLeftQuarter:
            return "Move front window to the bottom-left quarter"
        case .bottomRightQuarter:
            return "Move front window to the bottom-right quarter"
        case .leftThird:
            return "Move front window to the left third"
        case .centerThird:
            return "Move front window to the center third"
        case .rightThird:
            return "Move front window to the right third"
        case .leftTwoThirds:
            return "Move front window to the left two thirds"
        case .rightTwoThirds:
            return "Move front window to the right two thirds"
        case .topHalf:
            return "Move front window to the top half"
        case .bottomHalf:
            return "Move front window to the bottom half"
        case .maximize:
            return "Maximize the front window"
        case .center:
            return "Center the front window without changing the app"
        case .cycleLayout:
            return "Move front window to the next layout preset"
        case .cycleLayoutBackward:
            return "Move front window to the previous layout preset"
        case .undoLastMove:
            return "Restore the front window to its previous frame"
        case .moveToNextDisplay:
            return "Move front window to the next display"
        case .moveToPreviousDisplay:
            return "Move front window to the previous display"
        }
    }

    var systemImage: String {
        switch self {
        case .leftHalf:
            return "rectangle.lefthalf.filled"
        case .rightHalf:
            return "rectangle.righthalf.filled"
        case .topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter:
            return "rectangle.split.2x2"
        case .leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds:
            return "rectangle.split.3x1"
        case .topHalf, .bottomHalf:
            return "rectangle.split.1x2"
        case .maximize:
            return "macwindow.on.rectangle"
        case .center:
            return "rectangle.center.inset.filled"
        case .cycleLayout, .cycleLayoutBackward:
            return "arrow.triangle.2.circlepath.rectangle"
        case .undoLastMove:
            return "arrow.uturn.backward"
        case .moveToNextDisplay, .moveToPreviousDisplay:
            return "display.2"
        }
    }

    var keywords: [String] {
        switch self {
        case .leftHalf:
            return ["split", "tile", "snap", "left", "half"]
        case .rightHalf:
            return ["split", "tile", "snap", "right", "half"]
        case .topLeftQuarter:
            return ["quarter", "corner", "top-left", "tile"]
        case .topRightQuarter:
            return ["quarter", "corner", "top-right", "tile"]
        case .bottomLeftQuarter:
            return ["quarter", "corner", "bottom-left", "tile"]
        case .bottomRightQuarter:
            return ["quarter", "corner", "bottom-right", "tile"]
        case .leftThird:
            return ["third", "left", "tile"]
        case .centerThird:
            return ["middle", "center", "third", "tile"]
        case .rightThird:
            return ["third", "right", "tile"]
        case .leftTwoThirds:
            return ["two-thirds", "2/3", "wide", "left", "tile"]
        case .rightTwoThirds:
            return ["two-thirds", "2/3", "wide", "right", "tile"]
        case .topHalf:
            return ["top", "half", "tile"]
        case .bottomHalf:
            return ["bottom", "half", "tile"]
        case .maximize:
            return ["fullscreen", "fill", "maximize", "zoom"]
        case .center:
            return ["center", "middle", "focus"]
        case .cycleLayout:
            return ["cycle", "rotate", "next-layout", "layout-loop"]
        case .cycleLayoutBackward:
            return ["reverse", "back", "previous-layout"]
        case .undoLastMove:
            return ["undo", "restore", "revert", "last-position"]
        case .moveToNextDisplay:
            return ["monitor", "screen", "display", "next"]
        case .moveToPreviousDisplay:
            return ["monitor", "screen", "display", "previous"]
        }
    }

    var successMessage: String {
        switch self {
        case .leftHalf:
            return "Moved window left."
        case .rightHalf:
            return "Moved window right."
        case .topLeftQuarter:
            return "Moved window to the top-left quarter."
        case .topRightQuarter:
            return "Moved window to the top-right quarter."
        case .bottomLeftQuarter:
            return "Moved window to the bottom-left quarter."
        case .bottomRightQuarter:
            return "Moved window to the bottom-right quarter."
        case .leftThird:
            return "Moved window to the left third."
        case .centerThird:
            return "Moved window to the center third."
        case .rightThird:
            return "Moved window to the right third."
        case .leftTwoThirds:
            return "Moved window to the left two thirds."
        case .rightTwoThirds:
            return "Moved window to the right two thirds."
        case .topHalf:
            return "Moved window to the top half."
        case .bottomHalf:
            return "Moved window to the bottom half."
        case .maximize:
            return "Maximized window."
        case .center:
            return "Centered window."
        case .cycleLayout:
            return "Switched to the next window layout."
        case .cycleLayoutBackward:
            return "Switched to the previous window layout."
        case .undoLastMove:
            return "Restored the last window move."
        case .moveToNextDisplay:
            return "Moved window to the next display."
        case .moveToPreviousDisplay:
            return "Moved window to the previous display."
        }
    }

    static func normalizedCycleCommands(_ commands: [FrontWindowLayoutCommand]) -> [FrontWindowLayoutCommand] {
        var uniqueCommands: [FrontWindowLayoutCommand] = []
        for command in commands where cycleEligibleCommands.contains(command) {
            if !uniqueCommands.contains(command) {
                uniqueCommands.append(command)
            }
        }
        return uniqueCommands
    }

    static func cycleCommands(fromRawValues rawValues: [String], fallback: [FrontWindowLayoutCommand]) -> [FrontWindowLayoutCommand] {
        let resolvedCommands = rawValues.compactMap(Self.init(rawValue:))
        let normalizedCommands = normalizedCycleCommands(resolvedCommands)
        return normalizedCommands.isEmpty ? fallback : normalizedCommands
    }

    static func cycleCommandRawValues(_ commands: [FrontWindowLayoutCommand]) -> [String] {
        normalizedCycleCommands(commands).map(\.rawValue)
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

enum FrontWindowCycleProfile: String, CaseIterable, Identifiable {
    case full
    case focus
    case halves
    case thirds
    case quarters
    case custom

    var id: String { rawValue }

    var activityDetail: String {
        switch self {
        case .full:
            return "cycle-profile-full"
        case .focus:
            return "cycle-profile-focus"
        case .halves:
            return "cycle-profile-halves"
        case .thirds:
            return "cycle-profile-thirds"
        case .quarters:
            return "cycle-profile-quarters"
        case .custom:
            return "cycle-profile-custom"
        }
    }

    var title: String {
        switch self {
        case .full:
            return "Full"
        case .focus:
            return "Focus"
        case .halves:
            return "Halves"
        case .thirds:
            return "Thirds"
        case .quarters:
            return "Quarters"
        case .custom:
            return "Custom"
        }
    }

    var actionID: String {
        "window-cycle-profile-\(rawValue)"
    }

    var commandTitle: String {
        "Cycle Profile: \(title)"
    }

    var systemImage: String {
        switch self {
        case .full:
            return "square.grid.3x3"
        case .focus:
            return "viewfinder"
        case .halves:
            return "rectangle.split.2x1"
        case .thirds:
            return "rectangle.split.3x1"
        case .quarters:
            return "rectangle.split.2x2"
        case .custom:
            return "slider.horizontal.3"
        }
    }

    var keywords: [String] {
        switch self {
        case .full:
            return ["profile", "full", "cycle", "window", "layout"]
        case .focus:
            return ["profile", "focus", "cycle", "window", "layout"]
        case .halves:
            return ["profile", "halves", "split", "cycle", "window"]
        case .thirds:
            return ["profile", "thirds", "cycle", "window"]
        case .quarters:
            return ["profile", "quarters", "corners", "cycle", "window"]
        case .custom:
            return ["profile", "custom", "saved", "preset", "cycle", "window"]
        }
    }

    var defaultCommands: [FrontWindowLayoutCommand] {
        switch self {
        case .full:
            return FrontWindowLayoutCommand.cycleEligibleCommands
        case .focus:
            return [.leftHalf, .center, .rightHalf, .maximize]
        case .halves:
            return [.leftHalf, .rightHalf, .topHalf, .bottomHalf, .maximize]
        case .thirds:
            return [.leftThird, .centerThird, .rightThird, .leftTwoThirds, .rightTwoThirds, .maximize]
        case .quarters:
            return [.topLeftQuarter, .topRightQuarter, .bottomLeftQuarter, .bottomRightQuarter, .maximize]
        case .custom:
            return []
        }
    }

    func subtitle(customCommands: [FrontWindowLayoutCommand]) -> String {
        switch self {
        case .full:
            return "Cycle every built-in window layout"
        case .focus:
            return "Cycle left, center, right, maximize"
        case .halves:
            return "Cycle halves, stacks, and maximize"
        case .thirds:
            return "Cycle thirds, wide thirds, and maximize"
        case .quarters:
            return "Cycle quarter corners and maximize"
        case .custom:
            let count = customCommands.count
            let noun = count == 1 ? "layout" : "layouts"
            return "Cycle your saved custom set (\(count) \(noun))"
        }
    }
}

struct WindowLayoutOptions: Equatable {
    let gap: CGFloat

    init(gap: CGFloat = 0) {
        self.gap = max(0, gap)
    }

    func applyGap(to frame: CGRect, inside screenFrame: CGRect) -> CGRect {
        guard gap > 0 else { return frame }
        let inset = gap / 2
        let clampedInsetX = min(inset, max(0, (frame.width - 1) / 2))
        let clampedInsetY = min(inset, max(0, (frame.height - 1) / 2))
        let insetFrame = frame.insetBy(dx: clampedInsetX, dy: clampedInsetY)
        let maxX = screenFrame.maxX - insetFrame.width
        let maxY = screenFrame.maxY - insetFrame.height

        return CGRect(
            x: min(max(insetFrame.minX, screenFrame.minX), maxX),
            y: min(max(insetFrame.minY, screenFrame.minY), maxY),
            width: max(1, insetFrame.width),
            height: max(1, insetFrame.height)
        )
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
    static let defaultCycleCommands = FrontWindowLayoutCommand.cycleEligibleCommands

    static func targetFrame(
        command: FrontWindowLayoutCommand,
        screenFrame: CGRect,
        currentFrame: CGRect?,
        options: WindowLayoutOptions = WindowLayoutOptions()
    ) -> CGRect {
        let halfWidth = floor(screenFrame.width / 2)
        let rightWidth = screenFrame.width - halfWidth
        let thirdWidth = floor(screenFrame.width / 3)
        let rightThirdWidth = screenFrame.width - (thirdWidth * 2)
        let twoThirdsWidth = screenFrame.width - thirdWidth
        let halfHeight = floor(screenFrame.height / 2)
        let bottomHeight = screenFrame.height - halfHeight

        switch command {
        case .cycleLayout:
            return targetFrameForCycle(
                currentFrame: currentFrame,
                screenFrame: screenFrame,
                reverse: false,
                cycleCommands: nil,
                options: options
            )
        case .cycleLayoutBackward:
            return targetFrameForCycle(
                currentFrame: currentFrame,
                screenFrame: screenFrame,
                reverse: true,
                cycleCommands: nil,
                options: options
            )
        case .undoLastMove:
            return currentFrame ?? screenFrame
        case .moveToNextDisplay, .moveToPreviousDisplay:
            return currentFrame ?? screenFrame
        default:
            break
        }

        let baseFrame: CGRect
        switch command {
        case .leftHalf:
            baseFrame = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: halfWidth,
                height: screenFrame.height
            )
        case .rightHalf:
            baseFrame = CGRect(
                x: screenFrame.minX + halfWidth,
                y: screenFrame.minY,
                width: rightWidth,
                height: screenFrame.height
            )
        case .topLeftQuarter:
            baseFrame = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: halfWidth,
                height: halfHeight
            )
        case .topRightQuarter:
            baseFrame = CGRect(
                x: screenFrame.minX + halfWidth,
                y: screenFrame.minY,
                width: rightWidth,
                height: halfHeight
            )
        case .bottomLeftQuarter:
            baseFrame = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY + halfHeight,
                width: halfWidth,
                height: bottomHeight
            )
        case .bottomRightQuarter:
            baseFrame = CGRect(
                x: screenFrame.minX + halfWidth,
                y: screenFrame.minY + halfHeight,
                width: rightWidth,
                height: bottomHeight
            )
        case .leftThird:
            baseFrame = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: thirdWidth,
                height: screenFrame.height
            )
        case .centerThird:
            baseFrame = CGRect(
                x: screenFrame.minX + thirdWidth,
                y: screenFrame.minY,
                width: thirdWidth,
                height: screenFrame.height
            )
        case .rightThird:
            baseFrame = CGRect(
                x: screenFrame.minX + thirdWidth * 2,
                y: screenFrame.minY,
                width: rightThirdWidth,
                height: screenFrame.height
            )
        case .leftTwoThirds:
            baseFrame = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: twoThirdsWidth,
                height: screenFrame.height
            )
        case .rightTwoThirds:
            baseFrame = CGRect(
                x: screenFrame.minX + thirdWidth,
                y: screenFrame.minY,
                width: twoThirdsWidth,
                height: screenFrame.height
            )
        case .topHalf:
            baseFrame = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: screenFrame.width,
                height: halfHeight
            )
        case .bottomHalf:
            baseFrame = CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY + halfHeight,
                width: screenFrame.width,
                height: bottomHeight
            )
        case .maximize:
            baseFrame = screenFrame
        case .center:
            let size = centeredSize(currentFrame: currentFrame, screenFrame: screenFrame)
            baseFrame = CGRect(
                x: screenFrame.midX - size.width / 2,
                y: screenFrame.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
        case .cycleLayout, .cycleLayoutBackward, .undoLastMove, .moveToNextDisplay, .moveToPreviousDisplay:
            baseFrame = currentFrame ?? screenFrame
        }

        return options.applyGap(to: baseFrame, inside: screenFrame)
    }

    static func targetFrameForCycle(
        currentFrame: CGRect?,
        screenFrame: CGRect,
        reverse: Bool = false,
        cycleCommands: [FrontWindowLayoutCommand]? = nil,
        options: WindowLayoutOptions = WindowLayoutOptions()
    ) -> CGRect {
        let cycleCommands = normalizedCycleCommands(cycleCommands)
        guard let firstCommand = cycleCommands.first else { return screenFrame }
        guard let currentFrame else {
            return targetFrame(
                command: firstCommand,
                screenFrame: screenFrame,
                currentFrame: nil,
                options: options
            )
        }

        let normalizedCurrentFrame = currentFrame.integral
        if let currentIndex = cycleCommands.firstIndex(where: { command in
            let commandFrame = targetFrame(
                command: command,
                screenFrame: screenFrame,
                currentFrame: currentFrame,
                options: options
            ).integral
            return isSameLayoutFrame(commandFrame, normalizedCurrentFrame)
        }) {
            let nextIndex = reverse
                ? (currentIndex - 1 + cycleCommands.count) % cycleCommands.count
                : (currentIndex + 1) % cycleCommands.count
            let nextCommand = cycleCommands[nextIndex]
            return targetFrame(
                command: nextCommand,
                screenFrame: screenFrame,
                currentFrame: currentFrame,
                options: options
            )
        }

        return targetFrame(
            command: firstCommand,
            screenFrame: screenFrame,
            currentFrame: currentFrame,
            options: options
        )
    }

    static func normalizedCycleCommands(_ cycleCommands: [FrontWindowLayoutCommand]?) -> [FrontWindowLayoutCommand] {
        let sourceCommands = cycleCommands ?? defaultCycleCommands
        let uniqueCommands = FrontWindowLayoutCommand.normalizedCycleCommands(sourceCommands)
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
    private static let defaultCustomCycleCommands: [FrontWindowLayoutCommand] = [.leftHalf, .rightHalf, .maximize]

    static func cycleProfile(defaults: UserDefaults = .standard) -> FrontWindowCycleProfile {
        guard let rawValue = defaults.string(forKey: AppDefaults.frontWindowCycleProfileKey),
              let profile = FrontWindowCycleProfile(rawValue: rawValue) else {
            return .full
        }
        return profile
    }

    static func setCycleProfile(_ profile: FrontWindowCycleProfile, defaults: UserDefaults = .standard) {
        if profile == .full {
            defaults.removeObject(forKey: AppDefaults.frontWindowCycleProfileKey)
            return
        }
        defaults.set(profile.rawValue, forKey: AppDefaults.frontWindowCycleProfileKey)
    }

    static func normalizedCycleProfileRawValue(_ rawValue: String) -> String {
        FrontWindowCycleProfile(rawValue: rawValue)?.rawValue ?? AppDefaults.frontWindowCycleProfile
    }

    static func layoutGapPoints(defaults: UserDefaults = .standard) -> Int {
        let storedValue = defaults.object(forKey: AppDefaults.frontWindowGapPointsKey) as? Int
            ?? AppDefaults.frontWindowGapPoints
        return AppDefaults.normalizedFrontWindowGapPoints(storedValue)
    }

    static func setLayoutGapPoints(_ points: Int, defaults: UserDefaults = .standard) {
        let normalizedPoints = AppDefaults.normalizedFrontWindowGapPoints(points)
        defaults.set(normalizedPoints, forKey: AppDefaults.frontWindowGapPointsKey)
    }

    static func normalizedCustomCycleCommandRawValues(_ rawValues: [String]) -> [String] {
        FrontWindowLayoutCommand.cycleCommandRawValues(
            FrontWindowLayoutCommand.cycleCommands(
                fromRawValues: rawValues,
                fallback: defaultCustomCycleCommands
            )
        )
    }

    static func customCycleCommands(fromRawValues rawValues: [String]) -> [FrontWindowLayoutCommand] {
        FrontWindowLayoutCommand.cycleCommands(
            fromRawValues: rawValues,
            fallback: defaultCustomCycleCommands
        )
    }

    static func customCycleCommands(defaults: UserDefaults = .standard) -> [FrontWindowLayoutCommand] {
        customCycleCommands(
            fromRawValues: defaults.stringArray(forKey: AppDefaults.frontWindowCustomCycleCommandIDsKey) ?? []
        )
    }

    static func setCustomCycleCommands(
        _ commands: [FrontWindowLayoutCommand],
        defaults: UserDefaults = .standard
    ) {
        defaults.set(
            FrontWindowLayoutCommand.cycleCommandRawValues(commands),
            forKey: AppDefaults.frontWindowCustomCycleCommandIDsKey
        )
    }

    static func cycleCommands(defaults: UserDefaults = .standard) -> [FrontWindowLayoutCommand] {
        cycleCommands(for: cycleProfile(defaults: defaults), defaults: defaults)
    }

    static func cycleCommands(
        for profile: FrontWindowCycleProfile,
        defaults: UserDefaults = .standard
    ) -> [FrontWindowLayoutCommand] {
        switch profile {
        case .custom:
            return customCycleCommands(defaults: defaults)
        default:
            return WindowLayout.normalizedCycleCommands(profile.defaultCommands)
        }
    }

    private static func layoutOptions(defaults: UserDefaults = .standard) -> WindowLayoutOptions {
        WindowLayoutOptions(gap: CGFloat(layoutGapPoints(defaults: defaults)))
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
        let layoutOptions = layoutOptions()
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
                cycleCommands: cycleCommands(),
                options: layoutOptions
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
                currentFrame: currentFrame,
                options: layoutOptions
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
