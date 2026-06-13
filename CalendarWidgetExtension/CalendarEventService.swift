import Foundation
import EventKit

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: String
}

final class CalendarEventService {
    private let eventStore = EKEventStore()

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    var hasAccess: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        return status == .fullAccess
    }

    func fetchEvents(for month: Date) -> [CalendarEvent] {
        guard hasAccess else { return [] }

        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfMonth, end: endOfMonth, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)

        return ekEvents.map { event in
            CalendarEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Untitled",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                calendarColor: event.calendar.cgColor.components?.isEmpty == false
                    ? "#\(String(format: "%02X%02X%02X", Int((event.calendar.cgColor.components?[0] ?? 0) * 255), Int((event.calendar.cgColor.components?[1] ?? 0) * 255), Int((event.calendar.cgColor.components?[2] ?? 0) * 255)))"
                    : "#007AFF"
            )
        }
    }

    func eventDays(for month: Date) -> Set<Int> {
        let calendar = Calendar.current
        let events = fetchEvents(for: month)
        var days = Set<Int>()
        for event in events {
            let day = calendar.component(.day, from: event.startDate)
            days.insert(day)
        }
        return days
    }
}
