# Quick Start Guide

Get your Flutter Android app up and running in minutes!

## 🎯 I just want the APK file!

**Easiest method - No setup required:**

1. Go to the [**Actions**](../../actions) tab
2. Click **"Run workflow"** button → Select **"Run workflow"**
3. Wait 3-5 minutes for build to complete
4. Scroll to **Artifacts** section
5. Download **myflutter-release-apk**
6. Extract ZIP and install APK on your Android device

✅ Done! No coding, no installation, no setup needed.

---

## 💻 I want to develop in the cloud!

**Use GitHub Codespaces:**

1. Click the **Code** button (green button at top)
2. Go to **Codespaces** tab
3. Click **"Create codespace on main"**
4. Wait for initialization (2-3 minutes)
5. In terminal, run:
   ```bash
   flutter pub get
   flutter build apk --release
   ```
6. Find your APK at: `build/app/outputs/flutter-apk/app-release.apk`

✅ Full Flutter development environment in your browser!

---

## 🖥️ I want to develop locally!

**Prerequisites:** Install Flutter SDK, Android Studio, Java 17+

```bash
# 1. Clone repository
git clone https://github.com/apkarthik1986/MyFlutter.git
cd MyFlutter

# 2. Get dependencies
flutter pub get

# 3. Build APK
flutter build apk --release

# 4. Find APK
# Location: build/app/outputs/flutter-apk/app-release.apk
```

✅ APK ready for distribution!

---

## 🧪 I want to test the app!

### On Emulator:
```bash
flutter run
```

### On Physical Device:
1. Enable USB Debugging on your Android device
2. Connect via USB
3. Run: `flutter run`

---

## 📱 Installing APK on Android

1. Transfer APK to your phone
2. Settings → Security → Enable "Install unknown apps"
3. Open APK file
4. Tap "Install"

---

## 🆘 Need Help?

- **Detailed Instructions**: See [BUILDING.md](BUILDING.md)
- **Flutter Issues**: Run `flutter doctor` and fix any issues
- **Build Failures**: Check [Actions](../../actions) logs for errors

---

## 🎉 What's Next?

- Modify `lib/main.dart` to customize the app
- Add new features and packages in `pubspec.yaml`
- Push changes to trigger automatic builds
- Download new APK from Actions artifacts

Happy coding! 🚀
