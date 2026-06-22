import XCTest
@testable import FluidReader

final class AppDelegatePersistenceTests: XCTestCase {
    func testLaunchControlHealthTransitionHistorySanitizesMalformedPersistedDays() throws {
        let defaults = try makeDefaults()
        let historyKey = "launchControlHistory"
        let seededHistory = [
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-09",
                watchToRiskCount: -2,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-02-30",
                watchToRiskCount: 9,
                riskToReadyCount: 9
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: " 2026-06-10 ",
                watchToRiskCount: 2,
                riskToReadyCount: 3
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-10",
                watchToRiskCount: 4,
                riskToReadyCount: -7
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "not-a-day",
                watchToRiskCount: 5,
                riskToReadyCount: 5
            )
        ]
        defaults.set(try JSONEncoder().encode(seededHistory), forKey: historyKey)

        let history = AppDelegate.launchControlHealthTransitionHistory(
            defaults: defaults,
            historyKey: historyKey
        )

        XCTAssertEqual(
            history,
            [
                AppDelegate.LaunchControlHealthTransitionHistoryDay(
                    dayStamp: "2026-06-09",
                    watchToRiskCount: 0,
                    riskToReadyCount: 1
                ),
                AppDelegate.LaunchControlHealthTransitionHistoryDay(
                    dayStamp: "2026-06-10",
                    watchToRiskCount: 4,
                    riskToReadyCount: 0
                )
            ]
        )
    }

    func testFameExceptionalLoopOutcomeCommandHistorySanitizesPersistedSamples() throws {
        let defaults = try makeDefaults()
        let historyKey = "outcomeHistory"
        let recentCommandID = "recent-\(UUID().uuidString)"
        let seededHistory = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: " run-fame-next-move-copy-drafts \n",
                recordedAt: 100,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: " \n\t ",
                recordedAt: 110,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: recentCommandID,
                recordedAt: 120,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-command-center",
                recordedAt: -1,
                wasSuccess: true
            )
        ]
        defaults.set(try JSONEncoder().encode(seededHistory), forKey: historyKey)

        let history = AppDelegate.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: historyKey
        )

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].commandToken, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(history[0].recordedAt, 100)
        XCTAssertFalse(history[0].wasSuccess)
        XCTAssertEqual(history[1].commandToken, "recent-item")
        XCTAssertEqual(history[1].recordedAt, 120)
        XCTAssertTrue(history[1].wasSuccess)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderAppDelegatePersistenceTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
