import XCTest

final class TimeOfDayTests: XCTestCase {

    // MARK: - Helpers

    private func date(month: Int, day: Int = 15, hour: Int, minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        return Calendar.current.date(from: comps)!
    }

    // MARK: - Basic daylight values

    func testMidday_isFullDaylight() {
        XCTAssertEqual(TimeOfDay.daylight(at: date(month: 4, hour: 12)), 1.0)
    }

    func testMidnight_isDeepNight() {
        XCTAssertLessThanOrEqual(TimeOfDay.daylight(at: date(month: 4, hour: 0)), 0.15)
    }

    func testApril7PM_isStillFullDay() {
        // April sunset ~7:53 PM (19.88h) -- 7pm must still be full daylight
        XCTAssertEqual(TimeOfDay.daylight(at: date(month: 4, hour: 19)), 1.0)
    }

    func testApril10PM_isPastTransition() {
        // 10pm is past set(19.88) + transition(1.25) = 21.13 -> deep night
        XCTAssertEqual(TimeOfDay.daylight(at: date(month: 4, hour: 22)), 0.15)
    }

    func testAllMonths_noonIsFullDaylight() {
        for month in 1...12 {
            XCTAssertEqual(
                TimeOfDay.daylight(at: date(month: month, hour: 12)),
                1.0,
                "Month \(month): noon should be full daylight"
            )
        }
    }

    // MARK: - isNight consistency with daylight

    func testIsNight_falseAtNoon() {
        XCTAssertFalse(TimeOfDay.isNight(at: date(month: 4, hour: 12)))
    }

    func testIsNight_trueAtMidnight() {
        XCTAssertTrue(TimeOfDay.isNight(at: date(month: 4, hour: 0)))
    }

    func testIsNight_matchesDaylightThreshold() {
        // isNight must agree with daylight < 0.4 at every hour of the day
        for hour in 0..<24 {
            let d = date(month: 4, hour: hour)
            XCTAssertEqual(
                TimeOfDay.isNight(at: d),
                TimeOfDay.daylight(at: d) < 0.4,
                "isNight and daylight disagree at hour \(hour)"
            )
        }
    }

    // MARK: - Regression: 12-hour vs 24-hour sunset times

    func testAllMonths_sunsetIsAfterNoon() {
        // If sunset times ever revert to 12-hour format (e.g. 7.88 instead of 19.88),
        // this test catches it immediately.
        for month in 1...12 {
            XCTAssertGreaterThan(
                TimeOfDay.sunsets[month],
                12.0,
                "Month \(month): sunset (\(TimeOfDay.sunsets[month])h) must be stored in 24-hour time"
            )
        }
    }

    func testAllMonths_sunriseBeforeSunset() {
        for month in 1...12 {
            XCTAssertLessThan(
                TimeOfDay.sunrises[month],
                TimeOfDay.sunsets[month],
                "Month \(month): sunrise must precede sunset"
            )
        }
    }
}
