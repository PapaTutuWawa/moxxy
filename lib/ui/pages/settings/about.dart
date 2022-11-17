import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO(PapaTutuWawa): Include license text
// TODO(Unknown): Maybe include the version number
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
      appBar: BorderlessTopbar.simple('About'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200, height: 200,
            ),
            const Text(
              'moxxy',
              style: TextStyle(
                fontSize: 40,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'An experimental XMPP client that is beautiful, modern and easy to use',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
            const Text('Licensed under GPL3'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                child: const Text('View source code'),
                onPressed: () => _openUrl('https://github.com/PapaTutuWawa/moxxyv2'),
              ),
            ) 
          ],
        ),
      ),
    );
  }
}
