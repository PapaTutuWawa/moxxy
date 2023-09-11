import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';

class Intro extends StatelessWidget {
  const Intro({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const Intro(),
        settings: const RouteSettings(
          name: introRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    // TODO(Unknown): Fix the typography
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'moxxy',
                style: TextStyle(
                  fontSize: fontsizeTitle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
              child: Text(
                t.global.moxxySubtitle,
                style: const TextStyle(
                  fontSize: fontsizeBody,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                  .add(const EdgeInsets.only(top: 8)),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pushNamed(
                        loginRoute,
                      ),
                      child: Text(t.pages.intro.loginButton),
                    ),
                  )
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
              child: Text(
                t.pages.intro.noAccount,
                style: const TextStyle(
                  fontSize: fontsizeBody,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: paddingVeryLarge,
                    ).add(const EdgeInsets.only(bottom: paddingVeryLarge)),
                    child: TextButton(
                      child: Text(t.pages.intro.registerButton),
                      onPressed: () {
                        // Navigator.pushNamed(context, registrationRoute);
                        showNotImplementedDialog('registration', context);
                      },
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
