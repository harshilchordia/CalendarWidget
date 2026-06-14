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
            items.append(DayItem(day: 0, isToday: false, monthLabel: nil, dateKey: "", isWeekend: false))
        }

        for day in range {
            items.append(DayItem(day: day, isToday: isCurrentMonth && day == today, monthLabel: nil, dateKey: "", isWeekend: false))
        }

        return items
    }
}

// MARK: - Full month grid with inline events (large/extra-large widget)
struct CalendarFullMonthView: View {
    let currentDate: Date
    let eventsByDay: [String: [SimpleEvent]]
    var compact: Bool = false
    var eventPages: [String: Int] = [:]

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()
    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // Colors matching Apple Calendar dark theme
    private let todayColor = Color.red
    private let eventCardColor = Color(red: 0.2, green: 0.5, blue: 0.9)
    private let gridLineColor = Color.white.opacity(0.001)

    private var headerSize: CGFloat { compact ? 11 : 12 }
    private var weekdaySize: CGFloat { compact ? 8 : 9 }
    private var dayNumberSize: CGFloat { compact ? 10 : 11 }
    private var todayCircleSize: CGFloat { compact ? 14 : 14 }
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
            Spacer()

            Button(intent: ChangeMonthIntent(offset: -3)) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Text(monthYearString)
                .font(.system(size: headerSize, weight: .bold))
                .foregroundColor(.white)

            Button(intent: ChangeMonthIntent(offset: 3)) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)

            Button(intent: ResetMonthIntent()) {
                Text("Today")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.bottom, 2)
    }

    private var weekdayHeader: some View {
        let weekOffset = MonthOffsetStore.currentOffset
        let startDay = calendar.date(byAdding: .day, value: weekOffset * 7, to: Date()) ?? Date()
        let startWeekdayIndex = calendar.component(.weekday, from: startDay) - 1
        let reorderedSymbols = (0..<7).map { i in
            weekdaySymbols[(startWeekdayIndex + i) % 7]
        }
        return HStack(spacing: 0) {
            ForEach(Array(reorderedSymbols.enumerated()), id: \.offset) { index, symbol in
                Text(symbol.uppercased())
                    .font(.system(size: weekdaySize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 2)
    }

    private var weeksGrid: some View {
        let weeks = computeWeeks()
        return GeometryReader { geo in
            let rowCount = CGFloat(weeks.count)
            let rowHeight = geo.size.height / rowCount

            VStack(spacing: 0) {
                ForEach(0..<weeks.count, id: \.self) { weekIndex in
                    if weekIndex > 0 {
                        Divider().background(gridLineColor)
                    }
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            if dayIndex > 0 {
                                Divider().background(gridLineColor)
                            }
                            let dayItem = weeks[weekIndex][dayIndex]
                            dayCellFull(dayItem)
                                .frame(height: rowHeight)
                                .background(dayItem.isWeekend ? Color.white.opacity(0.04) : Color.clear)
                                .clipped()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCellFull(_ dayItem: DayItem) -> some View {
        GeometryReader { geo in
            let dayHeight: CGFloat = todayCircleSize + 4
            let buttonHeight: CGFloat = 16
            let eventsHeight = geo.size.height - dayHeight

            VStack(alignment: .center, spacing: 0) {
                // Day number - always visible at top
                Group {
                    if dayItem.day != 0 {
                        if dayItem.isToday {
                            VStack(spacing: 1) {
                                Text("\(dayItem.day)")
                                    .font(.system(size: dayNumberSize + 1, weight: .bold))
                                    .foregroundColor(.white)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 2)
                            }
                            .frame(height: todayCircleSize + 2)
                        } else if let label = dayItem.monthLabel {
                            VStack(spacing: 0) {
                                Text("\(dayItem.day) \(label)")
                                    .font(.system(size: dayNumberSize, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(height: todayCircleSize)
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

                // Events for this day - fixed height container
                if dayItem.day != 0, let events = eventsByDay[dayItem.dateKey] {
                    let page = eventPages[dayItem.dateKey] ?? 0
                    let startIndex = page * maxEventsPerCell
                    let endIndex = min(startIndex + maxEventsPerCell, events.count)
                    let visibleEvents = Array(events[startIndex..<endIndex])
                    let totalPages = (events.count + maxEventsPerCell - 1) / maxEventsPerCell
                    let hasPages = totalPages > 1

                    VStack(spacing: 1) {
                        ForEach(visibleEvents) { event in
                            eventCard(event)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(height: hasPages ? eventsHeight - buttonHeight : eventsHeight)

                    if hasPages {
                        Button(intent: ShowMoreEventsIntent(dateKey: dayItem.dateKey, totalEvents: events.count, pageSize: maxEventsPerCell)) {
                            Text("\(page + 1)/\(totalPages)")
                                .font(.system(size: eventTimeSize + 2, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .frame(height: buttonHeight)
                    }
                } else {
                    Spacer(minLength: 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }

    private func eventCard(_ event: SimpleEvent) -> some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(eventCardColor)
                .frame(width: 2, height: 14)

            VStack(alignment: .leading, spacing: 0) {
                Text(event.title)
                    .font(.system(size: eventTitleSize, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.cyan)

                if !event.shortTime.isEmpty {
                    Text(event.shortTime)
                        .font(.system(size: eventTimeSize))
                        .foregroundColor(.cyan.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .padding(.leading, 3)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 1)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(eventCardColor.opacity(0.2))
        )
        .padding(.horizontal, 1)
    }

    private func isWeekendIndex(_ index: Int) -> Bool {
        let firstWeekday = calendar.firstWeekday
        let adjustedIndex = (index + firstWeekday - 1) % 7 + 1
        return adjustedIndex == 1 || adjustedIndex == 7
    }

    private var monthYearString: String {
        let weekOffset = MonthOffsetStore.currentOffset
        let startDay = calendar.date(byAdding: .day, value: weekOffset * 7, to: Date()) ?? Date()
        return Self.monthYearFormatter.string(from: startDay)
    }

    private func computeWeeks() -> [[DayItem]] {
        let today = Date()
        let weekOffset = MonthOffsetStore.currentOffset
        let startDay = calendar.date(byAdding: .day, value: weekOffset * 7, to: today) ?? today
        let startMonth = calendar.component(.month, from: startDay)

        var allDays: [DayItem] = []

        let shortMonths = calendar.shortMonthSymbols

        for offset in 0..<21 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDay) else { continue }
            let day = calendar.component(.day, from: date)
            let month = calendar.component(.month, from: date)
            let isToday = calendar.isDateInToday(date)
            let monthLabel: String? = (month != startMonth && day == 1) ? shortMonths[month - 1] : nil
            let dateKey = Self.dateKeyFormatter.string(from: date)
            let isWeekend = calendar.isDateInWeekend(date)
            allDays.append(DayItem(day: day, isToday: isToday, monthLabel: monthLabel, dateKey: dateKey, isWeekend: isWeekend))
        }

        // Split into 3 weeks of 7 days
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
    let monthLabel: String?
    let dateKey: String
    let isWeekend: Bool
}
