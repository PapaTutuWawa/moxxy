import "package:moxxyv2/xmpp/routing.dart";

import "package:moxxyv2/xmpp/stringxml.dart";

abstract class AuthenticationNegotiator {
  final void Function(String) send;
  final void Function() sendStreamHeader;

  AuthenticationNegotiator({ required this.send, required this.sendStreamHeader });

  Future<RoutingState> next(XMLNode? nonza);
}
