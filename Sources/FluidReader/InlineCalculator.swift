import Foundation

enum InlineCalculator {
    static func makeAction(
        query: String,
        copyResult: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        guard let calculation = CalculatorExpression.evaluate(query) else { return nil }

        return CommandPaletteAction(
            id: "inline-calculator",
            title: "Calculate: \(calculation.result)",
            subtitle: "\(calculation.expression) = \(calculation.result)",
            systemImage: "function",
            keywords: [calculation.expression, calculation.result],
            canFavorite: false
        ) {
            copyResult(calculation.result)
        }
    }
}

struct CalculatorExpression: Equatable {
    let expression: String
    let result: String

    private static let queryReplacements: [(String, String)] = [
        ("sqrt", "√"),
        ("net burn multiple", "burnmultiple"),
        ("burn-multiple", "burnmultiple"),
        ("burn multiple", "burnmultiple"),
        ("break-even", "breakeven"),
        ("break even", "breakeven"),
        ("gross margin", "margin"),
        ("customer acquisition cost", "cac"),
        ("lifetime value", "ltv"),
        ("life time value", "ltv"),
        ("ltv/cac", "ltvcac"),
        ("ltv cac", "ltvcac"),
        ("net revenue retention", "nrr"),
        ("net dollar retention", "nrr"),
        ("net retention", "nrr"),
        ("quick ratio", "quickratio"),
        ("magic number", "magicnumber"),
        ("rule of 40", "rule40"),
        ("rule of forty", "rule40"),
        ("rule 40", "rule40"),
        ("cac payback", "payback"),
        ("payback period", "payback"),
        ("runway months", "runway")
    ]

    static func evaluate(_ query: String) -> CalculatorExpression? {
        let cleaned = cleanQuery(query)
        guard !cleaned.isEmpty else { return nil }
        if let conversational = evaluateConversational(cleaned) {
            return conversational
        }
        guard shouldTry(cleaned) else { return nil }

        let expression = cleaned.hasPrefix("=")
            ? String(cleaned.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            : cleaned
        guard !expression.isEmpty else { return nil }

        var parser = CalculatorParser(expression)
        guard let value = parser.parse(), let result = format(value) else { return nil }
        return CalculatorExpression(expression: expression, result: result)
    }

    private static func cleanQuery(_ query: String) -> String {
        var normalized = InlineQueryNormalizer.normalize(
            query,
            prefixes: [
                "what is ",
                "calculate ",
                "calc "
            ]
        )
            .replacingOccurrences(of: ",", with: "")

        for (pattern, replacement) in queryReplacements {
            normalized = normalized.replacingOccurrences(of: pattern, with: replacement)
        }

        return normalized
    }

    private static func evaluateConversational(_ query: String) -> CalculatorExpression? {
        let tokens = query.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return nil }
        if let businessFormula = evaluateBusinessFormula(tokens, query: query) {
            return businessFormula
        }
        return evaluatePercentOf(tokens, query: query)
    }

    private static func evaluateBusinessFormula(
        _ tokens: [String],
        query: String
    ) -> CalculatorExpression? {
        guard let keyword = tokens.first else { return nil }

        switch keyword {
        case "roi":
            guard tokens.count == 3,
                  let total = Double(tokens[1]),
                  let cost = Double(tokens[2]),
                  cost != 0 else { return nil }
            return conversationalPercentExpression(expression: query, ratio: (total - cost) / cost)
        case "margin":
            guard tokens.count == 3,
                  let revenue = Double(tokens[1]),
                  let cost = Double(tokens[2]),
                  revenue != 0 else { return nil }
            return conversationalPercentExpression(expression: query, ratio: (revenue - cost) / revenue)
        case "markup":
            guard tokens.count == 3,
                  let sellPrice = Double(tokens[1]),
                  let cost = Double(tokens[2]),
                  cost != 0 else { return nil }
            return conversationalPercentExpression(expression: query, ratio: (sellPrice - cost) / cost)
        case "cagr":
            guard tokens.count == 4,
                  let start = Double(tokens[1]),
                  let end = Double(tokens[2]),
                  let years = Double(tokens[3]),
                  start > 0,
                  end >= 0,
                  years > 0 else { return nil }
            return conversationalPercentExpression(expression: query, ratio: pow(end / start, 1 / years) - 1)
        case "breakeven":
            guard tokens.count == 4,
                  let fixedCost = Double(tokens[1]),
                  let pricePerUnit = Double(tokens[2]),
                  let variableCostPerUnit = Double(tokens[3]) else { return nil }
            let contributionPerUnit = pricePerUnit - variableCostPerUnit
            guard fixedCost >= 0,
                  contributionPerUnit > 0 else { return nil }
            return conversationalExpression(expression: query, value: fixedCost / contributionPerUnit)
        case "ltv":
            guard tokens.count == 3,
                  let monthlyContribution = Double(tokens[1]),
                  let lifetimeMonths = Double(tokens[2]),
                  monthlyContribution >= 0,
                  lifetimeMonths >= 0 else { return nil }
            return conversationalExpression(expression: query, value: monthlyContribution * lifetimeMonths)
        case "cac":
            guard tokens.count == 3,
                  let spend = Double(tokens[1]),
                  let customers = Double(tokens[2]),
                  spend >= 0,
                  customers > 0 else { return nil }
            return conversationalExpression(expression: query, value: spend / customers)
        case "runway":
            guard tokens.count == 3,
                  let cash = Double(tokens[1]),
                  let monthlyBurn = Double(tokens[2]),
                  cash >= 0,
                  monthlyBurn > 0 else { return nil }
            return conversationalExpression(expression: query, value: cash / monthlyBurn)
        case "payback":
            guard tokens.count == 3,
                  let customerAcquisitionCost = Double(tokens[1]),
                  let monthlyContribution = Double(tokens[2]),
                  customerAcquisitionCost >= 0,
                  monthlyContribution > 0 else { return nil }
            return conversationalExpression(
                expression: query,
                value: customerAcquisitionCost / monthlyContribution
            )
        case "ltvcac":
            guard tokens.count == 3,
                  let lifetimeValue = Double(tokens[1]),
                  let customerAcquisitionCost = Double(tokens[2]),
                  lifetimeValue >= 0,
                  customerAcquisitionCost > 0 else { return nil }
            return conversationalExpression(
                expression: query,
                value: lifetimeValue / customerAcquisitionCost
            )
        case "burnmultiple":
            guard tokens.count == 3,
                  let netBurn = Double(tokens[1]),
                  let netNewARR = Double(tokens[2]),
                  netBurn >= 0,
                  netNewARR > 0 else { return nil }
            return conversationalExpression(expression: query, value: netBurn / netNewARR)
        case "nrr":
            guard tokens.count == 5,
                  let startingRevenue = Double(tokens[1]),
                  let expansionRevenue = Double(tokens[2]),
                  let contractionRevenue = Double(tokens[3]),
                  let churnRevenue = Double(tokens[4]),
                  startingRevenue > 0,
                  expansionRevenue >= 0,
                  contractionRevenue >= 0,
                  churnRevenue >= 0 else { return nil }
            return conversationalPercentExpression(
                expression: query,
                ratio: (startingRevenue + expansionRevenue - contractionRevenue - churnRevenue) / startingRevenue
            )
        case "quickratio":
            guard tokens.count == 5,
                  let newRevenue = Double(tokens[1]),
                  let expansionRevenue = Double(tokens[2]),
                  let churnRevenue = Double(tokens[3]),
                  let contractionRevenue = Double(tokens[4]),
                  newRevenue >= 0,
                  expansionRevenue >= 0,
                  churnRevenue >= 0,
                  contractionRevenue >= 0 else { return nil }
            let denominator = churnRevenue + contractionRevenue
            guard denominator > 0 else { return nil }
            return conversationalExpression(
                expression: query,
                value: (newRevenue + expansionRevenue) / denominator
            )
        case "magicnumber":
            guard tokens.count == 3,
                  let netNewARR = Double(tokens[1]),
                  let salesAndMarketingSpend = Double(tokens[2]),
                  netNewARR >= 0,
                  salesAndMarketingSpend > 0 else { return nil }
            // Magic number = net new ARR / S&M spend. ARR is already
            // annualized, so no x4 multiplier (that applies only when
            // annualizing quarterly net-new revenue).
            return conversationalExpression(
                expression: query,
                value: netNewARR / salesAndMarketingSpend
            )
        case "rule40":
            guard tokens.count == 3,
                  let growthPercent = Double(tokens[1]),
                  let marginPercent = Double(tokens[2]) else { return nil }
            return conversationalPercentExpression(
                expression: query,
                ratio: (growthPercent + marginPercent) / 100
            )
        default:
            return nil
        }
    }

    private static func evaluatePercentOf(
        _ tokens: [String],
        query: String
    ) -> CalculatorExpression? {
        if tokens.count == 3,
           let percent = percentValue(tokens[0]),
           tokens[1] == "of",
           let base = Double(tokens[2]) {
            return conversationalExpression(
                expression: query,
                value: base * percent / 100
            )
        }
        return nil
    }

    private static func conversationalExpression(
        expression: String,
        value: Double
    ) -> CalculatorExpression? {
        guard let result = format(value) else { return nil }
        return CalculatorExpression(expression: expression, result: result)
    }

    private static func conversationalPercentExpression(
        expression: String,
        ratio: Double
    ) -> CalculatorExpression? {
        guard let percent = format(ratio * 100) else { return nil }
        return CalculatorExpression(expression: expression, result: "\(percent)%")
    }

    private static func percentValue(_ token: String) -> Double? {
        guard token.hasSuffix("%"),
              let value = Double(token.dropLast()),
              value >= 0 else {
            return nil
        }
        return value
    }

    private static func shouldTry(_ query: String) -> Bool {
        if query.hasPrefix("=") {
            return true
        }

        let hasDigit = query.contains { $0.isNumber }
        let hasOperator = query.contains { "+-*/%×÷^()√".contains($0) }
        let lowercased = query.lowercased()
        return hasDigit && hasOperator
            || lowercased.contains("pi")
            || lowercased.contains("sqrt")
            || query.contains("π")
    }

    private static func format(_ value: Double) -> String? {
        guard value.isFinite else { return nil }

        let normalizedValue = abs(value) < 0.000_000_000_001 ? 0 : value
        let roundedValue = normalizedValue.rounded()
        if abs(normalizedValue - roundedValue) < 0.000_000_000_001,
           abs(roundedValue) < 9_000_000_000_000_000 {
            return String(format: "%.0f", roundedValue)
        }

        return String(format: "%.12g", normalizedValue)
    }
}

private struct CalculatorParser {
    private let characters: [Character]
    private var index = 0

    init(_ expression: String) {
        characters = Array(expression)
    }

    mutating func parse() -> Double? {
        guard let value = parseExpression() else { return nil }
        skipSpaces()
        guard index == characters.count else { return nil }
        return value
    }

    private mutating func parseExpression() -> Double? {
        guard var value = parseTerm() else { return nil }

        while true {
            if match("+") {
                guard let rhs = parseTerm() else { return nil }
                value += rhs
            } else if match("-") {
                guard let rhs = parseTerm() else { return nil }
                value -= rhs
            } else {
                return value
            }
        }
    }

    private mutating func parseTerm() -> Double? {
        guard var value = parsePower() else { return nil }

        while true {
            if match("*") || match("×") || match("x") || match("X") {
                guard let rhs = parsePower() else { return nil }
                value *= rhs
            } else if match("/") || match("÷") {
                guard let rhs = parsePower(), rhs != 0 else { return nil }
                value /= rhs
            } else if match("%") {
                guard let rhs = parsePower(), rhs != 0 else { return nil }
                value = value.truncatingRemainder(dividingBy: rhs)
            } else {
                return value
            }
        }
    }

    private mutating func parsePower() -> Double? {
        guard var value = parseUnary() else { return nil }

        if match("^") {
            guard let rhs = parsePower() else { return nil }
            value = pow(value, rhs)
        }

        return value
    }

    private mutating func parseUnary() -> Double? {
        if match("+") {
            return parseUnary()
        }
        if match("-") {
            guard let value = parseUnary() else { return nil }
            return -value
        }
        return parsePrimary()
    }

    private mutating func parsePrimary() -> Double? {
        if match("√") {
            guard let value = parsePrimary(), value >= 0 else { return nil }
            return sqrt(value)
        }

        if match("(") {
            guard let value = parseExpression(), match(")") else { return nil }
            return value
        }

        if match("π") {
            return Double.pi
        }
        if match("p") {
            guard match("i") else { return nil }
            return Double.pi
        }

        return parseNumber()
    }

    private mutating func parseNumber() -> Double? {
        skipSpaces()

        let start = index
        var hasDigit = false
        var hasDecimalPoint = false

        while index < characters.count {
            let character = characters[index]
            if character.isNumber {
                hasDigit = true
                index += 1
            } else if character == ".", !hasDecimalPoint {
                hasDecimalPoint = true
                index += 1
            } else {
                break
            }
        }

        guard hasDigit else { return nil }
        return Double(String(characters[start..<index]))
    }

    private mutating func match(_ character: Character) -> Bool {
        skipSpaces()
        guard index < characters.count, characters[index] == character else { return false }
        index += 1
        return true
    }

    private mutating func skipSpaces() {
        while index < characters.count, characters[index].isWhitespace {
            index += 1
        }
    }
}
