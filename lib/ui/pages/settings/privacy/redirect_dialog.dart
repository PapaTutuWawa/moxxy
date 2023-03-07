import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';

class RedirectDialog extends StatefulWidget {
  const RedirectDialog(
    this.callback,
    this.serviceName,
    this.initialText, {
    super.key,
  });
  final void Function(String url) callback;
  final String serviceName;
  final String initialText;

  @override
  RedirectDialogState createState() => RedirectDialogState();
}

class RedirectDialogState extends State<RedirectDialog> {
  RedirectDialogState() : _controller = TextEditingController();
  final TextEditingController _controller;
  String? errorText;

  bool _validateUrl() {
    final value = _controller.text;

    if (value.isEmpty) {
      setState(() {
        errorText = t.pages.settings.privacy.urlEmpty;
      });
      return false;
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null) {
      setState(() {
        errorText = t.pages.settings.privacy.urlInvalid;
      });
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();

    _controller.text = widget.initialText;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(radiusLarge),
      ),
      title: Text(
        t.pages.settings.privacy
            .redirectDialogTitle(serviceName: widget.serviceName),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              cornerRadius: textfieldRadiusRegular,
              borderColor: primaryColor,
              borderWidth: 1,
              enableIMEFeatures: false,
              controller: _controller,
              errorText: errorText,
              hintText: 'URL',
              onChanged: (value) {
                // Reset the error message if it was set
                if (errorText != null) {
                  setState(() {
                    errorText = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(t.global.dialogAccept),
          onPressed: () {
            if (_validateUrl()) {
              Navigator.of(context).pop();
              widget.callback(_controller.text);
              return;
            }
          },
        ),
        TextButton(
          child: Text(t.global.dialogCancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
