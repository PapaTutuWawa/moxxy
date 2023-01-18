#!/bin/bash
[[ $1 = "--clean" ]] && flutter clean

# Build everything again
flutter pub run build_runner build

# Build the release apk
flutter build apk \
	--release \
	--split-per-abi

# Create a folder with releases
[[ -d ./release ]] && rm -rf ./release
mkdir release
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ./release/moxxy-arm64-v8a-release.apk
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ./release/moxxy-armeabi-v7a-release.apk
cp build/app/outputs/flutter-apk/app-x86_64-release.apk ./release/moxxy-x86_64-release.apk
