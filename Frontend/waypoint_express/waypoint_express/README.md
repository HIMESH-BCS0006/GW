# waypoint_express

A new Flutter project.

## Loader-to-driver QR handoff

Run `node Backend\mock_server.js` from the repository root while developing. A
loader accepts an order and shows its QR code; the driver scans it from the
**Scan QR** tab to fetch and view the order details. The mock server keeps
handoff records in memory, so both devices must use the same running server
and accepted orders are cleared when it stops.

For a USB-connected Android device, run `adb reverse tcp:4010 tcp:4010` before
launching the Flutter app in debug mode.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
