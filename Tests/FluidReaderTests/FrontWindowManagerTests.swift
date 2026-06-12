import XCTest
import ApplicationServices
@testable import FluidReader

final class FrontWindowManagerTests: XCTestCase {
    func testAccessibilityElementRejectsWrongType() {
        XCTAssertNil(FrontWindowManager.accessibilityElement(from: nil))
        XCTAssertNil(FrontWindowManager.accessibilityElement(from: "not a window" as CFString))

        let appElement = AXUIElementCreateApplication(ProcessInfo.processInfo.processIdentifier)
        XCTAssertNotNil(FrontWindowManager.accessibilityElement(from: appElement))
    }

    func testAccessibilityValueRejectsWrongTypeAndWrongValueKind() throws {
        XCTAssertNil(FrontWindowManager.accessibilityValue(from: nil, expectedType: .cgPoint))
        XCTAssertNil(FrontWindowManager.accessibilityValue(from: "not a value" as CFString, expectedType: .cgPoint))

        var point = CGPoint(x: 10, y: 20)
        let pointValue = try XCTUnwrap(AXValueCreate(.cgPoint, &point))

        XCTAssertNotNil(FrontWindowManager.accessibilityValue(from: pointValue, expectedType: .cgPoint))
        XCTAssertNil(FrontWindowManager.accessibilityValue(from: pointValue, expectedType: .cgSize))
    }

    func testHalfWindowFrames() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)

        XCTAssertEqual(
            WindowLayout.targetFrame(command: .leftHalf, screenFrame: screen, currentFrame: nil),
            CGRect(x: 0, y: 24, width: 720, height: 876)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .rightHalf, screenFrame: screen, currentFrame: nil),
            CGRect(x: 720, y: 24, width: 720, height: 876)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .topHalf, screenFrame: screen, currentFrame: nil),
            CGRect(x: 0, y: 24, width: 1440, height: 438)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .bottomHalf, screenFrame: screen, currentFrame: nil),
            CGRect(x: 0, y: 462, width: 1440, height: 438)
        )
    }

    func testThirdWindowFrames() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)

        XCTAssertEqual(
            WindowLayout.targetFrame(command: .leftThird, screenFrame: screen, currentFrame: nil),
            CGRect(x: 0, y: 24, width: 480, height: 876)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .centerThird, screenFrame: screen, currentFrame: nil),
            CGRect(x: 480, y: 24, width: 480, height: 876)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .rightThird, screenFrame: screen, currentFrame: nil),
            CGRect(x: 960, y: 24, width: 480, height: 876)
        )
    }

    func testTwoThirdWindowFrames() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)

        XCTAssertEqual(
            WindowLayout.targetFrame(command: .leftTwoThirds, screenFrame: screen, currentFrame: nil),
            CGRect(x: 0, y: 24, width: 960, height: 876)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .rightTwoThirds, screenFrame: screen, currentFrame: nil),
            CGRect(x: 480, y: 24, width: 960, height: 876)
        )
    }

    func testQuarterWindowFrames() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)

        XCTAssertEqual(
            WindowLayout.targetFrame(command: .topLeftQuarter, screenFrame: screen, currentFrame: nil),
            CGRect(x: 0, y: 24, width: 720, height: 438)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .topRightQuarter, screenFrame: screen, currentFrame: nil),
            CGRect(x: 720, y: 24, width: 720, height: 438)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .bottomLeftQuarter, screenFrame: screen, currentFrame: nil),
            CGRect(x: 0, y: 462, width: 720, height: 438)
        )
        XCTAssertEqual(
            WindowLayout.targetFrame(command: .bottomRightQuarter, screenFrame: screen, currentFrame: nil),
            CGRect(x: 720, y: 462, width: 720, height: 438)
        )
    }

    func testMaximizeUsesFullScreenFrame() {
        let screen = CGRect(x: 10, y: 20, width: 1000, height: 700)

        XCTAssertEqual(
            WindowLayout.targetFrame(command: .maximize, screenFrame: screen, currentFrame: nil),
            screen
        )
    }

    func testCenterKeepsCurrentSizeInsideScreen() {
        let screen = CGRect(x: 0, y: 0, width: 1200, height: 800)
        let current = CGRect(x: 100, y: 100, width: 500, height: 300)

        XCTAssertEqual(
            WindowLayout.targetFrame(command: .center, screenFrame: screen, currentFrame: current),
            CGRect(x: 350, y: 250, width: 500, height: 300)
        )
    }

    func testCenterCapsLargeWindow() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let current = CGRect(x: 0, y: 0, width: 2000, height: 2000)

        XCTAssertEqual(
            WindowLayout.targetFrame(command: .center, screenFrame: screen, currentFrame: current),
            CGRect(x: 40, y: 32, width: 920, height: 736)
        )
    }

    func testBestScreenUsesContainingScreenThenNearest() throws {
        let left = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let right = CGRect(x: 1000, y: 0, width: 1000, height: 800)

        XCTAssertEqual(
            WindowLayout.bestScreenFrame(
                for: CGRect(x: 1200, y: 200, width: 300, height: 300),
                screenFrames: [left, right]
            ),
            right
        )

        XCTAssertEqual(
            WindowLayout.bestScreenFrame(
                for: CGRect(x: 2500, y: 200, width: 300, height: 300),
                screenFrames: [left, right]
            ),
            right
        )
    }

    func testNextDisplayPreservesRelativePosition() throws {
        let left = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let right = CGRect(x: 1000, y: 0, width: 1200, height: 900)
        let current = CGRect(x: 100, y: 200, width: 500, height: 300)

        XCTAssertEqual(
            try XCTUnwrap(
                WindowLayout.targetFrameForNextDisplay(
                    currentFrame: current,
                    screenFrames: [left, right]
                )
            ),
            CGRect(x: 1170, y: 243.75, width: 500, height: 300)
        )
    }

    func testNextDisplayClampsLargeWindowToTargetScreen() throws {
        let left = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let right = CGRect(x: 1000, y: 0, width: 700, height: 500)
        let current = CGRect(x: 40, y: 60, width: 900, height: 700)

        XCTAssertEqual(
            try XCTUnwrap(
                WindowLayout.targetFrameForNextDisplay(
                    currentFrame: current,
                    screenFrames: [left, right]
                )
            ),
            CGRect(x: 1000, y: 0, width: 700, height: 500)
        )
    }

    func testNextDisplayRequiresAnotherScreen() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let current = CGRect(x: 100, y: 100, width: 400, height: 300)

        XCTAssertNil(
            WindowLayout.targetFrameForNextDisplay(
                currentFrame: current,
                screenFrames: [screen]
            )
        )
    }

    func testPreviousDisplayWrapsBackAcrossScreens() throws {
        let left = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let middle = CGRect(x: 1000, y: 0, width: 1200, height: 900)
        let right = CGRect(x: 2200, y: 0, width: 800, height: 700)
        let current = CGRect(x: 2340, y: 140, width: 600, height: 500)

        XCTAssertEqual(
            try XCTUnwrap(
                WindowLayout.targetFrameForPreviousDisplay(
                    currentFrame: current,
                    screenFrames: [left, middle, right]
                )
            ),
            CGRect(x: 1360, y: 251.42857142857144, width: 600, height: 500)
        )
    }

    func testUndoStoreTracksFramesPerProcessID() {
        var store = FrontWindowUndoStore()
        let first = CGRect(x: 10, y: 20, width: 300, height: 400)
        let second = CGRect(x: 40, y: 50, width: 320, height: 420)

        store.remember(first, for: 101)
        store.remember(second, for: 202)

        XCTAssertTrue(store.hasFrame(for: 101))
        XCTAssertTrue(store.hasFrame(for: 202))
        XCTAssertFalse(store.hasFrame(for: 303))
    }

    func testUndoStoreSwapReturnsPreviousFrameAndUpdatesCurrent() throws {
        var store = FrontWindowUndoStore()
        let previous = CGRect(x: 0, y: 0, width: 800, height: 600)
        let current = CGRect(x: 100, y: 100, width: 900, height: 700)

        store.remember(previous, for: 404)
        XCTAssertEqual(store.swapCurrentFrame(current, for: 404), previous.integral)

        let swappedBack = try XCTUnwrap(store.swapCurrentFrame(previous, for: 404))
        XCTAssertEqual(swappedBack, current.integral)
    }

    func testCycleLayoutAdvancesKnownPresetsAndWraps() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)
        let leftHalf = WindowLayout.targetFrame(command: .leftHalf, screenFrame: screen, currentFrame: nil)
        let rightHalf = WindowLayout.targetFrame(command: .rightHalf, screenFrame: screen, currentFrame: nil)
        let rightTwoThirds = WindowLayout.targetFrame(command: .rightTwoThirds, screenFrame: screen, currentFrame: nil)
        let maximize = WindowLayout.targetFrame(command: .maximize, screenFrame: screen, currentFrame: nil)
        let center = WindowLayout.targetFrame(command: .center, screenFrame: screen, currentFrame: maximize)

        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(currentFrame: leftHalf, screenFrame: screen),
            rightHalf
        )
        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(currentFrame: rightTwoThirds, screenFrame: screen),
            maximize
        )
        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(currentFrame: center, screenFrame: screen),
            leftHalf
        )
    }

    func testCycleLayoutFallsBackToLeftHalfForUnknownFrame() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)
        let unknown = CGRect(x: 123, y: 77, width: 901, height: 511)

        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(currentFrame: unknown, screenFrame: screen),
            WindowLayout.targetFrame(command: .leftHalf, screenFrame: screen, currentFrame: unknown)
        )
    }

    func testCycleLayoutCanMoveBackward() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)
        let leftHalf = WindowLayout.targetFrame(command: .leftHalf, screenFrame: screen, currentFrame: nil)
        let rightHalf = WindowLayout.targetFrame(command: .rightHalf, screenFrame: screen, currentFrame: nil)
        let center = WindowLayout.targetFrame(command: .center, screenFrame: screen, currentFrame: rightHalf)

        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(currentFrame: rightHalf, screenFrame: screen, reverse: true),
            leftHalf
        )
        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(currentFrame: leftHalf, screenFrame: screen, reverse: true),
            center
        )
    }

    func testCycleLayoutSupportsCustomCycleCommands() {
        let screen = CGRect(x: 0, y: 24, width: 1440, height: 876)
        let customCommands: [FrontWindowLayoutCommand] = [.leftHalf, .rightHalf, .maximize]
        let leftHalf = WindowLayout.targetFrame(command: .leftHalf, screenFrame: screen, currentFrame: nil)
        let maximize = WindowLayout.targetFrame(command: .maximize, screenFrame: screen, currentFrame: nil)

        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(
                currentFrame: leftHalf,
                screenFrame: screen,
                reverse: false,
                cycleCommands: customCommands
            ),
            WindowLayout.targetFrame(command: .rightHalf, screenFrame: screen, currentFrame: leftHalf)
        )
        XCTAssertEqual(
            WindowLayout.targetFrameForCycle(
                currentFrame: leftHalf,
                screenFrame: screen,
                reverse: true,
                cycleCommands: customCommands
            ),
            maximize
        )
    }

    func testCycleProfilePersistsAndFallsBackToDefault() {
        let suiteName = "FrontWindowManagerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        XCTAssertEqual(FrontWindowManager.cycleProfile(defaults: defaults), .full)
        FrontWindowManager.setCycleProfile(.focus, defaults: defaults)
        XCTAssertEqual(FrontWindowManager.cycleProfile(defaults: defaults), .focus)
        FrontWindowManager.setCycleProfile(.full, defaults: defaults)
        XCTAssertEqual(FrontWindowManager.cycleProfile(defaults: defaults), .full)
    }
}
