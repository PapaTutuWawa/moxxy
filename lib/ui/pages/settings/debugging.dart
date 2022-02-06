import "package:moxxyv2/ui/widgets/topbar.dart";

import "package:flutter/material.dart";
import "package:flutter_settings_ui/flutter_settings_ui.dart";

class DebuggingPage extends StatelessWidget {
  final TextEditingController _ipController;
  final TextEditingController _passphraseController;

  DebuggingPage({ Key? key }) : _ipController = TextEditingController(), _passphraseController = TextEditingController(), super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Debugging"),
      body: SettingsList(
        contentPadding: const EdgeInsets.all(16.0),
        sections: [
          SettingsSection(
            title: "General",
            tiles: [
              SettingsTile.switchTile(
                title: "Enable debugging",
                onToggle: (value) {},
                switchValue: false
              ),
              SettingsTile(
                title: "Encryption password",
                subtitle: "The logs may contain sensitive information so pick a strong passphrase",
                subtitleMaxLines: 2,
                onPressed: (context) {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text("Debug Passphrase"),
                      content: TextField(
                        maxLines: 1,
                        minLines: 1,
                        obscureText: true,
                        controller: _passphraseController
                      ),
                      actions: [
                        TextButton(
                          child: const Text("Okay"),
                          onPressed: () => Navigator.of(context).pop()
                        )
                      ]
                    )
                  );
                }
              ),
              SettingsTile(
                title: "Logging IP",
                subtitle: "The IP the logs should be sent to",
                subtitleMaxLines: 2,
                onPressed: (context) {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text("Logging IP"),
                      content: TextField(
                        maxLines: 1,
                        minLines: 1,
                        controller: _ipController
                      ),
                      actions: [
                        TextButton(
                          child: const Text("Okay"),
                          onPressed: () => Navigator.of(context).pop()
                        )
                      ]
                    )
                  );
                }
              )
            ]
          )
        ]
      )
    );
  }
}
