# moxxy

An experimental XMPP client that tries to be as easy, modern and beautiful as possible.

## Screenshots

![screenshots](./assets/repo/title.png)

## Developing and Building

Clone using `git clone --recursive https://github.com/Polynomdivision/moxxyv2.git`.

Run `nix develop` to get a development shell. Before the first build, run `make data` and
`make data` and `flutter pub run build_runner build` to generate the data classes. After
that, you can run the app using `flutter run` or build the app with `flutter build`.

After implementing a change or a feature, please ensure that nothing is broken by the change
by running `flutter test` afterwards. Also make sure that the code passes the linter by
running `flutter analyze`. This project also uses [gitlint](https://github.com/jorisroovers/gitlint)
to ensure uniform formatting of commit messages.

## A Bit of History

This project is the successor of moxxyv1, which was written in *React Native* and abandoned
due to various technical issues.

## License

See `./LICENSE`.

## Special Thanks

- New logo designed by [Synoh](https://twitter.com/synoh_manda)
