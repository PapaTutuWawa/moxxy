import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/messaging_textfield.dart';

/// The width and height of the send button.
const double sendButtonSize = 45;

/// The width of the lock button.
const double lockButtonWidth = 45;

/// The width and height of the record button's overlay
const double recordButtonSize = 80;

/// The size of the icons inside the "text field".
const double iconSize = 24;

/// The padding of the icons inside the "text field".
const double _iconPadding = 8;
const EdgeInsets iconPadding = EdgeInsets.all(_iconPadding);

/// The padding of the top-most [ColoredBox] inside the [MobileMessagingTextField].
const double _bottomBarPadding = 8;
const EdgeInsets bottomBarPadding = EdgeInsets.all(_bottomBarPadding);

/// The padding of the [ColoredBox] that represents the text field.
const double _textFieldInnerVerticalPadding = 4;
const double _textFieldInnerHorizontalPadding = 12;
const EdgeInsets textFieldInnerPadding = EdgeInsets.symmetric(
  horizontal: _textFieldInnerHorizontalPadding,
  vertical: _textFieldInnerVerticalPadding,
);

/// The padding of the send button.
const double _sendButtonPaddingLeft = 16;
const double _sendButtonPaddingRight = 8;
const double _sendButtonBottomPadding = (noTextBarHeight - sendButtonSize) / 2;
const EdgeInsets sendButtonPadding = EdgeInsets.only(
  left: _sendButtonPaddingLeft,
  right: _sendButtonPaddingRight,
  bottom: _sendButtonBottomPadding,
);

/// The height of the [MobileMessagingTextField] without any text or quoted messages.
const double noTextBarHeight = 2 * _bottomBarPadding +
    2 * _textFieldInnerVerticalPadding +
    2 * _iconPadding +
    iconSize;

/// The padding of the top icon inside the lock button.
const double _lockButtonTopIconTopPadding = 8;
const EdgeInsets lockButtonTopIconPadding = EdgeInsets.only(
  top: _lockButtonTopIconTopPadding,
);

/// The padding of the bottom icon inside the lock button.
const double _lockButtonBottomIconTopPadding = 4;
const double _lockButtonBottomIconBottomPadding = 8;
const EdgeInsets lockButtonBottomIconPadding = EdgeInsets.only(
  top: _lockButtonBottomIconTopPadding,
  bottom: _lockButtonBottomIconBottomPadding,
);

/// The "bottom" coordinate of the lock button.
const double lockButtonBottomPosition = 250;

/// The height of the lock button.
const double lockButtonHeight = _lockButtonBottomIconTopPadding +
    iconSize +
    _lockButtonTopIconTopPadding +
    iconSize +
    _lockButtonBottomIconBottomPadding;

/// The value to remove from the viewport height to center the record button overlay
/// vertically over the record icon.
const double recordButtonVerticalCenteringOffset =
    noTextBarHeight + (recordButtonSize - noTextBarHeight) / 2;

/// The value to use in the record button overlay's "right" coordinate to center the
/// record button overlay horizontally over the record icon.
const double recordButtonHorizontalCenteringOffset = _sendButtonPaddingRight +
    sendButtonSize +
    _sendButtonPaddingLeft +
    _bottomBarPadding +
    _textFieldInnerHorizontalPadding +
    _iconPadding -
    (recordButtonSize - iconSize) / 2;

/// The value to use as the lock button's "right" coordinate to center it horizontally
/// over the record icon.
const double lockButtonHorizontalCenteringOffset = _sendButtonPaddingRight +
    sendButtonSize +
    _sendButtonPaddingLeft +
    _bottomBarPadding +
    _textFieldInnerHorizontalPadding +
    _iconPadding -
    (lockButtonWidth - iconSize) / 2;

/// Computes the width of the actual [TextField].
double getTextFieldWidth(BuildContext context) =>
    MediaQuery.of(context).size.width -
    bottomBarPadding.left -
    bottomBarPadding.right -
    sendButtonSize -
    sendButtonPadding.left -
    sendButtonPadding.right;

/// The height of the actual [TextField] within the messaging textfield.
const double noTextTextFieldHeight =
    noTextBarHeight - _bottomBarPadding - _bottomBarPadding;
