import "dart:collection";
import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";

import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:url_launcher/url_launcher.dart";

// TODO: Maybe also include the License text

class Library {
  final String name;
  final String license;
  final String url;

  const Library({ required this.name, required this.license, required this.url });
}

// TODO: Maybe generate this list during build
const List<Library> _USED_LIBRARIES = [
  Library(
    name: "flutter_settings_ui",
    license: "Apache-2.0",
    url: "https://github.com/juliansteenbakker/flutter_settings_ui"
  ),
  Library(
    name: "flutter_speed_dial",
    license: "MIT",
    url: "https://github.com/darioielardi/flutter_speed_dial"
  ),
  Library(
    name: "get_it",
    license: "MIT",
    url: "https://github.com/fluttercommunity/get_it"
  ),
  Library(
    name: "redux",
    license: "MIT",
    url: "https://github.com/fluttercommunity/redux.dart"
  ),
  Library(
    name: "flutter_redux",
    license: "MIT",
    url: "https://github.com/brianegan/flutter_redux"
  ),
  Library(
    name: "badges",
    license: "Apache-2.0",
    url: "https://github.com/yadaniyil/flutter_badges"
  ),
  Library(
    name: "url_launcher",
    license: "BSD-3-Clause",
    url: "https://github.com/flutter/plugins/tree/master/packages/url_launcher/url_launcher"
  )
];

class LicenseRow extends StatelessWidget {
  final Library library;

  LicenseRow({ required this.library });

  void _openUrl() async {
    if (!await launch(this.library.url)) {
      // TODO: Show a popup to copy the url
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(this.library.name),
      subtitle: Text("Licensed under " + this.library.license),
      // TODO
      onTap: this._openUrl
   );
  }
}

class SettingsLicensesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton()
          ]
        )
      ),
      body: ListView.builder(
        itemCount: _USED_LIBRARIES.length,
        itemBuilder: (context, index) => LicenseRow(library: _USED_LIBRARIES[index])
      )
    );
  }
}
