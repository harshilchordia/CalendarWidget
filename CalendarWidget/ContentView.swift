import SwiftUI
import EventKit

struct ContentView: View {
    @State private var calendarAccessGranted = false
    @State private var accessDenied = false
    @State private var eventStore = EKEventStore()

    var body: some View {
        VStack(spacing: 16) {
            Text("Calendar Widget")
                .font(.largeTitle)
                .fontWeight(.bold)

            if calendarAccessGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                Text("Calendar access granted!")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else if accessDenied {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                Text("Calendar access denied.")
                    .font(.body)
                    .foregroundColor(.secondary)

                Button("Open Privacy Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Check Again") {
                    Task { await requestCalendarAccess() }
                }
                .buttonStyle(.bordered)
            } else {
                ProgressView()
                Text("Requesting calendar access...")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Text("Add the widget from the Notification Center or by right-clicking on the desktop.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(width: 400, height: 280)
        .padding()
        .task {
            await requestCalendarAccess()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await requestCalendarAccess() }
        }
    }

    private func requestCalendarAccess() async {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .fullAccess, .authorized:
            calendarAccessGranted = true
            accessDenied = false
        case .denied, .restricted:
            calendarAccessGranted = false
            accessDenied = true
        case .notDetermined, .writeOnly:
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                calendarAccessGranted = granted
                accessDenied = !granted
            } catch {
                accessDenied = true
            }
        @unknown default:
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                calendarAccessGranted = granted
                accessDenied = !granted
            } catch {
                accessDenied = true
            }
        }
    }
}
