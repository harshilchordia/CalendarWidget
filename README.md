# Calendar Widget for macOS

A native macOS WidgetKit widget that displays a month calendar view with your Apple Calendar events.

## Features

- **Month view** with day grid and highlighted current day
- **Event indicators** (dots) on days with calendar events
- **Upcoming events list** shown in medium and large widget sizes
- **Three sizes**: Small (calendar only), Medium (calendar + events), Large (expanded view)

## Requirements

- macOS 14.0+
- Xcode 16+
- Swift 5.9+

## Setup

1. Install XcodeGen if not already: `brew install xcodegen`
2. Generate the Xcode project: `xcodegen generate`
3. Open `CalendarWidget.xcodeproj` in Xcode
4. Build and run (Cmd+R)
5. Add the widget to your desktop or Notification Center

## Permissions

The widget requests calendar access to display your events. Grant access when prompted.

## Project Structure

```
CalendarWidget/
├── project.yml                         # XcodeGen config
├── CalendarWidget/                     # Host app
│   ├── CalendarWidgetApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   └── CalendarWidget.entitlements
├── CalendarWidgetExtension/            # Widget extension
│   ├── CalendarWidgetExtension.swift   # Widget entry point & views
│   ├── CalendarProvider.swift          # Timeline provider
│   ├── CalendarMonthView.swift         # Month grid view
│   ├── CalendarEventService.swift      # EventKit integration
│   ├── Info.plist
│   └── CalendarWidgetExtension.entitlements
└── Assets.xcassets/                    # Asset catalog
```
