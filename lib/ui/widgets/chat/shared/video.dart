import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedVideoWidget extends StatelessWidget {

  const SharedVideoWidget(this.path, this.onTap, { this.borderColor, this.child, Key? key }) : super(key: key);
  final String path;
  final Color? borderColor;
  final void Function() onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      const Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
      onTap: onTap,
    );
  }
}
