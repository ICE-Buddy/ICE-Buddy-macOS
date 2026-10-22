<img src="https://user-images.githubusercontent.com/5204169/172066908-19394991-76d5-4cfb-a535-8be4b6a68e05.png" width="100" height="100">

# Train Buddy for macOS

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

## Reporting an API problem

Choose **Report API problem…** (**API-Problem melden…**) in the menu, including when disconnected. Review the diagnostic report, then prepare an email to **trainbuddy@riedel.wtf** or save the JSON file for use in webmail. Nothing is sent automatically.

The report contains recent technical request metadata and app/macOS versions. It excludes locations, station names, Wi-Fi identifiers, headers and response contents. Add a short description of the problem and operator yourself if useful. The support address must exist as a mailbox or forwarding alias; the app does not provision email hosting.

## Contribution Rules

We encourage everyone to improve and enhance Train Buddy for different train types and functionalities. The project's original contribution rule remains: pull requests should be written while travelling on a train.

![Journey](https://user-images.githubusercontent.com/5204169/172067056-45556072-69d7-4fa2-9fe0-a9c1d137e071.png)
