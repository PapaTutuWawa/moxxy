# Moxxy

An experimental XMPP client that tries to be as easy, modern and beautiful as possible.

The code is also available on [codeberg](https://codeberg.org/moxxy/moxxyv2).

[<img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroid.png"
     alt="Get it on IzzyOnDroid"
     height="80">](https://apt.izzysoft.de/fdroid/index/apk/org.moxxy.moxxyv2)

Or [get the latest APK from Codeberg](https://codeberg.org/moxxy/moxxy/releases/latest).

## Screenshots

[<img src="https://codeberg.org/moxxy/moxxyv2/raw/branch/master/fastlane/metadata/android/en-US/images/phoneScreenshots/1.png" width="20%"></img>](./fastlane/metadata/android/en-US/images/phoneScreenshots/1.png)
[<img src="https://codeberg.org/moxxy/moxxyv2/raw/branch/master/fastlane/metadata/android/en-US/images/phoneScreenshots/2.png" width="20%"></img>](./fastlane/metadata/android/en-US/images/phoneScreenshots/2.png)

## Developing and Building

Clone using `git clone --recursive https://github.com/Polynomdivision/moxxyv2.git`.

In order to build Moxxy, you need to have [Flutter](https://docs.flutter.dev/get-started/install) set
up. If you are running NixOS or using Nix, you can also use the Flake at the root of the repository
by running `nix develop` to get a development shell including everything that is needed. Note
that if you decide to use the Flake, `ANDROID_HOME` and `ANDROID_AVD_HOME` must be set to the respective directories.

Before building Moxxy, you need to generate all needed data classes. To do this, run
`flutter pub get` to install all dependencies. Then run `flutter pub run build_runner build` to generate
state classes, data classes and the database schemata. After that is done, you can either
build the app with `flutter build apk --debug` to create a debug build,
`flutter build apk --release` to create a relase build or just run the app in development
mode with `flutter run`.

After implementing a change or a feature, please ensure that nothing is broken by the change
by running `flutter test` afterwards. Also make sure that the code passes the linter by
running `flutter analyze`. This project also uses [gitlint](https://github.com/jorisroovers/gitlint)
to ensure uniform formatting of commit messages.

Also, feel free to join the development chat at `moxxy@muc.moxxy.org`.

## A Bit of History

This project is the successor of moxxyv1, which was written in *React Native* and abandoned
due to various technical issues.

## License

See `./LICENSE`.

## Special Thanks

- New logo designed by [Synoh](https://twitter.com/synoh_manda)

## Support

If you like what I do and you want to support me, feel free to donate to me on Ko-Fi.

[<img src="https://codeberg.org/moxxy/moxxyv2/raw/branch/master/assets/repo/kofi.png" height="36" style="height: 36px; border: 0px;"></img>](https://ko-fi.com/papatutuwawa)
