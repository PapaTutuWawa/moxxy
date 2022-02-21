import "package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart";

class MoxxyDiscoManager extends DiscoManager {
  @override
  List<Identity> getIdentities() => const [ Identity(category: "client", type: "phone", name: "Moxxy") ];
}
