// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Like [PopScope] but allows directly passing in a ValueNotifier as to not
/// having to rely on widget rebuilds.
///
/// Parameters are the same as for [PopScope], except for [canPopNotifier].
class PopScopeNotifier extends StatefulWidget {
  const PopScopeNotifier({
    required this.child,
    required this.canPopNotifier,
    this.onPopInvoked,
    super.key,
  });

  final Widget child;

  final PopInvokedCallback? onPopInvoked;

  final ValueNotifier<bool> canPopNotifier;

  @override
  State<PopScopeNotifier> createState() => _PopScopeNotifierState();
}

class _PopScopeNotifierState extends State<PopScopeNotifier>
    implements PopEntry {
  ModalRoute<dynamic>? _route;

  @override
  PopInvokedCallback? get onPopInvoked => widget.onPopInvoked;

  @override
  late final ValueNotifier<bool> canPopNotifier;

  @override
  void initState() {
    super.initState();
    canPopNotifier = widget.canPopNotifier;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? nextRoute = ModalRoute.of(context);
    if (nextRoute != _route) {
      _route?.unregisterPopEntry(this);
      _route = nextRoute;
      _route?.registerPopEntry(this);
    }
  }

  @override
  void dispose() {
    _route?.unregisterPopEntry(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
