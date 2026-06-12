import Foundation

struct FirstRunGuide {
    private static let defaultSetupChecklistKey = "didShowFirstRunSetupChecklist"
    private static let defaultInstallDayKey = "firstRunInstallDay"
    private static let defaultFameOnboardingNudgeLastShownDayKey = "fameOnboardingNudgeLastShownDay"
    private static let defaultFameOnboardingCompletedDaysKey = "fameOnboardingCompletedDays"

    private let defaults: UserDefaults
    private let setupChecklistKey: String
    private let installDayKey: String
    private let fameOnboardingNudgeLastShownDayKey: String
    private let fameOnboardingCompletedDaysKey: String

    init(
        defaults: UserDefaults = .standard,
        setupChecklistKey: String = FirstRunGuide.defaultSetupChecklistKey,
        installDayKey: String = FirstRunGuide.defaultInstallDayKey,
        fameOnboardingNudgeLastShownDayKey: String = FirstRunGuide.defaultFameOnboardingNudgeLastShownDayKey,
        fameOnboardingCompletedDaysKey: String = FirstRunGuide.defaultFameOnboardingCompletedDaysKey
    ) {
        self.defaults = defaults
        self.setupChecklistKey = setupChecklistKey
        self.installDayKey = installDayKey
        self.fameOnboardingNudgeLastShownDayKey = fameOnboardingNudgeLastShownDayKey
        self.fameOnboardingCompletedDaysKey = fameOnboardingCompletedDaysKey
    }

    func shouldShowSetupChecklist() -> Bool {
        !defaults.bool(forKey: setupChecklistKey)
    }

    func markSetupChecklistShown() {
        defaults.set(true, forKey: setupChecklistKey)
    }

    func claimSetupChecklistLaunch() -> Bool {
        guard shouldShowSetupChecklist() else { return false }
        markSetupChecklistShown()
        return true
    }

    func fameOnboardingDay(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        let installDayStamp = installAnchorDayStamp(now: now, calendar: calendar)
        let formatter = Self.dayStampFormatter(calendar: calendar)
        guard let installDate = formatter.date(from: installDayStamp) else { return 1 }
        let startInstallDay = calendar.startOfDay(for: installDate)
        let startCurrentDay = calendar.startOfDay(for: now)
        let delta = calendar.dateComponents([.day], from: startInstallDay, to: startCurrentDay).day ?? 0
        return max(1, delta + 1)
    }

    func shouldShowFameOnboardingNudge(
        now: Date = Date(),
        calendar: Calendar = .current,
        cadenceBestStreak: Int,
        fameOnboardingEnabled: Bool = AppDefaults.fameOnboardingNudgeEnabled,
        onboardingWindowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) -> Bool {
        guard fameOnboardingEnabled else { return false }
        let normalizedBestStreak = max(0, cadenceBestStreak)
        guard normalizedBestStreak < 10 else { return false }
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            onboardingWindowDays
        )
        let completedDays = fameOnboardingCompletedDays(onboardingWindowDays: normalizedWindowDays)
        guard completedDays < normalizedWindowDays else { return false }
        let onboardingDay = fameOnboardingDay(now: now, calendar: calendar)
        guard onboardingDay <= normalizedWindowDays else { return false }
        let todayStamp = Self.dayStamp(for: now, calendar: calendar)
        return defaults.string(forKey: fameOnboardingNudgeLastShownDayKey) != todayStamp
    }

    func markFameOnboardingNudgeShown(
        now: Date = Date(),
        calendar: Calendar = .current,
        onboardingWindowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) {
        let todayStamp = Self.dayStamp(for: now, calendar: calendar)
        guard defaults.string(forKey: fameOnboardingNudgeLastShownDayKey) != todayStamp else { return }

        defaults.set(todayStamp, forKey: fameOnboardingNudgeLastShownDayKey)
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            onboardingWindowDays
        )
        let nextCompletedDays = min(
            normalizedWindowDays,
            max(0, defaults.integer(forKey: fameOnboardingCompletedDaysKey)) + 1
        )
        defaults.set(nextCompletedDays, forKey: fameOnboardingCompletedDaysKey)
    }

    func fameOnboardingCompletedDays(
        onboardingWindowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) -> Int {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            onboardingWindowDays
        )
        return min(
            normalizedWindowDays,
            max(0, defaults.integer(forKey: fameOnboardingCompletedDaysKey))
        )
    }

    func fameOnboardingRemainingDays(
        onboardingWindowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) -> Int {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            onboardingWindowDays
        )
        return max(0, normalizedWindowDays - fameOnboardingCompletedDays(onboardingWindowDays: normalizedWindowDays))
    }

    private func installAnchorDayStamp(
        now: Date,
        calendar: Calendar
    ) -> String {
        if let persisted = defaults.string(forKey: installDayKey), !persisted.isEmpty {
            return persisted
        }
        let stamp = Self.dayStamp(for: now, calendar: calendar)
        defaults.set(stamp, forKey: installDayKey)
        return stamp
    }

    private static func dayStamp(
        for date: Date,
        calendar: Calendar
    ) -> String {
        dayStampFormatter(calendar: calendar).string(from: date)
    }

    private static func dayStampFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
