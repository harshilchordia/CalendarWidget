import SwiftUI

// MARK: - Compact month view (small/medium widget - dots only)
struct CalendarMonthView: View {
    let currentDate: Date
    let eventDays: Set<Int>

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        VStack(spacing: 4) {
            headerView
            weekdayHeaderView
            daysGridView
        }
    }

    private var headerView: some View {
        HStack {
            Button(intent: ChangeMonthIntent(offset: -1)) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthYearString)
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            Button(intent: ChangeMonthIntent(offset: 1)) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeaderView: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGridView: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(daysInMonth, id: \.self) { dayItem in
                dayCell(for: dayItem)
            }
        }
    }

    @ViewBuilder
    private func dayCell(for dayItem: DayItem) -> some View {
        if dayItem.day == 0 {
            Text("")
                .frame(width: 18, height: 18)
        } else {
            ZStack {
                if dayItem.isToday {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 18, height: 18)
                }

                Text("\(dayItem.day)")
                    .font(.system(size: 10, weight: dayItem.isToday ? .bold : .regular))
                    .foregroundColor(dayItem.isToday ? .white : .primary)

                if eventDays.contains(dayItem.day) && !dayItem.isToday {
                    Circle()
                        .fill(Color.accentColor.opacity(0.8))
                        .frame(width: 4, height: 4)
                        .offset(y: 8)
                }
            }
            .frame(width: 18, height: 18)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private var daysInMonth: [DayItem] {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        let today = calendar.component(.day, from: Date())
        let isCurrentMonth = calendar.isDate(currentDate, equalTo: Date(), toGranularity: .month)

        var items: [DayItem] = []

        for _ in 0..<offsetDays {
            items.append(DayItem(day: 0, isToday: false))
        }

        for day in range {
            items.append(DayItem(day: day, isToday: isCurrentMonth && day == today))
        }

        return items
    }
}

// MARK: - Full month grid with inline events (large/extra-large widget)
struct CalendarFullMonthView: View {
    let currentDate: Date
    let eventsByDay: [Int: [SimpleEvent]]
    var compact: Bool = false

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    // Colors matching Apple Calendar dark theme
    private let todayColor = Color.red
    private let eventCardColor = Color(red: 0.2, green: 0.5, blue: 0.9)
    private let gridLineColor = Color.white.opacity(0.1)

    private var headerSize: CGFloat { compact ? 14 : 16 }
    private var weekdaySize: CGFloat { compact ? 9 : 10 }
    private var dayNumberSize: CGFloat { compact ? 11 : 11 }
    private var todayCircleSize: CGFloat { compact ? 18 : 20 }
    private var eventTitleSize: CGFloat { compact ? 8 : 9 }
    private var eventTimeSize: CGFloat { compact ? 7 : 8 }
    private var maxEventsPerCell: Int { compact ? 2 : 3 }
    private var rowSpacing: CGFloat { compact ? 2 : 4 }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            weekdayHeader
            weeksGrid
        }
    }

    private var monthHeader: some View {
        HStack {
            Button(intent: ChangeMonthIntent(offset: -1)) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Text(monthYearString)
                .font(.system(size: headerSize, weight: .bold))
                .foregroundColor(.white)

            Button(intent: ChangeMonthIntent(offset: 1)) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(intent: ResetMonthIntent()) {
                Text("Today")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 4)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol.uppercased())
                    .font(.system(size: weekdaySize, weight: .semibold))
                    .foregroundColor(isWeekendIndex(index) ? Color.white.opacity(0.5) : Color.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 3)
    }

    private var weeksGrid: some View {
        let weeks = computeWeeks()
        return GeometryReader { geo in
            let rowCount = CGFloat(weeks.count)
            let separatorTotal = (rowCount - 1) * 0.5
            let rowHeight = (geo.size.height - separatorTotal) / rowCount

            VStack(spacing: 0) {
                ForEach(0..<weeks.count, id: \.self) { weekIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            let dayItem = weeks[weekIndex][dayIndex]
                            dayCellFull(dayItem)
                                .frame(height: rowHeight)
                                .clipped()
                            if dayIndex < 6 {
                                Rectangle()
                                    .fill(gridLineColor)
                                    .frame(width: 0.5, height: rowHeight)
                            }
                        }
                    }
                    if weekIndex < weeks.count - 1 {
                        Rectangle()
                            .fill(gridLineColor)
                            .frame(height: 0.5)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCellFull(_ dayItem: DayItem) -> some View {
        GeometryReader { geo in
            let dayHeight: CGFloat = todayCircleSize + 4
            let eventsHeight = max(0, geo.size.height - dayHeight)

            VStack(alignment: .center, spacing: 0) {
                // Day number - always visible at top
                Group {
                    if dayItem.day != 0 {
                        if dayItem.isToday {
                            Text("\(dayItem.day)")
                                .font(.system(size: dayNumberSize, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: todayCircleSize, height: todayCircleSize)
                                .background(Circle().fill(todayColor))
                        } else {
                            Text("\(dayItem.day)")
                                .font(.system(size: dayNumberSize, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(height: todayCircleSize)
                        }
                    } else {
                        Color.clear.frame(height: todayCircleSize)
                    }
                }
                .padding(.top, 2)
                .frame(height: dayHeight)

                // Events for this day - constrained to remaining space
                if dayItem.day != 0, let events = eventsByDay[dayItem.day] {
                    VStack(spacing: 1) {
                        ForEach(events.prefix(maxEventsPerCell)) { event in
                            eventCard(event)
                        }
                        if events.count > maxEventsPerCell {
                            Text("+\(events.count - maxEventsPerCell) more")
                                .font(.system(size: eventTimeSize))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .frame(maxHeight: eventsHeight, alignment: .top)
                    .clipped()
                }

                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    private func eventCard(_ event: SimpleEvent) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(eventCardColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: eventTitleSize, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.cyan)

                if !event.shortTime.isEmpty {
                    Text(event.shortTime)
                        .font(.system(size: eventTimeSize))
                        .foregroundColor(.cyan.opacity(0.7))
                }
            }
            .padding(.leading, 4)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(eventCardColor.opacity(0.2))
        )
        .padding(.horizontal, 2)
    }

    private func isWeekendIndex(_ index: Int) -> Bool {
        let firstWeekday = calendar.firstWeekday
        let adjustedIndex = (index + firstWeekday - 1) % 7 + 1
        return adjustedIndex == 1 || adjustedIndex == 7
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }

    private func computeWeeks() -> [[DayItem]] {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        let today = calendar.component(.day, from: Date())
        let isCurrentMonth = calendar.isDate(currentDate, equalTo: Date(), toGranularity: .month)

        var allDays: [DayItem] = []

        for _ in 0..<offsetDays {
            allDays.append(DayItem(day: 0, isToday: false))
        }

        for day in range {
            allDays.append(DayItem(day: day, isToday: isCurrentMonth && day == today))
        }

        // Pad to fill last week
        while allDays.count % 7 != 0 {
            allDays.append(DayItem(day: 0, isToday: false))
        }

        // Split into weeks
        var weeks: [[DayItem]] = []
        for i in stride(from: 0, to: allDays.count, by: 7) {
            weeks.append(Array(allDays[i..<min(i + 7, allDays.count)]))
        }
        return weeks
    }
}

struct DayItem: Hashable {
    let day: Int
    let isToday: Bool
}
