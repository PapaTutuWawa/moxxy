import "dart:collection";
import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/data/libraries.dart";
import "package:moxxyv2/data/generated/licenses.dart";

import "package:flutter_settings_ui/flutter_settings_ui.dart";
import "package:url_launcher/url_launcher.dart";

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
      appBar: BorderlessTopbar.simple(title: "Licenses"),
      body: ListView.builder(
        itemCount: usedLibraryList.length,
        itemBuilder: (context, index) => LicenseRow(library: usedLibraryList[index])
      )
    );
  }
}
