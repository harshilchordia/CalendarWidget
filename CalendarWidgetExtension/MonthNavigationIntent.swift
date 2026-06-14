import AppIntents
import WidgetKit

struct ChangeMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "Change Week"
    static var description = IntentDescription("Navigate by week in the calendar widget.")

    @Parameter(title: "Week Offset")
    var offset: Int

    init() {
        self.offset = 0
    }

    init(offset: Int) {
        self.offset = offset
    }

    func perform() async throws -> some IntentResult {
        let current = MonthOffsetStore.currentOffset
        MonthOffsetStore.currentOffset = current + offset
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        return .result()
    }
}

struct ResetMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset to Today"
    static var description = IntentDescription("Return to today in the calendar widget.")

    func perform() async throws -> some IntentResult {
        MonthOffsetStore.currentOffset = 0
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        return .result()
    }
}

enum MonthOffsetStore {
    private static let key = "calendarWidgetWeekOffset"

    static var currentOffset: Int {
        get { UserDefaults.standard.integer(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
