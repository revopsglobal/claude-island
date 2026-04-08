import Foundation

/// Time-of-day calculations for Ridgefield, WA (98642, ~45.8°N).
/// All functions accept an injectable `Date` (defaults to `Date()`) so they
/// are pure and unit-testable without waiting for a specific time of day.
enum TimeOfDay {

    // Monthly sunrise/sunset in 24-hour local time (DST-adjusted).
    // Index 0 unused; indices 1-12 correspond to calendar months.
    static let sunrises: [Double] = [0, 7.78, 7.22, 6.37, 6.52, 5.78, 5.27, 5.45, 5.95, 6.58, 7.20, 6.87, 7.72]
    static let sunsets:  [Double] = [0, 16.53, 17.32, 19.07, 19.88, 20.40, 20.92, 20.83, 20.25, 19.33, 18.00, 16.70, 16.25]
    static let transitionHours: Double = 1.25 // 75-minute dawn/dusk ramp

    /// Returns a brightness factor: 0.15 (deep night) to 1.0 (full daylight).
    static func daylight(at date: Date = Date()) -> Double {
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: date))
        let m = Double(cal.component(.minute, from: date))
        let hour = h + m / 60.0
        let month = cal.component(.month, from: date)

        let rise = sunrises[month]
        let set  = sunsets[month]

        if hour < rise - transitionHours || hour > set + transitionHours {
            return 0.15
        } else if hour < rise {
            return 0.15 + (hour - (rise - transitionHours)) / transitionHours * 0.85
        } else if hour <= set {
            return 1.0
        } else {
            return max(0.15, 1.0 - (hour - set) / transitionHours * 0.85)
        }
    }

    /// Returns true when the scene should render as nighttime (daylight < 0.4).
    static func isNight(at date: Date = Date()) -> Bool {
        return daylight(at: date) < 0.4
    }
}
