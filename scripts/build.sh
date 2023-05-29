#!/bin/bash
set -e
version=$(grep -E "^version: " pubspec.yaml | cut -b 10-)
IFS="+" read -ra version_parts <<< "$version"
version_code="${version_parts[1]}"
echo "===== Moxxy ====="
echo
echo "Building version ${version}"

# Check if we have a changelog file for that version
if [[ ! -f "./fastlane/metadata/android/en-US/changelogs/$version_code.txt" ]]; then
    echo "Warning: No changelog item for $version_code"
fi

if [[ ! $1 = "--no-clean" ]]; then
    # Clean flutter build
    flutter clean

    # The custom builder does not overwrite its own files, for some reason
    # TODO: Fix
    rm lib/shared/{events,commands,version}.moxxy.dart || true
fi

# Get dependencies
flutter pub get

# Build everything again
flutter pub run build_runner build --delete-conflicting-outputs

# Build the release apk
flutter build apk \
	--release \
	--split-per-abi
	#--split-debug-info="./${version}"

# Create a folder with releases
release_dir="./release-${version}"
[[ -d "${release_dir}" ]] && rm -rf "${release_dir}"
mkdir "${release_dir}"

# Copy artifacts
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "${release_dir}/moxxy-arm64-v8a-release.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "${release_dir}/moxxy-armeabi-v7a-release.apk"
cp build/app/outputs/flutter-apk/app-x86_64-release.apk "${release_dir}/moxxy-x86_64-release.apk"

# Copy the debug symbols into it
#mv "./${version}" "${release_dir}/debug-info-${version}"
