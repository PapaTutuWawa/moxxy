import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/shared/version.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/state/preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SpecialThanksText extends StatelessWidget {
  const SpecialThanksText(
    this.prefix,
    this.name,
    this.url, {
    super.key,
  });

  /// Prefix text, like "Designed by". A space is automatically appended.
  final String prefix;

  /// The name of the person to thank.
  final String name;

  /// The URL to open upon clicking the name.
  final String url;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$prefix ',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          TextSpan(
            text: name,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrlString(
                    url,
                    mode: LaunchMode.externalApplication,
                  ),
          ),
        ],
      ),
    );
  }
}

// TODO(PapaTutuWawa): Include license text
class SettingsAboutPage extends StatefulWidget {
  const SettingsAboutPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const SettingsAboutPage(),
        settings: const RouteSettings(
          name: aboutRoute,
        ),
      );

  @override
  SettingsAboutPageState createState() => SettingsAboutPageState();
}

class SettingsAboutPageState extends State<SettingsAboutPage> {
  /// The amount of taps on the Moxxy logo, if showDebugMenu is false
  int _counter = 0;

  /// True, if the toast ("You're already a developer") has already been shown once.
  bool _alreadyShownNotificationShown = false;

  Future<void> _openUrl(String url) async {
    if (!(await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ))) {
      // TODO(Unknown): Show a popup to copy the url
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.settings.about.title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
        child: Column(
          children: [
            BlocBuilder<PreferencesCubit, PreferencesState>(
              buildWhen: (prev, next) =>
                  prev.showDebugMenu != next.showDebugMenu,
              builder: (context, state) => InkWell(
                onTap: () async {
                  if (state.showDebugMenu) {
                    if (_counter == 0 && !_alreadyShownNotificationShown) {
                      _alreadyShownNotificationShown = true;
                      await Fluttertoast.showToast(
                        msg: t.pages.settings.about.debugMenuAlreadyShown,
                        gravity: ToastGravity.SNACKBAR,
                        toastLength: Toast.LENGTH_SHORT,
                      );
                    }

                    return;
                  }

                  _counter++;
                  if (_counter == 10) {
                    await context.read<PreferencesCubit>().change(
                          state.copyWith(
                            showDebugMenu: true,
                          ),
                        );

                    await Fluttertoast.showToast(
                      msg: t.pages.settings.about.debugMenuShown,
                      gravity: ToastGravity.SNACKBAR,
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  }
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
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
                t.pages.settings.about.version(
                  version: pubspecVersionString,
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
                onPressed: () => _openUrl('https://codeberg.org/moxxy/moxxy'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SpecialThanksText(
                t.pages.settings.about.specialThanks.iconDesignedBy,
                'Synoh',
                'https://mastodon.art/@Synoh',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SpecialThanksText(
                t.pages.settings.about.specialThanks.uiDesignedBy,
                'Ailyaut',
                'https://ailyaut.robotfumeur.fr/',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
