import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class StreamManagementEnableNonza extends XMLNode {
  StreamManagementEnableNonza() : super(
    tag: "enable",
    attributes: {
      "xmlns": SM_XMLNS,
      "resume": "true"
    }
  );
}

class StreamManagementResumeNonza extends XMLNode {
  StreamManagementResumeNonza(String id, int h) : super(
    tag: "resume",
    attributes: {
      "xmlns": SM_XMLNS,
      "previd": id,
      "h": h.toString()
    }
  );
}

class StreamManagementAckNonza extends XMLNode {
  StreamManagementAckNonza(int h) : super(
    tag: "a",
    attributes: {
      "xmlns": SM_XMLNS,
      "h": h.toString()
    }
  );
}

class StreamManagementRequestNonza extends XMLNode {
  StreamManagementRequestNonza() : super(
    tag: "r",
    attributes: {
      "xmlns": SM_XMLNS,
    }
  );
}
