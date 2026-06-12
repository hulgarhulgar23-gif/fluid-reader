import Foundation

enum InlineColorConverter {
    static func makeAction(
        query: String,
        copyResult: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        guard let color = ColorConversion.parse(query) else { return nil }

        return CommandPaletteAction(
            id: "inline-color-converter",
            title: "Color: \(color.hex)",
            subtitle: "\(color.rgb) | \(color.hsl)",
            systemImage: "paintpalette",
            keywords: [query, color.hex, color.rgb, color.hsl],
            canFavorite: false
        ) {
            copyResult(color.summary)
        }
    }
}

struct ColorConversion: Equatable {
    let red: Int
    let green: Int
    let blue: Int

    var hex: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }

    var rgb: String {
        "rgb(\(red), \(green), \(blue))"
    }

    var hsl: String {
        let r = Double(red) / 255
        let g = Double(green) / 255
        let b = Double(blue) / 255
        let maxValue = max(r, g, b)
        let minValue = min(r, g, b)
        let lightness = (maxValue + minValue) / 2
        let delta = maxValue - minValue
        let hue: Double
        let saturation: Double

        if delta == 0 {
            hue = 0
            saturation = 0
        } else {
            saturation = delta / (lightness > 0.5 ? 2 - maxValue - minValue : maxValue + minValue)
            if maxValue == r {
                hue = ((g - b) / delta + (g < b ? 6 : 0)) * 60
            } else if maxValue == g {
                hue = ((b - r) / delta + 2) * 60
            } else {
                hue = ((r - g) / delta + 4) * 60
            }
        }

        return "hsl(\(Int(hue.rounded())), \(Int((saturation * 100).rounded()))%, \(Int((lightness * 100).rounded()))%)"
    }

    var summary: String {
        "\(hex)\n\(rgb)\n\(hsl)"
    }

    static func parse(_ query: String) -> ColorConversion? {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return nil }

        if clean.hasPrefix("#") {
            return parseHex(String(clean.dropFirst()))
        }
        if clean.hasPrefix("hex ") {
            return parseHex(String(clean.dropFirst(4)))
        }
        if clean.hasPrefix("color ") {
            return parse(String(clean.dropFirst(6)))
        }
        if clean.hasPrefix("rgb") {
            return parseRGB(clean)
        }
        if clean.hasPrefix("hsl") {
            return parseHSL(clean)
        }
        return nil
    }

    private static func parseHex(_ text: String) -> ColorConversion? {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits: String
        if clean.count == 3 {
            digits = clean.map { "\($0)\($0)" }.joined()
        } else if clean.count == 6 {
            digits = clean
        } else {
            return nil
        }
        guard digits.allSatisfy(\.isHexDigit),
              let value = Int(digits, radix: 16) else {
            return nil
        }
        return ColorConversion(red: (value >> 16) & 255, green: (value >> 8) & 255, blue: value & 255)
    }

    private static func parseRGB(_ text: String) -> ColorConversion? {
        let values = text
            .split { !$0.isNumber }
            .compactMap { Int($0) }
        guard values.count == 3, values.allSatisfy({ (0...255).contains($0) }) else {
            return nil
        }
        return ColorConversion(red: values[0], green: values[1], blue: values[2])
    }

    private static func parseHSL(_ text: String) -> ColorConversion? {
        let values = text
            .split { !$0.isNumber }
            .compactMap { Int($0) }
        guard values.count == 3,
              (0...360).contains(values[0]),
              (0...100).contains(values[1]),
              (0...100).contains(values[2]) else {
            return nil
        }

        let hue = Double(values[0] % 360) / 360
        let saturation = Double(values[1]) / 100
        let lightness = Double(values[2]) / 100
        guard saturation > 0 else {
            let gray = colorByte(lightness)
            return ColorConversion(red: gray, green: gray, blue: gray)
        }

        let q = lightness < 0.5
            ? lightness * (1 + saturation)
            : lightness + saturation - lightness * saturation
        let p = 2 * lightness - q
        return ColorConversion(
            red: colorByte(hueValue(p, q, hue + 1 / 3)),
            green: colorByte(hueValue(p, q, hue)),
            blue: colorByte(hueValue(p, q, hue - 1 / 3))
        )
    }

    private static func hueValue(_ p: Double, _ q: Double, _ value: Double) -> Double {
        var t = value
        if t < 0 { t += 1 }
        if t > 1 { t -= 1 }
        if t < 1 / 6 { return p + (q - p) * 6 * t }
        if t < 1 / 2 { return q }
        if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
        return p
    }

    private static func colorByte(_ value: Double) -> Int {
        Int((value * 255).rounded())
    }
}
