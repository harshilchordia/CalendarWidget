import WidgetKit
import SwiftUI

struct CalendarEntry: TimelineEntry {
    let date: Date
    let monthDate: Date
    let eventDays: Set<Int>
    let eventsByDay: [Int: [SimpleEvent]]
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
        CalendarEntry(
            date: Date(),
            monthDate: Date(),
            eventDays: [3, 7, 12, 15, 20, 25],
            eventsByDay: [
                12: [SimpleEvent(id: "1", title: "BACA CHESS SOCIAL", startDate: Date(), isAllDay: false),
                     SimpleEvent(id: "2", title: "Thank F*** It's Friday", startDate: Date(), isAllDay: false)],
                13: [SimpleEvent(id: "3", title: "tag in regents park", startDate: Date(), isAllDay: false)]
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
        let monthOffset = MonthOffsetStore.currentOffset
        let displayDate = calendar.date(byAdding: .month, value: monthOffset, to: currentDate) ?? currentDate

        let entry = createEntry(for: displayDate)

        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)

        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }

    private func createEntry(for date: Date) -> CalendarEntry {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)

        let events = eventService.fetchEvents(for: date)

        // Build events grouped by day
        var eventsByDay: [Int: [SimpleEvent]] = [:]
        var eventDays = Set<Int>()

        for event in events {
            let day = calendar.component(.day, from: event.startDate)
            eventDays.insert(day)
            let simpleEvent = SimpleEvent(id: event.id, title: event.title, startDate: event.startDate, isAllDay: event.isAllDay)
            eventsByDay[day, default: []].append(simpleEvent)
        }

        // Sort events within each day
        for (day, dayEvents) in eventsByDay {
            eventsByDay[day] = dayEvents.sorted { $0.startDate < $1.startDate }
        }

        let upcoming = events
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
