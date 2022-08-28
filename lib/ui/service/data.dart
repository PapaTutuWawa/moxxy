import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart' as conversation;

// TODO(Unknown): Maybe manage this as a sort-of proxy service between the BLoCs and
//                the event receiver
class UIDataService {

  UIDataService() : isLoggedIn = false;

  bool isLoggedIn;

  String? _ownJid;
  String? get ownJid => _ownJid;
  set ownJid(String? ownJid) {
    _ownJid = ownJid;

    if (ownJid != null) {
      GetIt.I.get<conversation.ConversationBloc>().add(
        conversation.OwnJidReceivedEvent(ownJid),
      );
    }
  }
}
