import SwiftUI
import EventKit
import WidgetKit
import os.log

private let logger = Logger(subsystem: "com.harshilchordia.CalendarWidget", category: "AppDelegate")

class AppDelegate: NSObject, NSApplicationDelegate {
    let eventStore = EKEventStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        eventStore.requestFullAccessToEvents { [weak self] granted, error in
            if granted, let self = self {
                // Perform an initial fetch so the store subscribes to DB changes
                let now = Date()
                let end = Calendar.current.date(byAdding: .day, value: 1, to: now)!
                let pred = self.eventStore.predicateForEvents(withStart: now, end: end, calendars: nil)
                _ = self.eventStore.events(matching: pred)
                logger.info("Calendar access granted, store warmed up")
            } else {
                logger.error("Calendar access denied: \(error?.localizedDescription ?? "unknown")")
            }
        }

        // EKEventStoreChanged — official API (works when store is warmed up)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(calendarChanged(_:)),
            name: .EKEventStoreChanged,
            object: nil
        )

        // Darwin notifications — requires no sandbox
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()

        let callback: CFNotificationCallback = { _, _, name, _, _ in
            let n = name?.rawValue as String? ?? "unknown"
            logger.info("Darwin notification received: \(n)")
            WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
            }
        }

        CFNotificationCenterAddObserver(center, observer, callback,
            "com.apple.calendarstore.notification" as CFString, nil, .deliverImmediately)
        CFNotificationCenterAddObserver(center, observer, callback,
            "com.apple.calendar.availability.changed" as CFString, nil, .deliverImmediately)
        CFNotificationCenterAddObserver(center, observer, callback,
            "_CalDatabaseChangedNotification" as CFString, nil, .deliverImmediately)

        logger.info("Observing Darwin + EKEventStoreChanged notifications")
    }

    @objc private func calendarChanged(_ notification: Notification) {
        logger.info("EKEventStoreChanged fired, reloading widget")
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct CalendarWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
