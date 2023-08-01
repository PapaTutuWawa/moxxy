# Contribution Guide

Thanks for your interest in the Moxxy XMPP client! This document contains guidelines and guides for working
on the Moxxy codebase.

## Non-Code Contributions
### Translations

You can contribute to Moxxy by translating parts of Moxxy into a language you can speak. To do that, head over to [Codeberg's Weblate instance](https://translate.codeberg.org/projects/moxxy/moxxy/), where you can start translating.

## Prerequisites

Before building or working on Moxxy, please make sure that your development environment is correctly set up.
Moxxy requires Flutter 3.7.3, since we use a fork of the Flutter library, and the JDK 17. Building Moxxy
is currently only supported for Android.

### Android Studio

If you use Android Studio, make sure that you use version "Flamingo Canary 3", as that one comes bundled with
JDK 17, instead of JDK 11 ([See here](https://codeberg.org/moxxy/moxxy/issues/252)). If that is
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

- [ ] I formatted the code with the dart formatter (`dart format`) before running the linter
- [ ] I ran the linter (`flutter analyze`) and introduced no new linter warnings
- [ ] I ran the tests (`flutter test`) and introduced no new failing tests
- [ ] I used [gitlint](https://github.com/jorisroovers/gitlint) to ensure propper formatting of my commig messages

If you think that your code is ready for a pull request, but you are not sure if it is ready, prefix the PR's title with "WIP: ", so that discussion
can happen there. If you think your PR is ready for review, remove the "WIP: " prefix.

### Tips
#### `data_classes.yaml`

When you add, remove, or modify data classes in `data_classes.yaml`, you need to rebuild the classes using `flutter pub run build_runner build`. However, there appears
to be a bug in my own build runner script, which prevents the data classes from being
rebuilt if they are changed. To fix this, remove the generated data classes by running
`rm lib/shared/*.moxxy.dart`, after which build_runner will rebuild the data classes.

### Code Guidelines
#### Translations

If your code adds new strings that should be translated, only add them to the base
language, which is English. Even if you know more than English, do not add the keys
to other language files. To prevent merge conflicts between Weblate and the repository,
all other languages are managed via [Codeberg's Weblate instance](https://translate.codeberg.org/projects/moxxy/moxxy/).

#### Commit messages

Commit messages should be uniformly formatted. `gitlint` is a linter for commit messages that enforces those guidelines. They are defined in the `.gitlint` file
at the root of the repository. `gitlint` can be installed as a pre-commit hook using
`gitlint install-hook`. That way, `gitlint` runs on every commit and warns you if the
commit message violates any of the defined rules.

Commit messages always follow the following format:

```
<type>(<areas>): <summary>

<full message>
```

`<type>` is the type of action that was performed in the commit and is one of the following: `feat` (Addition of a feature), `fix` (Fix a bug or other issue), `chore` (Bump dependency versions, fix formatter issues), `refactor` (A bigger "moving around" or rewriting of code), `docs` (Commits that just touch the documentation, be it code or, for example, the README).

`<areas>` are the areas inside the code that are touched by the change. They are a comma-separated list of one or more of the following: `service` (Everything inside `lib/service`), `ui` (Everything inside `lib/ui`), `shared` (Everything inside `lib/shared`), `all` (A bit of everything is involved), `tests` (Everyting inside `test` or `integration_test`), `i18n` (The translation files have been modified), `docs` (Documentation of any kind), `flake` (The NixOS flake has been modified).

`<summary>` is the summary of the entire commit in a few words. Make that that the entire
first line is not longer than 72 characters. `<summary>` also must start with an uppercase
letter or a number.

The `<full message>` is optional. In case your commit requires more explanation, write it
there. Make sure that there is an empty line between the full message and the summary line.

The exception to these rules is a commit message of the format `release: Release version x.y.z`, as it touches everything and is thus implicitly using `(all)` as an area code.
