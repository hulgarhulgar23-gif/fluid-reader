import XCTest
@testable import FluidReader

final class FirstRunGuideTests: XCTestCase {
    func testNewInstallShouldShowSetupChecklist() throws {
        let guide = FirstRunGuide(defaults: try makeDefaults())

        XCTAssertTrue(guide.shouldShowSetupChecklist())
    }

    func testClaimMarksSetupChecklistShown() throws {
        let defaults = try makeDefaults()
        let guide = FirstRunGuide(defaults: defaults)

        XCTAssertTrue(guide.claimSetupChecklistLaunch())
        XCTAssertFalse(guide.shouldShowSetupChecklist())
        XCTAssertFalse(guide.claimSetupChecklistLaunch())
    }

    func testMarkSetupChecklistShownSkipsFutureLaunches() throws {
        let guide = FirstRunGuide(defaults: try makeDefaults())

        guide.markSetupChecklistShown()

        XCTAssertFalse(guide.shouldShowSetupChecklist())
    }

    func testFameOnboardingDayUsesInstallAnchorAndCalendarDays() throws {
        let defaults = try makeDefaults()
        let guide = FirstRunGuide(defaults: defaults)
        let calendar = makeUTCCalendar()
        let installDate = try makeDate("2026-06-10T08:30:00Z")

        XCTAssertEqual(
            guide.fameOnboardingDay(now: installDate, calendar: calendar),
            1
        )
        XCTAssertEqual(
            guide.fameOnboardingDay(
                now: try makeDate("2026-06-10T22:10:00Z"),
                calendar: calendar
            ),
            1
        )
        XCTAssertEqual(
            guide.fameOnboardingDay(
                now: try makeDate("2026-06-12T06:00:00Z"),
                calendar: calendar
            ),
            3
        )
    }

    func testFameOnboardingNudgeSurfacesOncePerDayInsideFirstWeek() throws {
        let defaults = try makeDefaults()
        let guide = FirstRunGuide(defaults: defaults)
        let calendar = makeUTCCalendar()
        let dayOne = try makeDate("2026-06-10T09:00:00Z")

        XCTAssertTrue(
            guide.shouldShowFameOnboardingNudge(
                now: dayOne,
                calendar: calendar,
                cadenceBestStreak: 0
            )
        )

        guide.markFameOnboardingNudgeShown(now: dayOne, calendar: calendar)

        XCTAssertFalse(
            guide.shouldShowFameOnboardingNudge(
                now: dayOne,
                calendar: calendar,
                cadenceBestStreak: 0
            )
        )
        XCTAssertTrue(
            guide.shouldShowFameOnboardingNudge(
                now: try makeDate("2026-06-11T09:00:00Z"),
                calendar: calendar,
                cadenceBestStreak: 0
            )
        )
    }

    func testFameOnboardingNudgeSkipsAfterWeekOrWhenBestStreakIsHigh() throws {
        let defaults = try makeDefaults()
        let guide = FirstRunGuide(defaults: defaults)
        let calendar = makeUTCCalendar()
        let installDay = try makeDate("2026-06-10T09:00:00Z")
        _ = guide.fameOnboardingDay(now: installDay, calendar: calendar)

        XCTAssertFalse(
            guide.shouldShowFameOnboardingNudge(
                now: try makeDate("2026-06-18T09:00:00Z"),
                calendar: calendar,
                cadenceBestStreak: 0
            )
        )
        XCTAssertFalse(
            guide.shouldShowFameOnboardingNudge(
                now: try makeDate("2026-06-11T09:00:00Z"),
                calendar: calendar,
                cadenceBestStreak: 10
            )
        )
    }

    func testFameOnboardingNudgeRespectsToggleAndCustomWindowDays() throws {
        let defaults = try makeDefaults()
        let guide = FirstRunGuide(defaults: defaults)
        let calendar = makeUTCCalendar()
        let installDay = try makeDate("2026-06-10T09:00:00Z")
        _ = guide.fameOnboardingDay(now: installDay, calendar: calendar)

        XCTAssertFalse(
            guide.shouldShowFameOnboardingNudge(
                now: try makeDate("2026-06-11T09:00:00Z"),
                calendar: calendar,
                cadenceBestStreak: 0,
                fameOnboardingEnabled: false,
                onboardingWindowDays: 7
            )
        )

        XCTAssertTrue(
            guide.shouldShowFameOnboardingNudge(
                now: try makeDate("2026-06-12T09:00:00Z"),
                calendar: calendar,
                cadenceBestStreak: 0,
                fameOnboardingEnabled: true,
                onboardingWindowDays: 3
            )
        )
        XCTAssertFalse(
            guide.shouldShowFameOnboardingNudge(
                now: try makeDate("2026-06-13T09:00:00Z"),
                calendar: calendar,
                cadenceBestStreak: 0,
                fameOnboardingEnabled: true,
                onboardingWindowDays: 3
            )
        )
    }

    func testMarkFameOnboardingNudgeShownTracksCompletedDaysOncePerDay() throws {
        let defaults = try makeDefaults()
        let guide = FirstRunGuide(defaults: defaults)
        let calendar = makeUTCCalendar()
        let dayOne = try makeDate("2026-06-10T09:00:00Z")
        let dayTwo = try makeDate("2026-06-11T09:00:00Z")

        XCTAssertEqual(guide.fameOnboardingCompletedDays(onboardingWindowDays: 7), 0)
        XCTAssertEqual(guide.fameOnboardingRemainingDays(onboardingWindowDays: 7), 7)

        guide.markFameOnboardingNudgeShown(
            now: dayOne,
            calendar: calendar,
            onboardingWindowDays: 7
        )
        XCTAssertEqual(guide.fameOnboardingCompletedDays(onboardingWindowDays: 7), 1)
        XCTAssertEqual(guide.fameOnboardingRemainingDays(onboardingWindowDays: 7), 6)

        guide.markFameOnboardingNudgeShown(
            now: dayOne,
            calendar: calendar,
            onboardingWindowDays: 7
        )
        XCTAssertEqual(guide.fameOnboardingCompletedDays(onboardingWindowDays: 7), 1)

        guide.markFameOnboardingNudgeShown(
            now: dayTwo,
            calendar: calendar,
            onboardingWindowDays: 7
        )
        XCTAssertEqual(guide.fameOnboardingCompletedDays(onboardingWindowDays: 7), 2)
        XCTAssertEqual(guide.fameOnboardingRemainingDays(onboardingWindowDays: 7), 5)
    }

    func testFameOnboardingCompletedDaysClampsToConfiguredWindow() throws {
        let defaults = try makeDefaults()
        let guide = FirstRunGuide(defaults: defaults)
        let calendar = makeUTCCalendar()

        for dayOffset in 0..<5 {
            let stamp = try makeDate("2026-06-\(String(format: "%02d", 10 + dayOffset))T09:00:00Z")
            guide.markFameOnboardingNudgeShown(
                now: stamp,
                calendar: calendar,
                onboardingWindowDays: 3
            )
        }

        XCTAssertEqual(guide.fameOnboardingCompletedDays(onboardingWindowDays: 3), 3)
        XCTAssertEqual(guide.fameOnboardingRemainingDays(onboardingWindowDays: 3), 0)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeUTCCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func makeDate(_ iso8601: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        return try XCTUnwrap(formatter.date(from: iso8601))
    }
}
