# ezdihar_remote

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## CI builds

`.github/workflows/android.yml` builds a release APK on every push to `main` (and on
"Run workflow") and publishes it as a GitHub Release tagged `v<version>-build<run>`,
with the APK named `ezdihar_remote_v<version>_build<run>_<sha>.apk`. Pull requests
only build (the APK is attached to the run). Bump `version:` in `pubspec.yaml` to
change the version part; the run number is used as the Android build number.

Optional release signing: add `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`; otherwise builds use a debug key.
