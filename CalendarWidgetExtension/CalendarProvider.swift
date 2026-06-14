import WidgetKit
import SwiftUI

struct CalendarEntry: TimelineEntry {
    let date: Date
    let monthDate: Date
    let eventDays: Set<Int>
    let eventsByDay: [String: [SimpleEvent]]
    let upcomingEvents: [SimpleEvent]
}

struct SimpleEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let isAllDay: Bool

    var shortTime: String {
        if isAllDay { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: startDate).lowercased()
    }
}

struct CalendarProvider: TimelineProvider {
    private let eventService = CalendarEventService()

    func placeholder(in context: Context) -> CalendarEntry {
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = keyFormatter.string(from: Date())
        return CalendarEntry(
            date: Date(),
            monthDate: Date(),
            eventDays: [3, 7, 12, 15, 20, 25],
            eventsByDay: [
                todayKey: [SimpleEvent(id: "1", title: "BACA CHESS SOCIAL", startDate: Date(), isAllDay: false),
                     SimpleEvent(id: "2", title: "Thank F*** It's Friday", startDate: Date(), isAllDay: false)]
            ],
            upcomingEvents: [
                SimpleEvent(id: "1", title: "BACA CHESS SOCIAL", startDate: Date(), isAllDay: false),
                SimpleEvent(id: "2", title: "Thank F*** It's Friday", startDate: Date(), isAllDay: false)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        let entry = createEntry(for: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        let currentDate = Date()
        let calendar = Calendar.current
        let weekOffset = MonthOffsetStore.currentOffset
        let startDay = calendar.date(byAdding: .day, value: weekOffset * 7, to: currentDate) ?? currentDate

        let entry = createEntry(for: startDay)

        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)

        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func createEntry(for date: Date) -> CalendarEntry {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)

        // Fetch events for the month of the start date
        var allEvents = eventService.fetchEvents(for: date)

        // Also fetch next month's events to cover the 21-day window
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) {
            allEvents += eventService.fetchEvents(for: nextMonth)
        }

        // Build events grouped by date string key
        var eventsByDay: [String: [SimpleEvent]] = [:]
        var eventDays = Set<Int>()
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"

        for event in allEvents {
            let day = calendar.component(.day, from: event.startDate)
            eventDays.insert(day)
            let key = keyFormatter.string(from: event.startDate)
            let simpleEvent = SimpleEvent(id: event.id, title: event.title, startDate: event.startDate, isAllDay: event.isAllDay)
            eventsByDay[key, default: []].append(simpleEvent)
        }

        // Sort events within each day
        for (key, dayEvents) in eventsByDay {
            eventsByDay[key] = dayEvents.sorted { $0.startDate < $1.startDate }
        }

        let upcoming = allEvents
            .filter { $0.endDate >= startOfToday }
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
            .map { SimpleEvent(id: $0.id, title: $0.title, startDate: $0.startDate, isAllDay: $0.isAllDay) }

        return CalendarEntry(
            date: date,
            monthDate: date,
            eventDays: eventDays,
            eventsByDay: eventsByDay,
            upcomingEvents: Array(upcoming)
        )
    }
}
