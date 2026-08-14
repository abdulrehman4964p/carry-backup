# Forexlancer Mobile

![Android APK Build](https://github.com/abdulrehman4964p/carry-backup/actions/workflows/build-apk.yml/badge.svg)

Cross-platform Flutter app for Android and iOS. This release is mapped to Forexlancer Core 8.25.1 and Elite Theme 6.7.8. It uses a secure, allow-listed WebView so existing WordPress login sessions, courses, payments, certificates, profile, affiliate and dashboard features remain available without duplicating business logic.

The native drawer exposes all verified WordPress routes: Student Dashboard, Learning Center, My Courses, Free/Basic/Advance courses, Memberships, Premium Signals, Payment History, Certificates, Affiliate Program, Notifications, Support, Profile, Trading Chart, Technical Analysis, Fundamental Analysis and Forex News.

## Requirements

- Flutter stable 3.24 or newer
- Android Studio for Android builds
- Xcode 16 or newer on macOS for iOS builds

## Generate platform folders

From this directory run:

```bash
flutter create --platforms=android,ios --org com.forexlancer .
flutter pub get
```

Then ensure Android has Internet permission in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

For iOS, HTTPS is used and no insecure transport exception is required.

## Run and build

```bash
flutter run
flutter build appbundle --release
flutter build apk --release
flutter build ipa --release
```

The iOS release command must run on a Mac with an Apple Developer signing team.

## Free automatic APK build

This project includes `.github/workflows/build-apk.yml`. Push the project to a
GitHub repository, open the repository's **Actions** tab, select **Build
Forexlancer APK**, and choose **Run workflow**. After the run succeeds, download
the `Forexlancer-Android-APK` artifact. Extract it to obtain `app-release.apk`.

The workflow uses the repository's standard GitHub Actions allowance and asks
for no payment information. The generated APK is suitable for direct testing;
Play Store publishing later requires a permanent private release signing key.

## Configuration

Edit `lib/core/app_config.dart` if WordPress slugs differ. The domain allow-list prevents untrusted pages from opening inside the authenticated app; external links open in the device browser or their respective apps.

## Before store submission

1. Add the final Forexlancer icon and splash artwork.
2. Confirm the actual Dashboard, Login and Course page slugs.
3. Publish Privacy Policy, Terms, Risk Disclaimer and Account Deletion pages.
4. Configure app signing and unique store identifiers.
5. Test registration, email activation, login persistence, video playback, payment proof upload, certificate downloads and password reset on physical Android and iPhone devices.

## Native API upgrade

The next phase can replace individual WebView sections with native Flutter screens. That requires the current custom WordPress plugin/theme ZIP or documented authenticated REST endpoints. Passwords should not be placed in source code or shared in chat.
