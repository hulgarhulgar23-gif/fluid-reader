import Foundation

enum InlineUnitConverter {
    static func makeAction(
        query: String,
        copyResult: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        guard let conversion = UnitConversion.parse(query) else { return nil }

        return CommandPaletteAction(
            id: "inline-unit-converter",
            title: "Convert: \(conversion.result)",
            subtitle: conversion.subtitle,
            systemImage: "ruler",
            sourceKind: .unit,
            keywords: [query, conversion.source, conversion.result],
            canFavorite: false
        ) {
            copyResult(conversion.result)
        }
    }
}

struct UnitConversion: Equatable {
    let source: String
    let result: String

    var subtitle: String {
        "\(source) = \(result)"
    }

    static func parse(_ query: String, localTimeZone: TimeZone = .current) -> UnitConversion? {
        let parts = InlineQueryNormalizer.normalize(
            query,
            prefixes: [
                "convert ",
                "what is ",
                "timezone "
            ]
        )
            .replacingOccurrences(of: "->", with: " to ")
            .replacingOccurrences(of: "fl oz", with: "floz")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        if let timeConversion = parseTimeZone(parts, localTimeZone: localTimeZone) {
            return timeConversion
        }
        let amountPart: String
        let sourceFallback: String
        let targetPart: String
        if parts.count == 4, ["to", "in", "as"].contains(parts[2]) {
            amountPart = parts[0]
            sourceFallback = parts[1]
            targetPart = parts[3]
        } else if parts.count == 3, ["to", "in", "as"].contains(parts[1]) {
            amountPart = parts[0]
            sourceFallback = ""
            targetPart = parts[2]
        } else {
            return nil
        }

        let (amountText, sourceUnitText) = splitAmountAndUnit(amountPart, fallbackUnit: sourceFallback)
        guard let amount = Double(amountText),
              let sourceUnit = unit(sourceUnitText),
              let targetUnit = unit(targetPart),
              sourceUnit.kind == targetUnit.kind else {
            return nil
        }

        let output = sourceUnit.kind == .temp
            ? convertTemperature(amount, from: sourceUnit.symbol, to: targetUnit.symbol)
            : amount * sourceUnit.rate / targetUnit.rate
        let result = "\(format(output)) \(targetUnit.symbol)"
        let source = "\(format(amount)) \(sourceUnit.symbol)"
        return UnitConversion(source: source, result: result)
    }

    private static func splitAmountAndUnit(_ amountPart: String, fallbackUnit: String) -> (String, String) {
        let number = amountPart.prefix { character in
            character.isNumber || character == "." || character == "-" || character == "+"
        }
        let unit = amountPart.dropFirst(number.count)
        return (String(number), unit.isEmpty ? fallbackUnit : String(unit))
    }

    private static func parseTimeZone(_ parts: [String], localTimeZone: TimeZone = .current) -> UnitConversion? {
        guard let toIndex = parts.firstIndex(of: "to"),
              toIndex < parts.count - 1,
              let parsedTime = parseTime(parts),
              parsedTime.nextTokenIndex <= toIndex else {
            return nil
        }
        let time = parsedTime.minutes
        var fromTokens = Array(parts[parsedTime.nextTokenIndex..<toIndex])
        if fromTokens.first == "from" {
            fromTokens.removeFirst()
        }
        if fromTokens.isEmpty {
            fromTokens = ["local"]
        }
        let toTokens = Array(parts[(toIndex + 1)...])

        guard let from = zone(fromTokens, localTimeZone: localTimeZone),
              let to = zone(toTokens, localTimeZone: localTimeZone) else {
            return nil
        }

        let result = time - from.minutes + to.minutes
        return UnitConversion(
            source: "\(clock(time)) \(from.label)",
            result: "\(clock(result)) \(to.label)"
        )
    }

    private static func parseTime(_ parts: [String]) -> (minutes: Int, nextTokenIndex: Int)? {
        guard !parts.isEmpty else { return nil }

        var timeToken = parts[0]
        var nextTokenIndex = 1
        if parts.count > 1,
           ["am", "pm"].contains(parts[1]),
           !(timeToken.hasSuffix("am") || timeToken.hasSuffix("pm")) {
            timeToken += parts[1]
            nextTokenIndex = 2
        }
        guard let minutes = timeMinutes(timeToken) else { return nil }
        return (minutes, nextTokenIndex)
    }

    private static func timeMinutes(_ text: String) -> Int? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
        if cleaned == "midnight" {
            return 0
        }
        if cleaned == "noon" {
            return 12 * 60
        }

        let isAM = cleaned.hasSuffix("am")
        let isPM = cleaned.hasSuffix("pm")
        let clockPart = (isAM || isPM) ? String(cleaned.dropLast(2)) : cleaned

        let pieces = clockPart.split(separator: ":", omittingEmptySubsequences: false)
        guard pieces.count == 1 || pieces.count == 2,
              let hourPart = Int(pieces[0]) else {
            return nil
        }

        let minutePart = pieces.count == 2 ? (Int(pieces[1]) ?? -1) : 0
        guard (0..<60).contains(minutePart) else { return nil }

        let hour: Int
        if isAM || isPM {
            guard (1...12).contains(hourPart) else { return nil }
            hour = (hourPart % 12) + (isPM ? 12 : 0)
        } else {
            guard (0...23).contains(hourPart) else { return nil }
            hour = hourPart
        }

        return hour * 60 + minutePart
    }

    private static func zone(_ tokens: [String], localTimeZone: TimeZone) -> (minutes: Int, label: String)? {
        for candidate in zoneCandidates(tokens) {
            if let parsed = zone(candidate, localTimeZone: localTimeZone) {
                return parsed
            }
        }
        return nil
    }

    private static func zoneCandidates(_ tokens: [String]) -> [String] {
        var candidates: [String] = []

        func append(_ value: String) {
            let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !cleaned.isEmpty,
                  !candidates.contains(cleaned) else { return }
            candidates.append(cleaned)
        }

        append(tokens.joined())
        if tokens.count > 1 {
            append(tokens.joined(separator: " "))
        }

        return candidates
    }

    private static func zone(_ text: String, localTimeZone: TimeZone) -> (minutes: Int, label: String)? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleaned == "local" || cleaned == "here" {
            let minutes = localTimeZone.secondsFromGMT() / 60
            return (minutes, "local \(zoneLabel(minutes))")
        }
        if let utcOffsetMinutes = parseUTCOffsetMinutes(cleaned) {
            return (utcOffsetMinutes, zoneLabel(utcOffsetMinutes))
        }
        let key = cleaned.filter { $0.isLetter || $0.isNumber }
        guard let minutes = zoneAliases[key] else {
            return nil
        }
        return (minutes, "\(key.uppercased()) \(zoneLabel(minutes))")
    }

    private static func parseUTCOffsetMinutes(_ text: String) -> Int? {
        if text == "utc" || text == "gmt" || text == "z" {
            return 0
        }
        var offsetText = text
        if offsetText.hasPrefix("utc") {
            offsetText.removeFirst(3)
        } else if offsetText.hasPrefix("gmt") {
            offsetText.removeFirst(3)
        }
        guard let sign = offsetText.first,
              sign == "+" || sign == "-" else {
            return nil
        }
        let value = String(offsetText.dropFirst())
        guard !value.isEmpty else { return nil }

        let hours: Int
        let minutes: Int
        if value.contains(":") {
            let parts = value.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2,
                  let parsedHours = Int(parts[0]),
                  let parsedMinutes = Int(parts[1]) else {
                return nil
            }
            hours = parsedHours
            minutes = parsedMinutes
        } else if value.count == 3 {
            guard let parsedHours = Int(value.prefix(1)),
                  let parsedMinutes = Int(value.suffix(2)) else {
                return nil
            }
            hours = parsedHours
            minutes = parsedMinutes
        } else if value.count == 4 {
            guard let parsedHours = Int(value.prefix(2)),
                  let parsedMinutes = Int(value.suffix(2)) else {
                return nil
            }
            hours = parsedHours
            minutes = parsedMinutes
        } else {
            guard let parsedHours = Int(value) else { return nil }
            hours = parsedHours
            minutes = 0
        }

        guard (0...14).contains(hours),
              (0..<60).contains(minutes),
              !(hours == 14 && minutes > 0) else {
            return nil
        }

        let totalMinutes = (hours * 60) + minutes
        return sign == "-" ? -totalMinutes : totalMinutes
    }

    private static func clock(_ minutes: Int) -> String {
        let cleanMinutes = ((minutes % 1440) + 1440) % 1440
        return String(format: "%02d:%02d", cleanMinutes / 60, cleanMinutes % 60)
    }

    private static func zoneLabel(_ minutes: Int) -> String {
        let sign = minutes < 0 ? "-" : "+"
        let absoluteMinutes = abs(minutes)
        return "UTC\(sign)\(String(format: "%02d:%02d", absoluteMinutes / 60, absoluteMinutes % 60))"
    }

    private static let zoneAliases: [String: Int] = [
        "pt": -8 * 60, "pst": -8 * 60, "pdt": -7 * 60,
        "mt": -7 * 60, "mst": -7 * 60, "mdt": -6 * 60,
        "ct": -6 * 60, "cst": -6 * 60, "cdt": -5 * 60,
        "et": -5 * 60, "est": -5 * 60, "edt": -4 * 60,
        "bst": 1 * 60, "cet": 1 * 60, "cest": 2 * 60,
        "eet": 2 * 60, "eest": 3 * 60,
        "ist": 5 * 60 + 30, "jst": 9 * 60, "kst": 9 * 60,
        "hkt": 8 * 60, "sgt": 8 * 60,
        "aest": 10 * 60, "acst": 9 * 60 + 30, "awst": 8 * 60,
        "nzst": 12 * 60
    ]

    private static func convertTemperature(_ value: Double, from source: String, to target: String) -> Double {
        let kelvin: Double
        switch source {
        case "C": kelvin = value + 273.15
        case "F": kelvin = (value + 459.67) * 5 / 9
        default: kelvin = value
        }

        switch target {
        case "C": return kelvin - 273.15
        case "F": return kelvin * 9 / 5 - 459.67
        default: return kelvin
        }
    }

    private static func format(_ value: Double) -> String {
        let cleanValue = abs(value) < 0.000_000_001 ? 0 : value
        let rounded = cleanValue.rounded()
        if abs(cleanValue - rounded) < 0.000_000_001, abs(rounded) < 9_000_000_000_000_000 {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.6g", cleanValue)
    }

    private struct Unit {
        let kind: Kind
        let rate: Double
        let symbol: String
    }

    private enum Kind {
        case length, weight, volume, temp, data, time
    }

    private static func unit(_ text: String) -> Unit? {
        if let unit = units[text] {
            return unit
        }
        if text.hasSuffix("s"), let unit = units[String(text.dropLast())] {
            return unit
        }
        if text.hasSuffix("es"), let unit = units[String(text.dropLast(2))] {
            return unit
        }
        return nil
    }

    private static let units: [String: Unit] = {
        func u(_ kind: Kind, _ rate: Double, _ symbol: String) -> Unit {
            Unit(kind: kind, rate: rate, symbol: symbol)
        }

        return [
            "mm": u(.length, 0.001, "mm"), "millimeter": u(.length, 0.001, "mm"),
            "cm": u(.length, 0.01, "cm"), "centimeter": u(.length, 0.01, "cm"),
            "m": u(.length, 1, "m"), "meter": u(.length, 1, "m"),
            "km": u(.length, 1000, "km"), "kilometer": u(.length, 1000, "km"),
            "in": u(.length, 0.0254, "in"), "inch": u(.length, 0.0254, "in"),
            "ft": u(.length, 0.3048, "ft"), "foot": u(.length, 0.3048, "ft"), "feet": u(.length, 0.3048, "ft"),
            "mi": u(.length, 1609.344, "mi"), "mile": u(.length, 1609.344, "mi"),
            "g": u(.weight, 1, "g"), "gram": u(.weight, 1, "g"),
            "kg": u(.weight, 1000, "kg"), "kilogram": u(.weight, 1000, "kg"),
            "oz": u(.weight, 28.349523125, "oz"), "ounce": u(.weight, 28.349523125, "oz"),
            "lb": u(.weight, 453.59237, "lb"), "lbs": u(.weight, 453.59237, "lb"), "pound": u(.weight, 453.59237, "lb"),
            "ml": u(.volume, 0.001, "mL"), "milliliter": u(.volume, 0.001, "mL"),
            "l": u(.volume, 1, "L"), "liter": u(.volume, 1, "L"),
            "tsp": u(.volume, 0.00492892159375, "tsp"), "teaspoon": u(.volume, 0.00492892159375, "tsp"),
            "tbsp": u(.volume, 0.01478676478125, "tbsp"), "tablespoon": u(.volume, 0.01478676478125, "tbsp"),
            "cup": u(.volume, 0.2365882365, "cup"),
            "floz": u(.volume, 0.0295735295625, "fl oz"), "fluidounce": u(.volume, 0.0295735295625, "fl oz"),
            "pt": u(.volume, 0.473176473, "pt"), "pint": u(.volume, 0.473176473, "pt"),
            "qt": u(.volume, 0.946352946, "qt"), "quart": u(.volume, 0.946352946, "qt"),
            "gal": u(.volume, 3.785411784, "gal"), "gallon": u(.volume, 3.785411784, "gal"),
            "c": u(.temp, 1, "C"), "celsius": u(.temp, 1, "C"),
            "f": u(.temp, 1, "F"), "fahrenheit": u(.temp, 1, "F"),
            "k": u(.temp, 1, "K"), "kelvin": u(.temp, 1, "K"),
            "byte": u(.data, 1, "B"),
            "kb": u(.data, 1000, "KB"), "mb": u(.data, 1_000_000, "MB"), "gb": u(.data, 1_000_000_000, "GB"),
            "s": u(.time, 1, "s"), "sec": u(.time, 1, "s"), "second": u(.time, 1, "s"),
            "min": u(.time, 60, "min"), "minute": u(.time, 60, "min"),
            "h": u(.time, 3600, "h"), "hr": u(.time, 3600, "h"), "hour": u(.time, 3600, "h"),
            "day": u(.time, 86_400, "day")
        ]
    }()
}
