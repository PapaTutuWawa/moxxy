import "package:moxxyv2/xmpp/routing.dart";

import "package:xml/xml.dart";

abstract class AuthenticationNegotiator {
  final void Function(String) send;
  final void Function() sendStreamHeader;

  AuthenticationNegotiator({ required this.send, required this.sendStreamHeader });

  Future<RoutingState> next(XmlElement? nonza);
}
