import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:url_launcher/url_launcher.dart';

part 'licenses.moxxy.dart';

class Library {
  const Library({required this.name, required this.license, required this.url});
  final String name;
  final String license;
  final String url;
}

class LicenseRow extends StatelessWidget {
  const LicenseRow({required this.library, super.key});
  final Library library;

  Future<void> _openUrl() async {
    final result = await launchUrl(
      Uri.parse(library.url),
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (!result) {
      // TODO(Unknown): Show a popup to copy the url
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(library.name),
      subtitle: Text(
        t.pages.settings.licenses.licensedUnder(license: library.license),
      ),
      onTap: _openUrl,
    );
  }
}

class SettingsLicensesPage extends StatelessWidget {
  const SettingsLicensesPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const SettingsLicensesPage(),
        settings: const RouteSettings(
          name: licensesRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.title(t.pages.settings.licenses.title),
      body: ListView.builder(
        itemCount: usedLibraryList.length,
        itemBuilder: (context, index) =>
            LicenseRow(library: usedLibraryList[index]),
      ),
    );
  }
}
