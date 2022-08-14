import 'package:flutter/material.dart';

const Radius radiusLarge = Radius.circular(10);
const Radius radiusSmall = Radius.circular(4);

const double textfieldRadiusRegular = 15;
const double textfieldRadiusConversation = 20;
const EdgeInsetsGeometry textfieldPaddingRegular = EdgeInsets.only(top: 4, bottom: 4, left: 8, right: 8);
const EdgeInsetsGeometry textfieldPaddingConversation = EdgeInsets.all(10);

const int primaryColorHexRGBO = 0xffcf4aff;
const Color primaryColor = Color(primaryColorHexRGBO);

const Color bubbleColorSent = Color(0xffac70ca);
const Color bubbleColorSentQuoted = Color(0xff964db3);
const Color bubbleColorReceived = Color(0xff222222);
const Color bubbleColorReceivedQuoted = Color(0xff2c3e50);

const double paddingVeryLarge = 64;

const double fontsizeTitle = 40;
const double fontsizeSubtitle = 25;
const double fontsizeAppbar = 20;
const double fontsizeBody = 15;
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
const String appearanceRoute = '$settingsRoute/appearance';
const String backgroundCroppingRoute = '$settingsRoute/appearance/background';
const String blocklistRoute = '/blocklist';
