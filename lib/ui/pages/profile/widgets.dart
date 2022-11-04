import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

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
      Key? key,
    }
  ) : super(key: key);
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
    final parts = List<String>.empty(growable: true);
    for (var i = 0; i < 8; i++) {
      final part = fingerprint.substring(i*8, (i+1)*8);
      parts.add(part);
    }

    final width = MediaQuery.of(context).size.width;
    final fontSize = width * 0.04;
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
              Wrap(
                spacing: 6,
                children: parts
                .map((part_) => Text(
                  part_,
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: fontSize,
                  ),
                ),).toList(),
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
