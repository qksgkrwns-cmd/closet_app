# closet_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Magic Link Login Setup

If email login link does not open the app, configure Supabase redirect URLs.

1. Open Supabase Dashboard -> Authentication -> URL Configuration.
2. Add this redirect URL:
	- `io.supabase.closetapp://login-callback/`
3. Save settings and request a new login email.

The app is configured for this callback in:

- iOS URL scheme: `ios/Runner/Info.plist`
- Android deep link intent filter: `android/app/src/main/AndroidManifest.xml`
- Login request redirect: `lib/pages/login_page.dart`
