import 'package:flutter/material.dart';

Future<void> showNotImplementedDialog(String feature, BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Not Implemented"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text("The $feature feature is not yet implemented.")
            ]
          )
        ),
        actions: [
          TextButton(
            child: Text("Okay"),
            onPressed: () => Navigator.of(context).pop()
          )
        ]
      );
    }
  );
}

void dismissSoftKeyboard(BuildContext context) {
  // NOTE: Thank you, https://flutterigniter.com/dismiss-keyboard-form-lose-focus/
  FocusScopeNode current = FocusScope.of(context);
  if (!current.hasPrimaryFocus) {
    current.unfocus();
  }
}
