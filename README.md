<img src="https://user-images.githubusercontent.com/5204169/172066908-19394991-76d5-4cfb-a535-8be4b6a68e05.png" width="100" height="100">

# Train Buddy for macOS and iOS

Train Buddy (formerly ICE Buddy) shows your train's journey, speed, delays, next stops and route in your Mac's menu bar. It reads the local onboard portal while you are connected to supported train Wi-Fi.

Supports ICE and TGV, with additional adapters for ÖBB Railnet, ČD onboard Wi-Fi and DB Zugportal. Available information depends on the portal: for example, regional journeys remain visible even without speed data. Reported delays remain visible, including delays below five minutes and at terminal stations.

The existing [Mac App Store listing](https://apps.apple.com/app/id1595947689) remains the released ICE Buddy build until a new version is submitted. See [the implementation and validation notes](CHANGELOG.md) and [API architecture](DBConnect/README.md).

## Build and test

```sh
git clone --recurse-submodules https://github.com/ICE-Buddy/ICE-Buddy-macOS.git
cd ICE-Buddy-macOS
open "Train Buddy.xcodeproj"
swift test --package-path DBConnect
xcodebuild -project "Train Buddy.xcodeproj" -scheme "Train Buddy" -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

The app targets macOS 12 or later. Its bundle ID and preference keys are preserved for updates from ICE Buddy. Use the `--demo` launch argument to inspect the app with bundled ICE sample data without train Wi-Fi. English and German menus are included.

## iPhone, widgets and Live Activities

Choose the **Train Buddy iOS** scheme in the same Xcode project. The iPhone/iPad app targets iOS 26 or later and uses the same five onboard adapters as the Mac app. It shows the full journey, reported vehicle series, train artwork, speed where available, platform changes and all reported delays.

1. Open Train Buddy once, connect to supported train Wi-Fi and allow local network access. Some trains require opening their captive portal first. Demo mode uses bundled ICE data and is visibly marked everywhere.
2. Add **Train journey** from the widget gallery. Small and medium Home Screen widgets and a rectangular Lock Screen widget show the next stop. Their refresh button fetches current portal data.
3. Start a **Live Activity** in the app, or add **Start Train Live Activity** in Control Center. The control starts or updates one activity in the background without opening the app. Refresh on the Lock Screen or in the expanded Dynamic Island fetches new information. Unlocking may be required by iOS.

The app refreshes every 30 seconds while active. Each completed manual refresh starts a new network request; overlapping refreshes share the in-flight request. Widgets read an atomic App Group snapshot. Data becomes marked outdated after 60 seconds, and a failed refresh preserves the last successful data and its original timestamp. There is no server push service or continuous polling while iOS suspends the app. Reconnect to train Wi-Fi and tap refresh when needed. iOS controls widget reload timing and Live Activity lifetime.

The shared `TrainBuddyKit` package owns the serializable journey, persistence, refresh service and ActivityKit lifecycle. The thin intents in `MobileShared` compile into both the app and widget extension; `LiveActivityIntent` routes their actions to the app process. Artwork and the full stop list stay out of the ActivityKit payload, which is bounded below the 4 KB platform limit. The app and extension use `group.wtf.riedel.TrainBuddy`; enable this App Group for both bundle IDs in your signing account before a device/TestFlight build. The iOS bundle ID is `wtf.riedel.TrainBuddy`; the existing Mac identity is preserved.

```sh
swift test --package-path TrainBuddyKit
xcodebuild -project "Train Buddy.xcodeproj" -scheme "Train Buddy iOS" -destination 'generic/platform=iOS Simulator' build
```

The iOS **Report API problem…** screen previews the same redacted diagnostics before preparing an email or opening the share sheet. Nothing is sent automatically.

## Reporting an API problem

Choose **Report API problem…** (**API-Problem melden…**) in the menu, including when disconnected. Review the diagnostic report, then prepare an email to **trainbuddy@riedel.wtf** or save the JSON file for use in webmail. Nothing is sent automatically.

The report contains recent technical request metadata and app/macOS versions. It excludes locations, station names, Wi-Fi identifiers, headers and response contents. Add a short description of the problem and operator yourself if useful. The support address must exist as a mailbox or forwarding alias; the app does not provision email hosting.

## Contribution Rules

We encourage everyone to improve and enhance Train Buddy for different train types and functionalities. The project's original contribution rule remains: pull requests should be written while travelling on a train.

![Journey](https://user-images.githubusercontent.com/5204169/172067056-45556072-69d7-4fa2-9fe0-a9c1d137e071.png)
