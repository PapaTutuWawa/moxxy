# Contribution Guide

Thanks for your interest in the Moxxy XMPP client! This document contains guidelines and guides for working
on the Moxxy codebase.

## Prerequisites

Before building or working on Moxxy, please make sure that your development environment is correctly set up.
Moxxy requires Flutter 3.7.3, since we use a fork of the Flutter library, and the JDK 17. Building Moxxy
is currently only supported for Android.

### Android Studio

If you use Android Studio, make sure that you use version "Flamingo Canary 3", as that one comes with
JDK 17 bundled, instead of JDK 11 ([See here](https://codeberg.org/moxxy/moxxy/issues/252)). If that is
not an option, you can manually add a JDK 17 installation in Android Studio and tell the Flutter addon
to use that installation instead.

### NixOS

If you use NixOS or Nix, you can use the dev shell provided by the Flake in the repository's root. It contains
the correct JDK and Flutter version. However, make sure that other environment variables, like
`ANDROID_HOME` and `ANDROID_AVD_HOME`, are correctly set.

## Building

Currently, Moxxy contains a git submodule. While it is not utilised at the moment, it contains
the list of suggested XMPP providers to use for auto-registration. To properly clone the
repository, use `git clone --recursive https://codeberg.org/moxxy/moxxy.git`

In order to build Moxxy, you first have to run the code generator. To do that, first install all dependencies with
`flutter pub get`. Next, run the code generator using `flutter pub run build_runner build`. This builds required
data classes and the i18n support.

Finally, you can build Moxxy using `flutter run`, if you want to test a change, or `flutter build apk --release` to build
an optimized release build. The release builds found in the repository's releases are build using `flutter build apk --release --split-per-abi`.

## Contributing

If you want to fix a small issue, you can just fork, create a new branch, and start working right away. However, if you want to work
on a bigger feature, please first create an issue (if an issue does not already exist) or join the [development chat](xmpp:moxxy@muc.moxxy.org?join) (xmpp:moxxy@muc.moxxy.org?join)
to discuss the feature first.

Before creating a pull request, please make sure you checked every item on the following checklist:

[ ] I formatted the code with the dart formatter (`dart format`) before running the linter
[ ] I ran the linter (`flutter analyze`) and introduced no new linter warnings
[ ] I ran the tests (`flutter test`) and introduced no new failing tests
[ ] I used [gitlint](https://github.com/jorisroovers/gitlint) to ensure propper formatting of my commig messages

If you think that your code is ready for a pull request, but you are not sure if it is ready, prefix the PR's title with "WIP: ", so that discussion
can happen there. If you think your PR is ready for review, remove the "WIP: " prefix.
