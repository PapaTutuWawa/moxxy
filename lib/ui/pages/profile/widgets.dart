import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

String _formatHalfFingerprint(String half) {
  final p1 = half.substring(0, 8);
  final p2 = half.substring(8, 16);
  final p3 = half.substring(16, 32);

  return '$p1 $p2 $p3';
}

class FingerprintListItem extends StatelessWidget {
  const FingerprintListItem(
    this.fingerprint,
    this.enabled,
    this.verified,
    this.hasVerifiedKeys,
    {
      this.onVerifiedPressed,
      this.onEnableValueChanged,
      this.onShowQrCodePressed,
      this.onDeletePressed,
      super.key,
    }
  );
  final String fingerprint;
  final bool enabled;
  final bool verified;
  final bool hasVerifiedKeys;
  final void Function()? onVerifiedPressed;
  final void Function(bool value)? onEnableValueChanged;
  final void Function()? onShowQrCodePressed;
  final void Function()? onDeletePressed;
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fontSize = width * 0.1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(textfieldRadiusRegular),
        ),
        color: !verified && hasVerifiedKeys ? Colors.red : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                _formatHalfFingerprint(fingerprint.substring(0, 32)),
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: fontSize,
                ),
                maxLines: 1,
              ),
              AutoSizeText(
                _formatHalfFingerprint(fingerprint.substring(32)),
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: fontSize,
                ),
                maxLines: 1,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ...onEnableValueChanged != null ?
                    [
                      Switch(
                        value: enabled,
                        onChanged: onEnableValueChanged,
                      ),
                    ] :
                    [],
                  ...onVerifiedPressed != null ?
                    [
                      IconButton(
                        icon: Icon(
                          verified ?
                            Icons.verified_user :
                            Icons.qr_code_scanner,
                        ),
                        onPressed: onVerifiedPressed,
                      ),
                    ] :
                    [],
                  ...onShowQrCodePressed != null ?
                    [
                      IconButton(
                        icon: const Icon(Icons.qr_code),
                        onPressed: onShowQrCodePressed,
                      ),
                    ] :
                    [],
                  ...onDeletePressed != null ?
                    [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: onDeletePressed,
                      ),
                    ] :
                    [],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
