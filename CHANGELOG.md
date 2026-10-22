# Train Buddy development update — 2026-10-22

## Changes

- Rename the macOS app, project, targets and schemes to Train Buddy; preserve its App Store bundle ID, login helper relationship and existing preferences.
- Integrate macOS PR #4 (long station names), explicitly approved by the maintainer. Keep #3 (suppressed/recoloured deviations) and #6 (full SwiftUI rewrite) out.
- Integrate DBConnect #12 (leading zeroes) and #13 (error completion), correcting #12's app-only test import and strengthening the provider race beyond #13.
- Point the submodule at the organization's DBConnect repository and use its current artwork and code.
- Add one-provider snapshots, poll coalescing, a five-second successful-result cache, main-queue UI delivery and exactly-once provider-race completion.
- Add ÖBB Railnet, ČD onboard Wi-Fi and DB Regio Zugportal adapters. Preserve a usable journey when telemetry is unavailable; keep unreported forecasts unknown.
- Bind asset catalogs into the Swift package, remove crashing image force unwraps and provide original schematic artwork for additional/unknown vehicles.
- Normalize physical trainset identifiers, prefer recognized reported series, identify ICE 3neo/BR 408 and explicitly reported ICE L, and narrow the ICE 4 allocation fallback.
- Reuse the pinned speed status item across updates to address the macOS Tahoe disappearance report.
- Remove automatic review requests prompted by selecting an alarm or pinning speed.
- Translate the exit alarm and menu into English/German. Cancel old alarm requests when switching/disabling an alarm; permit reminders selected less than ten minutes before arrival.
- Preserve all reported deviations, including small delays and arrival delays at the final stop. Skip canceled calls when choosing the next stop.

## Reports checked

All 21 customer reviews returned by App Store Connect were read. Actionable defects included repeated rating prompts and absent ICE 3neo artwork. Other reviews requested additional train support, German localization and data while using a hotspot. The first two requests are covered here. A cloud timetable mode over a personal hotspot remains a separate feature: onboard speed/position cannot be reliably inferred from a public timetable.

Open GitHub issues were reviewed, including #5 (wrong submodule), #7 (alarm language), #8 (ICE 3neo), #9 (Tahoe speed item) and #10 (other operators). Apple's recent crash-signature endpoint was queried, but its download failed; this is not evidence that there are no crashes.

## Validation and limits

- Reproduced incorrect trainset parsing and the empty-provider hang before repair.
- Reproduced the upstream provider race returning two callbacks after a success followed by a failure.
- Swift-package tests exercise all five adapters and their bundled artwork, transport failures, provider selection, cache/coalescing, midnight rollover, cancellation, stop identities and vehicle classification.
- The macOS Debug build and app-hosted tests pass. The test app launches on the host Mac; native Computer Use could not inspect the menu-only app, so a complete visual walkthrough is unverified.
- New onboard adapters were validated against bundled, attributed response samples, not live train Wi-Fi. Confirm them during actual journeys before publishing an App Store build.
- The installed Xcode requires at least macOS 12 for the app target; minimum deployment was raised from 11 to 12. No App Store submission is performed by these source changes.

## API support reports

- Add “Report API problem…” to connected and disconnected menus, with English/German preview, email-draft and JSON-export actions for trainbuddy@riedel.wtf.
- Keep at most 40 request outcomes from the last 15 minutes in memory. Capture static endpoint labels, timing, HTTP status/size and safe decoding/network categories; never retain raw bodies, arbitrary URLs, headers or localized error descriptions.
- Cover transport, decoding and semantic adapter failures. Redact dynamic dictionary keys; failed probes for other operators are explained in the preview/report.
- Export only to a location explicitly chosen in NSSavePanel. The sandbox file entitlement permits writes to user-selected files for this action.
- Preparing an email delegates to the system mail composer; the app has no sending backend. If composing is unavailable/fails, offer file export for webmail. The mailbox/alias itself is not provisioned by the source change.
- Validation for this addition: 14 package tests (including synthetic credential/location/error redaction and bounded retention) and 2 app tests pass; the app builds. No real support email was sent. The mail-composer/export UI still needs a manual walkthrough.

## iOS, widgets and Live Activities

- Add an iOS 26+ iPhone/iPad target and shared scheme alongside the existing Mac app. Reuse all five onboard providers and train artwork, with the full journey, vehicle series, platform changes, speed where reported, and small/past delays preserved.
- Add small/medium Home Screen widgets and a rectangular Lock Screen widget. Refresh buttons in widgets, Live Activities and the app perform a new onboard request; simultaneous actions coalesce while a request is in flight.
- Add Lock Screen and Dynamic Island presentations, stale/error labels, and a Control Center button that starts or updates one Live Activity through `LiveActivityIntent` without opening the app. Expose start/refresh as App Shortcuts as well.
- Share Codable/Sendable snapshots through atomic App Group files. Preserve the last successful data and original fetch time after failure, clear demo data when switching mode, and mark data outdated after 60 seconds. Bound UTF-8 fields in the ActivityKit state; exclude the full stop list and PNG artwork from its payload.
- Keep the refresh service and activity lifecycle in `TrainBuddyKit`. Compile thin intent entry points directly into both application bundles to avoid imported-package metadata resolution failures observed on iOS 26.5.
- Refresh automatically every 30 seconds in the foreground. Suspended background execution has no continuous polling guarantee; users can refresh from system surfaces. No push server or App Store submission is included.
- Include the diagnostic preview, email draft and share-sheet fallback on iOS. App Group provisioning is required for both new bundle IDs before installing a signed device/TestFlight build. Actual train Wi-Fi validation is still required before release.
- Validation: three shared-data Swift tests, three iOS UI scenarios (including Control Center cold start after app termination and Lock Screen refresh without opening the app), and the two existing macOS app tests pass. iOS Simulator Debug and unsigned device Release builds succeed. The iOS UI was exercised on an isolated iOS 26.5 simulator; physical-device/onboard-Wi-Fi and App Store distribution checks remain outstanding.
