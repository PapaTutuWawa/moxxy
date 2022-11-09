import 'package:moxxmpp/moxxmpp.dart';

class MoxxyDiscoManager extends DiscoManager {
  @override
  List<Identity> getIdentities() => const [ Identity(category: 'client', type: 'phone', name: 'Moxxy') ];
}
