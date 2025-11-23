# Building MyFlutter App

This document provides detailed instructions for building the MyFlutter Android application.

## 🏗️ Build Methods

### Method 1: Automated Build with GitHub Actions (Easiest)

This is the recommended method for getting APK files without setting up any development environment.

#### Steps:

1. **Trigger a Build**
   - Push any commit to `main` or `master` branch, OR
   - Go to **Actions** tab → **Build Flutter APK** → **Run workflow** → **Run workflow**

2. **Monitor Build Progress**
   - Go to **Actions** tab
   - Click on the latest workflow run
   - Watch the build process in real-time

3. **Download APK**
   - Once the build completes successfully (green checkmark ✓)
   - Scroll down to **Artifacts** section
   - Click on `myflutter-release-apk` to download
   - Extract the ZIP file to get the APK

4. **Install on Android Device**
   - Transfer APK to your Android device
   - Enable "Install from unknown sources" in Settings
   - Tap the APK file to install

**Note**: Artifacts are retained for 90 days and automatically deleted after that.

---

### Method 2: Build in GitHub Codespaces

Use GitHub Codespaces for a pre-configured cloud development environment.

#### Steps:

1. **Launch Codespace**
   - Click the **Code** button in the repository
   - Switch to **Codespaces** tab
   - Click **Create codespace on main**
   - Wait 2-3 minutes for initialization

2. **Verify Flutter Installation**
   ```bash
   flutter doctor
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run Tests** (Optional)
   ```bash
   flutter test
   ```

5. **Build Release APK**
   ```bash
   flutter build apk --release
   ```

6. **Locate APK**
   The APK will be at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

7. **Download APK**
   - Right-click on the APK file in VS Code file explorer
   - Select **Download**
   - Save to your local machine

---

### Method 3: Local Development Setup

For developers who want to work on the project locally.

#### Prerequisites:

1. **Install Flutter SDK**
   - Download from: https://flutter.dev/docs/get-started/install
   - Version: 3.24.3 or later recommended
   - Add Flutter to your PATH

2. **Install Android Studio**
   - Download from: https://developer.android.com/studio
   - Install Android SDK
   - Install Android SDK Platform (API 34)
   - Install Android SDK Build-Tools

3. **Install Java Development Kit**
   - Java 17 or later
   - Set JAVA_HOME environment variable

#### Build Steps:

1. **Clone Repository**
   ```bash
   git clone https://github.com/apkarthik1986/MyFlutter.git
   cd MyFlutter
   ```

2. **Verify Flutter Setup**
   ```bash
   flutter doctor
   ```
   Fix any issues reported by `flutter doctor`

3. **Get Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run Tests**
   ```bash
   flutter test
   ```

5. **Build APK**
   ```bash
   # Release build (optimized, smaller size)
   flutter build apk --release
   
   # Debug build (larger, with debugging info)
   flutter build apk --debug
   
   # Split APKs per architecture (smaller individual files)
   flutter build apk --split-per-abi
   ```

6. **Find Built APK**
   - Release APK: `build/app/outputs/flutter-apk/app-release.apk`
   - Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
   - Split APKs: `build/app/outputs/flutter-apk/app-{arch}-release.apk`

---

## 📱 Testing the App

### Run on Emulator

1. **Start Android Emulator**
   ```bash
   flutter emulators --launch <emulator_id>
   ```

2. **Run App**
   ```bash
   flutter run
   ```

### Run on Physical Device

1. **Enable Developer Options** on your Android device
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times

2. **Enable USB Debugging**
   - Go to Settings → Developer Options
   - Enable "USB Debugging"

3. **Connect Device**
   - Connect via USB cable
   - Allow USB debugging on device

4. **Verify Device**
   ```bash
   flutter devices
   ```

5. **Run App**
   ```bash
   flutter run
   ```

---

## 🔍 Troubleshooting

### Common Issues:

#### "Flutter SDK not found"
- Ensure Flutter is installed and added to PATH
- Run `flutter doctor` to diagnose

#### "Android licenses not accepted"
```bash
flutter doctor --android-licenses
```
Accept all licenses

#### "Gradle build failed"
- Check Java version: `java -version`
- Ensure Java 17 or later is installed
- Check Android SDK is properly installed

#### "No devices found"
- For emulator: Start an Android Virtual Device
- For physical device: Enable USB debugging and reconnect

#### Build fails in GitHub Actions
- Check Actions logs for specific error
- Ensure all required files are committed
- Verify workflow file syntax

---

## 📊 Build Configuration

### APK Types:

1. **Release APK** (Recommended for distribution)
   - Optimized and minified
   - Smaller file size
   - No debugging info
   - Signed with debug key (for development)

2. **Debug APK** (For testing)
   - Contains debugging information
   - Larger file size
   - Hot reload supported

3. **Profile APK** (For performance testing)
   - Optimized but retains some debugging info
   - Used for performance analysis

### Build Variants:

- **Universal APK**: Works on all architectures (larger size)
- **Split APKs**: Separate APKs for each architecture (smaller individual files)
  - arm64-v8a (64-bit ARM)
  - armeabi-v7a (32-bit ARM)
  - x86_64 (64-bit x86)

---

## 🚀 Advanced Build Options

### Custom Build Commands:

```bash
# Build with verbose output
flutter build apk --release --verbose

# Build without tree-shaking icons
flutter build apk --release --no-tree-shake-icons

# Build with specific target file
flutter build apk --release --target=lib/main_production.dart

# Build with obfuscation (for security)
flutter build apk --release --obfuscate --split-debug-info=./debug-info

# Build specific architecture only
flutter build apk --release --target-platform android-arm64
```

### Environment Variables:

```bash
# Increase Gradle memory
export GRADLE_OPTS="-Xmx4096m"

# Use specific Java version
export JAVA_HOME=/path/to/java17
```

---

## 📦 APK Distribution

### For Testing:
- Share the APK file directly with testers
- Upload to Firebase App Distribution
- Use Google Play Internal Testing

### For Production:
- Sign with a release keystore
- Upload to Google Play Console
- Generate an App Bundle (AAB) instead: `flutter build appbundle`

---

## 🔗 Useful Links

- [Flutter Documentation](https://flutter.dev/docs)
- [Android Developer Guide](https://developer.android.com/guide)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)

---

## 💡 Tips

1. **Always run tests** before building release APK
2. **Use release builds** for distribution (smaller and faster)
3. **Keep Flutter updated** for latest features and bug fixes
4. **Monitor build logs** in GitHub Actions for any warnings
5. **Test APK** on multiple devices before distribution
