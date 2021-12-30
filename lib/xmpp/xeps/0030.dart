import "dart:collection";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";

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

DiscoInfo? parseDiscoInfoResponse(XMLNode stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return null;

  final List<String> features = List.empty(growable: true);
  final List<Identity> identities = List.empty(growable: true);

  query.children.forEach((element) {
      if (element.tag == "feature") {
        features.add(element.attributes["var"]!);
      } else if (element.tag == "identity") {
        identities.add(Identity(
            category: element.attributes["category"]!,
            type: element.attributes["type"]!,
            name: element.attributes["name"]!
        ));
      } else {
        print("Unknown disco tag: " + element.tag);
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
