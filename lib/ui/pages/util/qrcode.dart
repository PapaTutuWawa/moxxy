import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:moxxyv2/ui/constants.dart';

class QrCodeScanningPage extends StatelessWidget {
  const QrCodeScanningPage({ super.key });

  static MaterialPageRoute<String> get route => MaterialPageRoute<String>(
    builder: (_) => const QrCodeScanningPage(),
    settings: const RouteSettings(
      name: qrCodeScannerRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ReaderWidget(
        onScan: (value) {
          final content = value.textString;
          if (content == null) return;

          final uri = Uri.tryParse(content);
          if (uri == null) return;

          if (uri.scheme == 'xmpp') {
            Vibrate.feedback(FeedbackType.heavy);
            Navigator.of(context).pop(uri.path);
          }
        },
      ),
    );
  }
}
