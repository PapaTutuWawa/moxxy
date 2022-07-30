import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:url_launcher/url_launcher.dart';

part 'licenses.moxxy.dart';

class Library {

  const Library({ required this.name, required this.license, required this.url });
  final String name;
  final String license;
  final String url;
}

class LicenseRow extends StatelessWidget {

  const LicenseRow({ required this.library, Key? key }) : super(key: key);
  final Library library;

  Future<void> _openUrl() async {
    if (!await launchUrl(Uri.parse(library.url))) {
      // TODO(Unknown): Show a popup to copy the url
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(library.name),
      subtitle: Text('Licensed under ${library.license}'),
      onTap: _openUrl,
   );
  }
}

class SettingsLicensesPage extends StatelessWidget {
  const SettingsLicensesPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(builder: (_) => const SettingsLicensesPage());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple('Licenses'),
      body: ListView.builder(
        itemCount: usedLibraryList.length,
        itemBuilder: (context, index) => LicenseRow(library: usedLibraryList[index]),
      ),
    );
  }
}
