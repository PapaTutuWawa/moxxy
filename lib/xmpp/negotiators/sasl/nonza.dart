import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

class SaslAuthNonza extends XMLNode {
  SaslAuthNonza(String mechanism, String body) : super(
    tag: 'auth',
    attributes: <String, String>{
      'xmlns': saslXmlns,
      'mechanism': mechanism ,
    },
    text: body,
  );
}
