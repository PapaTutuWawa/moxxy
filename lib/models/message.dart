import "dart:collection";

class Message {
  final String body;
  final String timestamp;
  final String from;

  const Message({ required this.from, required this.body, required this.timestamp });

  Message copyWith({ String? from, String? body, String? timestamp }) {
    return Message(
      from: from ?? this.from,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp
    );
  }
}
  
class MoxxyState {
  final HashMap<String, List<Message>> messages;

  const MoxxyState({ required this.messages });
  MoxxyState.initialState() : messages = HashMap();
}
