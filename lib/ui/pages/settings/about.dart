import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO(PapaTutuWawa): Include license text
class SettingsAboutPage extends StatefulWidget {
  const SettingsAboutPage({ super.key });

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
            BlocBuilder<PreferencesBloc, PreferencesState>(
              buildWhen: (prev, next) => prev.showDebugMenu != next.showDebugMenu,
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
                    context.read<PreferencesBloc>().add(
                      PreferencesChangedEvent(
                        state.copyWith(
                          showDebugMenu: true,
                        ),
                      ),
                    );

                    await Fluttertoast.showToast(
                      msg: t.pages.settings.about.debugMenuShown,
                      gravity: ToastGravity.SNACKBAR,
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  }
                },
                child:Image.asset(
                  'assets/images/logo.png',
                  width: 200, height: 200,
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
