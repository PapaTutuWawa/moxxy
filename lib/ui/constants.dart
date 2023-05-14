import 'package:flutter/material.dart';

const Radius radiusLarge = Radius.circular(10);
const Radius radiusSmall = Radius.circular(4);

const double textfieldRadiusRegular = 15;
const double textfieldRadiusConversation = 25;
const EdgeInsetsGeometry textfieldPaddingRegular = EdgeInsets.only(
  top: 4,
  bottom: 4,
  left: 8,
  right: 8,
);

/// The inner TextField padding for the TextField on the ConversationPage.
const EdgeInsetsGeometry textfieldPaddingConversation = EdgeInsets.only(
  top: 12,
  bottom: 12,
  left: 8,
  right: 8,
);

/// The font size for the TextField on the ConversationPage
const double textFieldFontSizeConversation = 18;

const int primaryColorHexRGBO = 0xffcf4aff;
const int primaryColorAltHexRGB = 0xff9c18cd;
const int primaryColorDisabledHexRGB = 0xff9a7fa9;
const int textColorDisabledHexRGB = 0xffcacaca;
const Color primaryColor = Color(primaryColorHexRGBO);
const Color primaryColorAlt = Color(primaryColorAltHexRGB);
const Color primaryColorDisabled = Color(primaryColorDisabledHexRGB);
const Color textColorDisabled = Color(textColorDisabledHexRGB);

/// The color of a quote bubble displayed inside the TextField
const Color bubbleQuoteInTextFieldColorLight = Color(0xffc7c7c7);
const Color bubbleQuoteInTextFieldColorDark = Color(0xff2f2f2f);

/// The color of text inside a quote bubble inside the TextField
const Color bubbleQuoteInTextFieldTextColorLight = Color(0xff373737);
const Color bubbleQuoteInTextFieldTextColorDark = Color(0xffdadada);

/// The text color of the hint text on the ConversationPage
const Color textFieldHintTextColorLight = Color(0xff4a4a4a);
const Color textFieldHintTextColorDark = Color(0xffd6d6d6);

/// The regular text color of the TextField on the ConversationPage
const Color textFieldTextColorLight = Colors.black;
const Color textFieldTextColorDark = Colors.white;

/// The color of a bubble that was sent
const Color bubbleColorSent = Color(0xff7e0bce);

/// The color of the quote widget for a sent quote
const Color bubbleColorSentQuoted = Color(0xff6e0ab4);

/// The color of a bubble that was received
const Color bubbleColorReceived = Color(0xff222222);

/// The color of the quote widget for a received quote
const Color bubbleColorReceivedQuoted = Color(0xff2f2f2f);

/// The color of a bubble when the message is unencrypted while the chat is encrypted
const Color bubbleColorUnencrypted = Color(0xffd40000);

/// The color of a bubble for a pseudo message of type new device
const Color bubbleColorNewDevice = Color(0xffeee8d5);

/// The color of text within a regular bubble
const Color bubbleTextColor = Color(0xffffffff);

/// The color of text within a quote widget
const Color bubbleTextQuoteColor = Color(0xffdadada);

/// The color of the sender name in a quote
const Color bubbleTextQuoteSenderColor = Color(0xffff90ff);

/// The color of the input text field of the conversation page
const Color conversationTextFieldColorLight = Color(0xffe6e6e6);
const Color conversationTextFieldColorDark = Color(0xff414141);

/// The width of the white left border of quote widgets
const double quoteLeftBorderWidth = 4;

/// The background color of the avatar when no actual avatar is available
const Color profileFallbackBackgroundColorLight = Color(0xffc3c3c3);
const Color profileFallbackBackgroundColorDark = Color(0xff424242);

/// The text color of the avatar fallback text
const Color profileFallbackTextColorLight = Color(0xff343434);
const Color profileFallbackTextColorDark = Colors.white;

/// The text color of the buttons in the overlay of the ConversationPage
const Color conversationOverlayButtonTextColor = Color(0xffcf4aff);

const Color settingsSectionTitleColor = Color(0xffb72fe7);

const double paddingVeryLarge = 64;

const Color tileColorDark = Color(0xff5c5c5c);
const Color tileColorLight = Color(0xffcbcbcb);

const double fontsizeTitle = 40;
const double fontsizeSubtitle = 25;
const double fontsizeAppbar = 20;
const double fontsizeBody = 15;
const double fontsizeBodyOnlyEmojis = 30;
const double fontsizeSubbody = 10;

/// The color for a shared media item
final Color sharedMediaItemBackgroundColor = Colors.grey.shade500;

/// The color for a shared media summary
final Color sharedMediaSummaryBackgroundColor = Colors.grey.shade500;

/// The translucent black we use when we need to ensure good contrast, for example when
/// displaying the download progress indicator.
final backdropBlack = Colors.black.withAlpha(150);

/// The height of the emoji/sticker picker.
const double pickerHeight = 300;

/// The color of a reaction that is not from ourselves.
const Color reactionColorReceived = Color(0xff757575);

/// The color of a reaction that is sent by ourselves.
const Color reactionColorSent = Color(0xff2993FB);

/// Navigation constants
const String cropRoute = '/crop';
const String introRoute = '/intro';
const String loginRoute = '/route';
const String registrationRoute = '/registration';
const String postRegistrationRoute = '$registrationRoute/post';
const String conversationsRoute = '/conversations';
const String conversationRoute = '/conversation';
const String sharedMediaRoute = '$conversationRoute/shared_media';
const String profileRoute = '$conversationRoute/profile';
const String sendFilesRoute = '$conversationRoute/send_files';
const String newConversationRoute = '/new_conversation';
const String addContactRoute = '$newConversationRoute/add_contact';
const String settingsRoute = '/settings';
const String licensesRoute = '$settingsRoute/licenses';
const String aboutRoute = '$settingsRoute/about';
const String debuggingRoute = '$settingsRoute/debugging';
const String privacyRoute = '$settingsRoute/privacy';
const String networkRoute = '$settingsRoute/network';
const String backgroundCroppingRoute = '$settingsRoute/appearance/background';
const String conversationSettingsRoute = '$settingsRoute/conversation';
const String appearanceRoute = '$settingsRoute/appearance';
const String stickersRoute = '$settingsRoute/stickers';
const String blocklistRoute = '/blocklist';
const String shareSelectionRoute = '/share_selection';
const String serverInfoRoute = '$profileRoute/server_info';
const String devicesRoute = '$profileRoute/devices';
const String ownDevicesRoute = '$profileRoute/own_devices';
const String qrCodeScannerRoute = '/util/qr_code_scanner';
const String stickerPackRoute = '/stickers/sticker_pack';
