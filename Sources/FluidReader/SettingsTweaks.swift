import Foundation

enum SettingsTweaks {
    static let speechRateRange: ClosedRange<Double> = 0.30...0.65
    static let speechRateStep = 0.05

    static func slowerSpeechRate(from rate: Double) -> Double {
        steppedSpeechRate(from: rate, delta: -speechRateStep)
    }

    static func fasterSpeechRate(from rate: Double) -> Double {
        steppedSpeechRate(from: rate, delta: speechRateStep)
    }

    static func speechRateLabel(_ rate: Double) -> String {
        String(format: "%.2f", rate)
    }

    private static func steppedSpeechRate(from rate: Double, delta: Double) -> Double {
        let stepped = rate + delta
        let clamped = min(max(stepped, speechRateRange.lowerBound), speechRateRange.upperBound)
        return (clamped * 100).rounded() / 100
    }
}
