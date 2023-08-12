import 'package:flutter/widgets.dart';

/// Widget that calls a given callback after the first frame has been rendered.
class PostBuildWidget extends StatefulWidget {
  const PostBuildWidget({
    required this.child,
    required this.postBuild,
    super.key,
  });

  final Widget child;

  final void Function() postBuild;

  @override
  PostBuildWidgetState createState() => PostBuildWidgetState();
}

class PostBuildWidgetState extends State<PostBuildWidget> {
  bool _hasBuilt = false;

  @override
  Widget build(BuildContext context) {
    if (!_hasBuilt) {
      _hasBuilt = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.postBuild(),
      );
    }

    return widget.child;
  }
}
