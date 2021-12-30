import "dart:collection";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";

import "package:xml/xml.dart";

class Identity {
  final String category;
  final String type;
  final String name;

  Identity({ required this.category, required this.type, required this.name });
}

class DiscoInfo {
  final List<String> features;
  final List<Identity> identities;

  DiscoInfo({ required this.features, required this.identities });
}

IqStanza buildDiscoQueryStanza(String entity) {
  return IqStanza(to: entity, type: StanzaType.GET, children: [
      XMLNode.xmlns(tag: "query", xmlns: DISCO_INFO_XMLNS)
  ]);
}

DiscoInfo? parseDiscoInfoResponse(XmlElement stanza) {
  final query = stanza.getElement("query");
  if (query == null) return null;

  final List<String> features = List.empty(growable: true);
  final List<Identity> identities = List.empty(growable: true);

  query.childElements.forEach((element) {
      if (element.name.qualified == "feature") {
        features.add(element.getAttribute("var")!);
      } else if (element.name.qualified == "identity") {
        identities.add(Identity(
            category: element.getAttribute("category")!,
            type: element.getAttribute("type")!,
            name: element.getAttribute("name")!
        ));
      } else {
        print("Unknown disco tag: " + element.name.qualified);
      }
  });

  return DiscoInfo(
    features: features,
    identities: identities
  );
}

Future<DiscoInfo?> discoQuery(XmppConnection conn, String entity) async {
  final stanza = await conn.sendStanza(buildDiscoQueryStanza(entity));
  return parseDiscoInfoResponse(stanza);
}
