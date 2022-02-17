import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class Identity {
  final String category;
  final String type;
  final String name;
  final String? lang;

  const Identity({ required this.category, required this.type, required this.name, this.lang });

  XMLNode toXMLNode() {
    return XMLNode(
      tag: "identity",
      attributes: {
        "category": category,
        "type": type,
        "name": name,
        ...(lang == null ? {} : { "xml:lang": lang!})
      }
    );
  }
}

class DiscoInfo {
  final List<String> features;
  final List<Identity> identities;
  final Map<String, List<String>>? extendedInfo;

  const DiscoInfo({ required this.features, required this.identities, this.extendedInfo });
}

class DiscoItem {
  final String jid;
  final String node;
  final String? name;

  const DiscoItem({ required this.jid, required this.node, required this.name });
}

DiscoInfo? parseDiscoInfoResponse(XMLNode stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return null;

  final error = stanza.firstTag("error");
  if (error != null && stanza.attributes["type"] == "error") {
    //print("Disco Items error: " + error.toXml());
    return null;
  }
  
  final List<String> features = List.empty(growable: true);
  final List<Identity> identities = List.empty(growable: true);

  for (var element in query.children) {
    if (element.tag == "feature") {
      features.add(element.attributes["var"]!);
    } else if (element.tag == "identity") {
      identities.add(Identity(
          category: element.attributes["category"]!,
          type: element.attributes["type"]!,
          name: element.attributes["name"]!
      ));
    } else {
      //print("Unknown disco tag: " + element.tag);
    }
  }

  // TODO: Include extendedInfo
  return DiscoInfo(
    features: features,
    identities: identities
  );
}

List<DiscoItem>? parseDiscoItemsResponse(Stanza stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return null;

  final error = stanza.firstTag("error");
  if (error != null && stanza.type == "error") {
    //print("Disco Items error: " + error.toXml());
    return null;
  }

  // TODO: Include extendedInfo; depends on support for XEP-0004
  return query.findTags("item").map((node) => DiscoItem(
      jid: node.attributes["jid"]!,
      node: node.attributes["node"]!,
      name: node.attributes["name"]
  )).toList();
}

Stanza buildDiscoInfoQueryStanza(String entity, String? node) {
  return Stanza.iq(to: entity, type: "get", children: [
      XMLNode.xmlns(
        tag: "query",
        xmlns: discoInfoXmlns,
        attributes: node != null ? { "node": node } : {}
      )
  ]);
}

Stanza buildDiscoItemsQueryStanza(String entity, { String? node }) {
  return Stanza.iq(to: entity, type: "get", children: [
      XMLNode.xmlns(
        tag: "query",
        xmlns: discoItemsXmlns,
        attributes: node != null ? { "node": node } : {}
      )
  ]);
}
