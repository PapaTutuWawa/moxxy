import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

class StreamManagementEnableNonza extends XMLNode {
  StreamManagementEnableNonza() : super(
    tag: 'enable',
    attributes: <String, String>{
      'xmlns': smXmlns,
      'resume': 'true'
    },
  );
}

class StreamManagementResumeNonza extends XMLNode {
  StreamManagementResumeNonza(String id, int h) : super(
    tag: 'resume',
    attributes: <String, String>{
      'xmlns': smXmlns,
      'previd': id,
      'h': h.toString()
    },
  );
}

class StreamManagementAckNonza extends XMLNode {
  StreamManagementAckNonza(int h) : super(
    tag: 'a',
    attributes: <String, String>{
      'xmlns': smXmlns,
      'h': h.toString()
    },
  );
}

class StreamManagementRequestNonza extends XMLNode {
  StreamManagementRequestNonza() : super(
    tag: 'r',
    attributes: <String, String>{
      'xmlns': smXmlns,
    },
  );
}
