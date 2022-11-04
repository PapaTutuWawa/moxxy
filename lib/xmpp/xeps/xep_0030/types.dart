import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0004.dart';

class Identity {

  const Identity({ required this.category, required this.type, this.name, this.lang });
  final String category;
  final String type;
  final String? name;
  final String? lang;

  XMLNode toXMLNode() {
    return XMLNode(
      tag: 'identity',
      attributes: <String, dynamic>{
        'category': category,
        'type': type,
        'name': name,
        ...lang == null ? <String, dynamic>{} : <String, dynamic>{ 'xml:lang': lang }
      },
    );
  }
}

class DiscoInfo {

  const DiscoInfo(
    this.features,
    this.identities,
    this.extendedInfo,
    this.jid,
  );
  final List<String> features;
  final List<Identity> identities;
  final List<DataForm> extendedInfo;
  final JID jid;
}

class DiscoItem {

  const DiscoItem({ required this.jid, this.node, this.name });
  final String jid;
  final String? node;
  final String? name;
}
