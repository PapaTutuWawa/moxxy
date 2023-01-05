import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO(PapaTutuWawa): Include license text
class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const SettingsAboutPage(),
    settings: const RouteSettings(
      name: aboutRoute,
    ),
  );
  
  Future<void> _openUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      // TODO(Unknown): Show a popup to copy the url
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(t.pages.settings.about.title),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200, height: 200,
            ),
            Text(
              t.global.title,
              style: const TextStyle(
                fontSize: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t.global.moxxySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                // TODO(Unknown): Generate this at build time
                t.pages.settings.about.version(
                  version: '0.4.0',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),

            Text(t.pages.settings.about.licensed),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                child: Text(t.pages.settings.about.viewSourceCode),
                onPressed: () => _openUrl('https://github.com/PapaTutuWawa/moxxyv2'),
              ),
            ) 
          ],
        ),
      ),
    );
  }
}
