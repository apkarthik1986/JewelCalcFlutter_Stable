#!/bin/bash
# Build script for JewelCalc APK
# This script builds the release APK without using Gradle daemon to avoid memory issues

echo "Building JewelCalc APK..."
cd "$(dirname "$0")/android"
./gradlew assembleRelease --no-daemon

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
    ls -lh ../build/app/outputs/flutter-apk/app-release.apk
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
