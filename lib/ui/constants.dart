import 'package:flutter/material.dart';

const Radius radiusLarge = Radius.circular(10);
const Radius radiusSmall = Radius.circular(4);

const double textfieldRadiusRegular = 15;
const double textfieldRadiusConversation = 20;
const EdgeInsetsGeometry textfieldPaddingRegular = EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8);
const EdgeInsetsGeometry textfieldPaddingConversation = EdgeInsets.all(10);

const int primaryColorHexRGBO = 0xffcf4aff;
const int primaryColorAltHexRGB = 0xff9c18cd;
const int primaryColorDisabledHexRGB = 0xff9a7fa9;
const int textColorDisabledHexRGB = 0xffcacaca;
const Color primaryColor = Color(primaryColorHexRGBO);
const Color primaryColorAlt = Color(primaryColorAltHexRGB);
const Color primaryColorDisabled = Color(primaryColorDisabledHexRGB);
const Color textColorDisabled = Color(textColorDisabledHexRGB);

const Color bubbleColorSent = Color(0xffa139f0);
const Color bubbleColorSentQuoted = bubbleColorSent;
const Color bubbleColorReceived = Color(0xff222222);
const Color bubbleColorReceivedQuoted = bubbleColorReceived;
const Color bubbleColorUnencrypted = Color(0xffd40101);

const double paddingVeryLarge = 64;

const Color tileColorDark = Color(0xff5c5c5c);
const Color tileColorLight = Color(0xffcbcbcb);

const double fontsizeTitle = 40;
const double fontsizeSubtitle = 25;
const double fontsizeAppbar = 20;
const double fontsizeBody = 15;
const double fontsizeBodyOnlyEmojis = 30;
const double fontsizeSubbody = 10;

// The translucent black we use when we need to ensure good contrast, for example when
// displaying the download progress indicator.
final backdropBlack = Colors.black.withAlpha(150);

// Navigation constants
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
const String blocklistRoute = '/blocklist';
const String shareSelectionRoute = '/share_selection';
const String serverInfoRoute = '$profileRoute/server_info';
const String devicesRoute = '$profileRoute/devices';
const String ownDevicesRoute = '$profileRoute/own_devices';
