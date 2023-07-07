import 'package:moxxyv2/shared/models/conversation.dart';

/// Conversion helpers for bool <-> int as sqlite has no "real" booleans
int boolToInt(bool b) => b ? 1 : 0;
bool intToBool(int i) => i == 0 ? false : true;

String boolToString(bool b) => b ? 'true' : 'false';
bool stringToBool(String s) => s == 'true' ? true : false;

String intToString(int i) => '$i';
int stringToInt(String s) => int.parse(s);

String conversationTypeToString(ConversationType type) {
  switch (type) {
    case ConversationType.chat:
      {
        return 'chat';
      }
    case ConversationType.note:
      {
        return 'note';
      }
    case ConversationType.groupchat:
      {
        return 'groupchat';
      }
  }
}

ConversationType stringToConversationType(String type) {
  switch (type) {
    case 'chat':
      {
        return ConversationType.chat;
      }
    case 'note':
      {
        return ConversationType.note;
      }
    default:
      {
        return ConversationType.groupchat;
      }
  }
}

/// Given a map [map], extract all key-value pairs from [map] where the key starts with
/// [prefix]. Combine those key-value pairs into a new map, where the leading [prefix]
/// is removed from all key names.
Map<String, T> getPrefixedSubMap<T>(Map<String, T> map, String prefix) {
  return Map<String, T>.fromEntries(
    map.entries.where((entry) => entry.key.startsWith(prefix)).map(
          (entry) => MapEntry<String, T>(
            entry.key.substring(prefix.length),
            entry.value,
          ),
        ),
  );
}
