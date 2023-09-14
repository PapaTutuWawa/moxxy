import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:moxxyv2/ui/constants.dart';

typedef QrCodeScanningValidatorCallback = bool Function(String? value);

class QrCodeScanningArguments {
  const QrCodeScanningArguments(this.validator);
  final QrCodeScanningValidatorCallback validator;
}

class QrCodeScanningPage extends StatelessWidget {
  const QrCodeScanningPage(this.args, {super.key});
  final QrCodeScanningArguments args;

  static MaterialPageRoute<String> getRoute(QrCodeScanningArguments args) =>
      MaterialPageRoute<String>(
        builder: (_) => QrCodeScanningPage(args),
        settings: const RouteSettings(
          name: qrCodeScannerRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReaderWidget(
        onScan: (value) {
          final content = value.text;
          if (args.validator(content)) {
            Vibrate.feedback(FeedbackType.heavy);
            Navigator.of(context).pop(content);
          }
        },
      ),
    );
  }
}
