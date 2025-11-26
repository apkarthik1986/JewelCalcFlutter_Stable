#!/bin/bash
# Build script for JewelCalc APK
# This script detects the Flutter version and builds accordingly

set -e

echo "🔍 Detecting Flutter version..."
FLUTTER_VERSION=$(flutter --version | grep "Flutter" | awk '{print $2}')
echo "Found Flutter version: $FLUTTER_VERSION"

# Extract major and minor version
FLUTTER_MAJOR=$(echo $FLUTTER_VERSION | cut -d'.' -f1)
FLUTTER_MINOR=$(echo $FLUTTER_VERSION | cut -d'.' -f2)

# Create keystore if it doesn't exist
if [ ! -f ~/.android/debug.keystore ]; then
    echo "🔑 Creating debug keystore..."
    mkdir -p ~/.android
    keytool -genkey -v -keystore ~/.android/debug.keystore \
        -storepass android -alias androiddebugkey -keypass android \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US"
fi

echo "🏗️  Building JewelCalc APK..."

# For older Flutter versions (< 3.10), use Gradle directly without daemon
if [ "$FLUTTER_MAJOR" -lt 3 ] || ([ "$FLUTTER_MAJOR" -eq 3 ] && [ "$FLUTTER_MINOR" -lt 10 ]); then
    echo "Using Gradle build (older Flutter)..."
    cd "$(dirname "$0")/android"
    ./gradlew assembleRelease --no-daemon
else
    echo "Using Flutter build (modern Flutter)..."
    flutter build apk --release
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📦 APK location: build/app/outputs/flutter-apk/app-release.apk"
    ls -lh build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || \
    ls -lh build/app/outputs/apk/release/app-release.apk 2>/dev/null
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
