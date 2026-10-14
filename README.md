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
"Run workflow"), named `ezdihar_remote_v<version>_build<run>_<sha>.apk`, attaches it to
the run and copies it to the Google Drive folder.

Drive upload setup (once):
1. Install [rclone](https://rclone.org/downloads/) and run `rclone config`:
   `n` (new remote), name `gdrive`, storage `drive`, leave client id/secret empty,
   scope `1` (full access), accept the defaults and sign in with the Google account
   that can edit the folder.
2. Print the config with `rclone config show gdrive` and add it (including the
   `[gdrive]` line) as the repository secret `RCLONE_CONF`.

Optional release signing: add `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`; otherwise builds use a debug key.
