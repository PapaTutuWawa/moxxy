import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';

class RedirectDialog extends StatefulWidget {

  const RedirectDialog(this.callback, this.serviceName, this.initialText, {Key? key}) : super(key: key);
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
        errorText = 'URL cannot be empty';
      });
      return false;
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null) {
      setState(() {
        errorText = 'Invalid URL';
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
      title: Text('${widget.serviceName} Redirect'),
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
          child: const Text('Okay'),
          onPressed: () {
            if (_validateUrl()) {
              Navigator.of(context).pop();
              widget.callback(_controller.text);
              return;
            }
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
