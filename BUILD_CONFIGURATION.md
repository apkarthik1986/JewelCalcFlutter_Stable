# Build Configuration Guide

## Overview

This project is configured to work with **both old and new Flutter versions**:
- **Local Dev Container**: Flutter 3.7.7 (older, pre-installed)
- **GitHub Actions**: Flutter 3.24.3 (latest stable)

## Configuration Files

### Android Build Files

The Android build configuration has been updated to support **modern Flutter versions (3.0+)**:

- **Gradle Version**: 8.3 (in `gradle-wrapper.properties`)
- **Android Gradle Plugin**: 8.1.0
- **compileSdk**: 34
- **targetSdk**: 34
- **minSdk**: 21

### Dependencies

**pubspec.yaml** now uses modern dependency versions compatible with Flutter 3.0+:
- `sdk: '>=3.0.0 <4.0.0'`
- Updated plugin versions (pdf, printing, shared_preferences, etc.)

## Building Locally

### Option 1: Using the Build Script (Recommended)

```bash
./build-apk.sh
```

This script automatically detects your Flutter version and builds accordingly.

### Option 2: Manual Build

**For Flutter 3.7.7 (current dev container):**
```bash
cd android
./gradlew assembleRelease --no-daemon
```

**For Flutter 3.10+ (if you upgrade):**
```bash
flutter build apk --release
```

## Building in GitHub Actions

The workflow (`.github/workflows/build-apk.yml`) uses Flutter 3.24.3 and:
1. Creates a debug keystore for signing
2. Runs `flutter build apk --release`
3. Uploads the APK as an artifact

The built APK will be **properly signed and installable**.

## Important Notes

### Signing Configuration

The APK is signed with a **debug keystore** for testing purposes:
- **Location**: `~/.android/debug.keystore`
- **Store Password**: `android`
- **Key Alias**: `androiddebugkey`
- **Key Password**: `android`

For production releases, you should create and use a **production keystore**.

### Memory Issues

If building locally with Flutter 3.7.7 and encountering Gradle daemon crashes:
- The build script uses `--no-daemon` flag
- Memory settings are configured in `android/gradle.properties`

### APK Location

After successful build, the APK is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

### "Invalid file" error on installation

This usually means:
1. **APK is not signed** - Ensure keystore exists and is configured
2. **Architecture mismatch** - The APK supports arm64-v8a, armeabi-v7a, and x86_64
3. **Corrupted download** - Re-download the APK from GitHub Actions artifacts

### GitHub Actions build fails

Check:
1. All tests pass (currently skipped with `|| true`)
2. Dependencies are correctly specified in `pubspec.yaml`
3. Android configuration is compatible with Flutter 3.24.3

### Local build fails with newer Flutter

If you upgrade Flutter locally:
1. Clean the build: `flutter clean`
2. Update dependencies: `flutter pub get`
3. Use the build script: `./build-apk.sh`

## Upgrading Flutter Locally

To upgrade the dev container Flutter to match GitHub Actions:

```bash
# This won't work in current setup due to git issues
# Instead, reinstall Flutter:
cd /sdks
mv flutter flutter-old
git clone https://github.com/flutter/flutter.git -b stable
export PATH="/sdks/flutter/bin:$PATH"
flutter doctor
```

After upgrading, the configuration should work seamlessly.
