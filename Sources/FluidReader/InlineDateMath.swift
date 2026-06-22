import Foundation

enum InlineDate {
    static func makeAction(
        query: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        copyResult: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        guard let calculation = DateCalc.parse(query, now: now, calendar: calendar) else { return nil }

        return CommandPaletteAction(
            id: "inline-date-math",
            title: "Date: \(calculation.result)",
            subtitle: calculation.subtitle,
            systemImage: "calendar",
            sourceKind: .date,
            keywords: [query, calculation.source, calculation.result],
            canFavorite: false
        ) {
            copyResult(calculation.result)
        }
    }
}

struct DateCalc: Equatable {
    let source: String
    let result: String

    var subtitle: String {
        "\(source) = \(result)"
    }

    static func parse(_ query: String, now: Date = Date(), calendar: Calendar = .current) -> DateCalc? {
        let cleaned = normalizeQuery(query)
        guard !cleaned.isEmpty else { return nil }

        if let special = parseSpecial(cleaned, now: now, calendar: calendar) {
            return special
        }
        if let anchor = parseAnchor(cleaned, now: now, calendar: calendar) {
            return anchor
        }
        if let weekdayQuery = parseWeekdayQuery(cleaned, now: now, calendar: calendar) {
            return weekdayQuery
        }
        return parseRelative(cleaned, now: now, calendar: calendar)
    }

    private static func parseSpecial(_ query: String, now: Date, calendar: Calendar) -> DateCalc? {
        let anchor = calendar.startOfDay(for: now)

        if query == "next business day" {
            guard let nextBusinessDay = addBusinessDays(1, from: anchor, calendar: calendar) else {
                return nil
            }
            return DateCalc(
                source: query,
                result: ClipboardUtility.dateStamp(nextBusinessDay, timeZone: calendar.timeZone)
            )
        }
        if query == "next business week" {
            guard let businessWeekStart = weekBoundary(anchor, calendar: calendar, end: false),
                  let nextBusinessWeekStart = calendar.date(byAdding: .day, value: 7, to: businessWeekStart) else {
                return nil
            }
            return DateCalc(
                source: query,
                result: ClipboardUtility.dateStamp(nextBusinessWeekStart, timeZone: calendar.timeZone)
            )
        }

        let offsetDays: Int
        switch query {
        case "today":
            offsetDays = 0
        case "tomorrow":
            offsetDays = 1
        case "yesterday":
            offsetDays = -1
        default:
            return nil
        }

        guard let date = calendar.date(byAdding: .day, value: offsetDays, to: anchor) else { return nil }
        return DateCalc(source: query, result: ClipboardUtility.dateStamp(date, timeZone: calendar.timeZone))
    }

    private static func parseRelative(_ query: String, now: Date, calendar: Calendar) -> DateCalc? {
        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return nil }

        var amount: Int?
        var unitTokens: [String] = []

        if tokens.count >= 3,
           tokens[0] == "in",
           let parsedAmount = Int(tokens[1]) {
            amount = parsedAmount
            unitTokens = Array(tokens.dropFirst(2))
        } else if tokens.count == 2,
                  tokens[0] == "in" {
            let (amountText, unitText) = splitAmountAndUnit(tokens[1])
            amount = Int(amountText)
            unitTokens = unitText.isEmpty ? [] : [unitText]
        } else if tokens.count >= 4,
                  let parsedAmount = Int(tokens[0]),
                  tokens.suffix(2) == ["from", "now"] {
            amount = parsedAmount
            unitTokens = Array(tokens.dropFirst().dropLast(2))
        } else if tokens.count == 3,
                  tokens.suffix(2) == ["from", "now"] {
            let (amountText, unitText) = splitAmountAndUnit(tokens[0])
            amount = Int(amountText)
            unitTokens = unitText.isEmpty ? [] : [unitText]
        } else {
            return nil
        }

        guard let amount,
              amount >= 0,
              let unit = unit(unitTokens) else {
            return nil
        }

        let anchor = calendar.startOfDay(for: now)
        let date: Date?
        switch unit {
        case .day:
            date = calendar.date(byAdding: .day, value: amount, to: anchor)
        case .week:
            date = calendar.date(byAdding: .weekOfYear, value: amount, to: anchor)
        case .businessDay:
            date = addBusinessDays(amount, from: anchor, calendar: calendar)
        }
        guard let date else { return nil }
        return DateCalc(source: query, result: ClipboardUtility.dateStamp(date, timeZone: calendar.timeZone))
    }

    private static func splitAmountAndUnit(_ token: String) -> (String, String) {
        let amountPart = token.prefix { character in
            character.isNumber || character == "+" || character == "-"
        }
        let unitPart = token.dropFirst(amountPart.count)
        return (String(amountPart), String(unitPart))
    }

    private static func parseAnchor(_ query: String, now: Date, calendar: Calendar) -> DateCalc? {
        let anchor = calendar.startOfDay(for: now)
        let targetDate: Date?
        switch query {
        case "start of week":
            targetDate = weekBoundary(anchor, calendar: calendar, end: false)
        case "end of week":
            targetDate = weekBoundary(anchor, calendar: calendar, end: true)
        case "start of quarter":
            targetDate = quarterBoundary(anchor, calendar: calendar, end: false)
        case "end of quarter":
            targetDate = quarterBoundary(anchor, calendar: calendar, end: true)
        case "start of year":
            targetDate = yearBoundary(anchor, calendar: calendar, end: false)
        case "end of year":
            targetDate = yearBoundary(anchor, calendar: calendar, end: true)
        default:
            targetDate = nil
        }
        guard let targetDate else { return nil }
        return DateCalc(source: query, result: ClipboardUtility.dateStamp(targetDate, timeZone: calendar.timeZone))
    }

    private static func parseWeekdayQuery(_ query: String, now: Date, calendar: Calendar) -> DateCalc? {
        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return nil }

        let mode: WeekdayQueryMode
        let weekdayToken: String
        if tokens.count == 1 {
            mode = .upcoming
            weekdayToken = tokens[0]
        } else if tokens.count == 2, tokens[0] == "next" {
            mode = .next
            weekdayToken = tokens[1]
        } else if tokens.count == 2, tokens[0] == "this" {
            mode = .thisWeek
            weekdayToken = tokens[1]
        } else {
            return nil
        }

        guard let targetWeekday = weekday(weekdayToken) else { return nil }

        let anchor = calendar.startOfDay(for: now)
        let currentWeekday = calendar.component(.weekday, from: anchor)

        var offset: Int
        switch mode {
        case .next:
            offset = (targetWeekday - currentWeekday + 7) % 7
            if offset == 0 {
                offset = 7
            }
        case .upcoming:
            offset = (targetWeekday - currentWeekday + 7) % 7
        case .thisWeek:
            offset = targetWeekday - currentWeekday
        }

        guard let targetDate = calendar.date(byAdding: .day, value: offset, to: anchor) else { return nil }
        return DateCalc(source: query, result: ClipboardUtility.dateStamp(targetDate, timeZone: calendar.timeZone))
    }

    private static func weekBoundary(_ date: Date, calendar: Calendar, end: Bool) -> Date? {
        let weekday = calendar.component(.weekday, from: date)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: date) else {
            return nil
        }
        guard end else { return monday }
        return calendar.date(byAdding: .day, value: 6, to: monday)
    }

    private static func quarterBoundary(_ date: Date, calendar: Calendar, end: Bool) -> Date? {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year,
              let month = components.month else {
            return nil
        }

        let quarterStartMonth = ((month - 1) / 3) * 3 + 1
        var quarterComponents = DateComponents()
        quarterComponents.calendar = calendar
        quarterComponents.timeZone = calendar.timeZone
        quarterComponents.year = year
        quarterComponents.month = quarterStartMonth
        quarterComponents.day = 1
        guard let quarterStart = calendar.date(from: quarterComponents) else { return nil }
        guard end else { return quarterStart }

        guard let nextQuarter = calendar.date(byAdding: .month, value: 3, to: quarterStart) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: -1, to: nextQuarter)
    }

    private static func yearBoundary(_ date: Date, calendar: Calendar, end: Bool) -> Date? {
        var components = calendar.dateComponents([.year], from: date)
        components.month = 1
        components.day = 1
        guard let yearStart = calendar.date(from: components) else { return nil }
        guard end else { return yearStart }

        guard let nextYear = calendar.date(byAdding: .year, value: 1, to: yearStart) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: -1, to: nextYear)
    }

    private static func addBusinessDays(_ amount: Int, from date: Date, calendar: Calendar) -> Date? {
        guard amount >= 0 else { return nil }
        if amount == 0 {
            return date
        }

        var currentDate = date
        var remaining = amount
        while remaining > 0 {
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                return nil
            }
            currentDate = nextDate
            let weekday = calendar.component(.weekday, from: currentDate)
            if weekday != 1 && weekday != 7 {
                remaining -= 1
            }
        }
        return currentDate
    }

    private static func normalizeQuery(_ query: String) -> String {
        InlineQueryNormalizer.normalize(
            query,
            prefixes: [
                "date ",
                "when is ",
                "what date is "
            ]
        )
    }

    private static func weekday(_ token: String) -> Int? {
        switch token {
        case "sunday":
            return 1
        case "monday":
            return 2
        case "tuesday":
            return 3
        case "wednesday":
            return 4
        case "thursday":
            return 5
        case "friday":
            return 6
        case "saturday":
            return 7
        default:
            return nil
        }
    }

    private static func unit(_ tokens: [String]) -> Unit? {
        guard !tokens.isEmpty else { return nil }
        if tokens.count == 1 {
            switch tokens[0] {
            case "day", "days", "d":
                return .day
            case "week", "weeks", "w":
                return .week
            case "workday", "workdays", "businessday", "businessdays", "bd":
                return .businessDay
            default:
                return nil
            }
        } else if tokens.count == 2 {
            if tokens[0] == "business", tokens[1] == "day" || tokens[1] == "days" {
                return .businessDay
            }
        }
        return nil
    }

    private enum WeekdayQueryMode {
        case thisWeek
        case upcoming
        case next
    }

    private enum Unit {
        case day
        case week
        case businessDay
    }
}
