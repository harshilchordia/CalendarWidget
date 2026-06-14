import WidgetKit
import SwiftUI

struct CalendarWidgetEntryView: View {
    var entry: CalendarProvider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .systemLarge:
            largeWidget
        case .systemExtraLarge:
            extraLargeWidget
        default:
            mediumWidget
        }
    }

    private var smallWidget: some View {
        VStack(spacing: 4) {
            CalendarMonthView(currentDate: entry.monthDate, eventDays: entry.eventDays)
        }
        .padding(8)
    }

    private var mediumWidget: some View {
        HStack(spacing: 12) {
            CalendarMonthView(currentDate: entry.monthDate, eventDays: entry.eventDays)
                .frame(maxWidth: .infinity)

            Divider()

            eventsList
                .frame(maxWidth: .infinity)
        }
        .padding(12)
    }

    private var largeWidget: some View {
        CalendarFullMonthView(
            currentDate: entry.monthDate,
            eventsByDay: entry.eventsByDay,
            compact: false
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 12)
    }

    private var extraLargeWidget: some View {
        CalendarFullMonthView(
            currentDate: entry.monthDate,
            eventsByDay: entry.eventsByDay,
            compact: false
        )
        .padding(.horizontal, 1)
        .padding(.vertical, 6)
    }

    private var eventsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            if entry.upcomingEvents.isEmpty {
                Text("No upcoming events")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                ForEach(entry.upcomingEvents.prefix(3)) { event in
                    eventRow(event)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func eventRow(_ event: SimpleEvent) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentColor)
                .frame(width: 3, height: 14)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)

                Text(eventTimeString(event))
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func eventTimeString(_ event: SimpleEvent) -> String {
        if event.isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
}

@main
struct CalendarWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        CalendarMonthWidget()
    }
}

struct CalendarMonthWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Calendar")
        .description("View your month at a glance with upcoming events.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge]
        if #available(macOS 15.0, *) {
            families.append(.systemExtraLarge)
        }
        return families
    }
}

#Preview(as: .systemLarge) {
    CalendarMonthWidget()
} timeline: {
    CalendarEntry(
        date: Date(),
        monthDate: Date(),
        eventDays: [3, 7, 12, 15, 20, 25],
        eventsByDay: [
            12: [SimpleEvent(id: "1", title: "BACA CHESS SOCIAL", startDate: Date(), isAllDay: false),
                 SimpleEvent(id: "2", title: "Thank F*** It's Friday", startDate: Date(), isAllDay: false)],
            13: [SimpleEvent(id: "3", title: "tag in regents park", startDate: Date(), isAllDay: false),
                 SimpleEvent(id: "4", title: "picnic @ greenwich", startDate: Date().addingTimeInterval(7200), isAllDay: false)]
        ],
        upcomingEvents: [
            SimpleEvent(id: "1", title: "BACA CHESS SOCIAL", startDate: Date(), isAllDay: false),
            SimpleEvent(id: "2", title: "Thank F*** It's Friday", startDate: Date().addingTimeInterval(3600), isAllDay: false),
            SimpleEvent(id: "3", title: "tag in regents park", startDate: Date().addingTimeInterval(7200), isAllDay: false)
        ]
    )
}
