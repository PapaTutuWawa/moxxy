import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/negotiators/negotiator.dart";

abstract class SaslNegotiator extends XmppFeatureNegotiatorBase {
  final mechanismName;

  SaslNegotiator(int priority, this.mechanismName) : super(priority, true, saslXmlns);
  
  @override
  bool matchesFeature(List<XMLNode> features) {
    // Is SASL advertised?
    final mechanisms = firstWhereOrNull(
      features,
      (XMLNode feature) => feature.attributes["xmlns"] == saslXmlns,
    );
    if (mechanisms == null) return false;

    // Is SASL PLAIN advertised?
    return firstWhereOrNull(
      mechanisms.children,
      (XMLNode mechanism) => mechanism.text == mechanismName
    ) != null;
  }
}
