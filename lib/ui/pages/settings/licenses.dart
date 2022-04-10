import "package:flutter/material.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/data/libraries.dart";
import "package:moxxyv2/ui/data/generated/licenses.g.dart";

import "package:url_launcher/url_launcher.dart";

class LicenseRow extends StatelessWidget {
  final Library library;

  const LicenseRow({ required this.library, Key? key }) : super(key: key);

  void _openUrl() async {
    if (!await launch(library.url)) {
      // TODO: Show a popup to copy the url
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(library.name),
      subtitle: Text("Licensed under " + library.license),
      onTap: _openUrl
   );
  }
}

class SettingsLicensesPage extends StatelessWidget {
  const SettingsLicensesPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple("Licenses"),
      body: ListView.builder(
        itemCount: usedLibraryList.length,
        itemBuilder: (context, index) => LicenseRow(library: usedLibraryList[index])
      )
    );
  }
}
