import 'package:moxxyv2/shared/models/conversation.dart';

/// Conversion helpers for bool <-> int as sqlite has no "real" booleans
int boolToInt(bool b) => b ? 1 : 0;
bool intToBool(int i) => i == 0 ? false : true;

String boolToString(bool b) => b ? 'true' : 'false';
bool stringToBool(String s) => s == 'true' ? true : false;

String intToString(int i) => '$i';
int stringToInt(String s) => int.parse(s);

String conversationTypeToString(ConversationType type) =>
    type == ConversationType.chat ? 'chat' : 'note';

ConversationType stringToConversationType(String type) {
  switch (type) {
    case 'chat':
      {
        return ConversationType.chat;
      }
    default:
      {
        return ConversationType.note;
      }
  }
}
