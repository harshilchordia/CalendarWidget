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

struct ShowMoreEventsIntent: AppIntent {
    static var title: LocalizedStringResource = "Show More Events"
    static var description = IntentDescription("Page through events in a day cell.")

    @Parameter(title: "Date Key")
    var dateKey: String

    @Parameter(title: "Total Events")
    var totalEvents: Int

    @Parameter(title: "Page Size")
    var pageSize: Int

    init() {
        self.dateKey = ""
        self.totalEvents = 0
        self.pageSize = 3
    }

    init(dateKey: String, totalEvents: Int, pageSize: Int) {
        self.dateKey = dateKey
        self.totalEvents = totalEvents
        self.pageSize = pageSize
    }

    func perform() async throws -> some IntentResult {
        let currentPage = MonthOffsetStore.eventPage(for: dateKey)
        let maxPage = max(0, (totalEvents - 1) / pageSize)
        let nextPage = (currentPage + 1) > maxPage ? 0 : currentPage + 1
        MonthOffsetStore.setEventPage(nextPage, for: dateKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        return .result()
    }
}

enum MonthOffsetStore {
    private static let key = "calendarWidgetWeekOffset"
    private static let pagesKey = "calendarWidgetEventPages"

    static var currentOffset: Int {
        get { UserDefaults.standard.integer(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static func eventPage(for dateKey: String) -> Int {
        let pages = UserDefaults.standard.dictionary(forKey: pagesKey) as? [String: Int] ?? [:]
        return pages[dateKey] ?? 0
    }

    static func setEventPage(_ page: Int, for dateKey: String) {
        var pages = UserDefaults.standard.dictionary(forKey: pagesKey) as? [String: Int] ?? [:]
        if page == 0 {
            pages.removeValue(forKey: dateKey)
        } else {
            pages[dateKey] = page
        }
        UserDefaults.standard.set(pages, forKey: pagesKey)
    }

    static var allEventPages: [String: Int] {
        UserDefaults.standard.dictionary(forKey: pagesKey) as? [String: Int] ?? [:]
    }
}
