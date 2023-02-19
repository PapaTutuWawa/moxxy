import 'package:moxxyv2/shared/events.dart';

// TODO(Unknown): Maybe manage this as a sort-of proxy service between the BLoCs and
//                the event receiver
class UIDataService {
  bool isLoggedIn = false;

  String? _ownJid;
  String? get ownJid => _ownJid;
  set ownJid(String? ownJid) {
    _ownJid = ownJid;
  }

  /// When receiving a PreStartDoneEvent, this function will process it and set
  /// all properties of the UIDataService accordingly.
  void processPreStartDoneEvent(PreStartDoneEvent event) {
    if (event.state == preStartLoggedInState) {
      isLoggedIn = true;
      ownJid = event.jid;
    } else {
      isLoggedIn = false;
      ownJid = null;
    }
  }
}
