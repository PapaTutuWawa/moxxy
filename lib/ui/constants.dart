import "package:flutter/widgets.dart";

const Radius radiusLarge = Radius.circular(10);
const Radius radiusSmall = Radius.circular(4);

const double textfieldRadiusRegular = 15;
const double textfieldRadiusConversation = 20;
const EdgeInsetsGeometry textfieldPaddingRegular = EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0);
const EdgeInsetsGeometry textfieldPaddingConversation = EdgeInsets.all(10);

const int primaryColorHexRGBO = 0xffcf4aff;
const Color primaryColor = Color(primaryColorHexRGBO);

const Color bubbleColorSent = primaryColor;
const Color bubbleColorReceived = Color.fromRGBO(44, 62, 80, 1.0);

const double paddingVeryLarge = 64.0;

const double fontsizeTitle = 40;
const double fontsizeSubtitle = 25;
const double fontsizeAppbar = 20;
const double fontsizeBody = 15;
const double fontsizeSubbody = 10;

// Navigation constants
const String introRoute = "/intro";
const String loginRoute = "/route";
const String registrationRoute = "/registration";
const String postRegistrationRoute = registrationRoute + "/post";
const String conversationsRoute = "/conversations";
const String conversationRoute = "/conversation";
const String profileRoute = conversationRoute + "/profile";
const String sendFilesRoute = conversationRoute + "/send_files";
const String newConversationRoute = "/new_conversation";
const String addContactRoute = newConversationRoute + "/add_contact";
const String settingsRoute = "/settings";
const String licensesRoute = settingsRoute + "/licenses";
const String aboutRoute = settingsRoute + "/about";
const String debuggingRoute = settingsRoute + "/debugging";
