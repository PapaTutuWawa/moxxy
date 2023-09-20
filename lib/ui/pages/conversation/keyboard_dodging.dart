import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:moxxyv2/ui/helpers.dart';

/// A triple of data for the child widget wrapper widget.
class KeyboardReplacerData {
  const KeyboardReplacerData(
    this.visible,
    this.height,
    this.showWidget,
  );

  /// Flag indicating whether the keyboard is visible or not.
  final bool visible;

  /// The height of the keyboard.
  final double height;

  /// Flag indicating whether the widget should be shown or not.
  final bool showWidget;
}

/// A controller to interact with the child wrapper widget.
class KeyboardReplacerController {
  KeyboardReplacerController() {
    _keyboardVisible = _keyboardController.isVisible;
    _keyboardVisibilitySubscription =
        _keyboardController.onChange.listen((visible) {
      // Only update when the state actually changed
      if (visible == _keyboardVisible) {
        return;
      }

      if (visible) {
        _widgetVisible = false;
      }

      _keyboardVisible = visible;
      _streamController.add(
        KeyboardReplacerData(
          visible,
          _keyboardHeight,
          _widgetVisible,
        ),
      );
    });

    _keyboardHeightSubscription =
        const EventChannel('org.moxxy.moxxyv2/keyboard_stream')
            .receiveBroadcastStream()
            .cast<double>()
            .listen(
      (height) {
        // Only update when the height actually changed
        if (height == 0 || height == _keyboardHeight) return;

        _keyboardHeight = height;
        _streamController.add(
          KeyboardReplacerData(
            _keyboardVisible,
            height,
            _widgetVisible,
          ),
        );
      },
    );
  }

  /// State of the child widget's visibility.
  bool _widgetVisible = false;

  /// Data for keeping track of the keyboard visibility.
  final KeyboardVisibilityController _keyboardController =
      KeyboardVisibilityController();
  late final StreamSubscription<bool> _keyboardVisibilitySubscription;

  /// Flag indicating whether the keyboard is currently visible or not.
  late bool _keyboardVisible;

  /// Data for keeping track of the keyboard height.
  late final StreamSubscription<double> _keyboardHeightSubscription;

  /// The currently tracked keyboard height.
  /// NOTE: The value is a random keyboard height I got on my test device.
  // TODO(Unknown): Maybe make this platform specific.
  double _keyboardHeight = 260;

  /// The stream for building the child widget wrapper.
  final StreamController<KeyboardReplacerData> _streamController =
      StreamController<KeyboardReplacerData>.broadcast();
  Stream<KeyboardReplacerData> get stream => _streamController.stream;

  /// Get the currently tracked data.
  KeyboardReplacerData get currentData => KeyboardReplacerData(
        _keyboardVisible,
        _keyboardHeight,
        _widgetVisible,
      );

  void dispose() {
    _keyboardVisibilitySubscription.cancel();
    _keyboardHeightSubscription.cancel();
  }

  /// Show the child widget in the child wrapper. If the soft-keyboard is currently
  /// visible, dismiss it.
  void showWidget(BuildContext context) {
    _widgetVisible = true;
    if (_keyboardVisible) {
      dismissSoftKeyboard(context);
    }

    // Notify the child widget wrapper
    _streamController.add(
      KeyboardReplacerData(
        false,
        _keyboardHeight,
        true,
      ),
    );
  }

  /// Hide the child widget. If [summonKeyboard] is true, then the soft-keyboard is
  /// summoned.
  void hideWidget({bool summonKeyboard = false}) {
    _widgetVisible = false;
    _streamController.add(
      KeyboardReplacerData(
        summonKeyboard,
        _keyboardHeight,
        false,
      ),
    );
  }

  /// Toggle between (Widget visible, keyboard hidden) and (Widget hidden, keyboard shown).
  /// Requires the FocusNode [focusNode] of the Textfield.
  void toggleWidget(BuildContext context, FocusNode focusNode) {
    if (_widgetVisible) {
      hideWidget(summonKeyboard: true);
      focusNode.requestFocus();
    } else {
      showWidget(context);
    }
  }
}

/// A widget for wrapping a given child that should be switching places with the
/// soft-keyboard.
class KeyboardReplacerWidget extends StatelessWidget {
  const KeyboardReplacerWidget(this.controller, this.child, {super.key});

  /// A controller that feeds this widget with data.
  final KeyboardReplacerController controller;

  /// The child to show or not show.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KeyboardReplacerData>(
      initialData: controller.currentData,
      stream: controller.stream,
      builder: (context, snapshot) {
        return SizedBox(
          height: snapshot.data!.visible || snapshot.data!.showWidget
              ? snapshot.data!.height
              : 0,
          width: MediaQuery.of(context).size.width,
          child: Offstage(
            offstage: !snapshot.data!.showWidget,
            child: child,
          ),
        );
      },
    );
  }
}

/// An alternative to the regular Scaffold that allows keyboard dodging with a widget
/// that switches places with the soft-keyboard.
class KeyboardReplacerScaffold extends StatelessWidget {
  const KeyboardReplacerScaffold({
    required this.controller,
    required this.children,
    required this.appbar,
    required this.keyboardWidget,
    required this.background,
    required this.extraStackChildren,
    super.key,
  });

  /// The KeyboardReplacerController for the keyboard "dodging".
  final KeyboardReplacerController controller;

  /// The body of the scaffold.
  final List<Widget> children;

  /// The widget that can switch places with the soft-keyboard.
  final Widget keyboardWidget;

  /// The app bar.
  final Widget appbar;

  /// The background of the "scaffold". Useful for displaying a background image.
  final Widget background;

  final List<Widget>? extraStackChildren;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final headerHeight = mq.viewPadding.top;
    return Stack(
      children: [
        // The background should not move when we dodge the keyboard
        Positioned(
          // Do not leak under the system UI
          top: headerHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: background,
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            bottom: false,
            child: Material(
              color: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  appbar,
                  ...children,
                  KeyboardReplacerWidget(
                    controller,
                    keyboardWidget,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (extraStackChildren != null) ...extraStackChildren!,
      ],
    );
  }
}
