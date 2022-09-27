import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

enum MessageProcessingHint {
  noPermanentStore,
  noStore,
  noCopies,
  store,
}

/// NOTE: We do not define a function for turning a Message Processing Hint element into
///       an enum value since the elements do not concern us as a client.
extension XmlExtension on MessageProcessingHint {
  XMLNode toXml() {
    String tag;
    switch (this) {
      case MessageProcessingHint.noPermanentStore:
        tag = 'no-permanent-store';
        break;
      case MessageProcessingHint.noStore:
        tag = 'no-store';
        break;
      case MessageProcessingHint.noCopies:
        tag = 'no-copy';
        break;
      case MessageProcessingHint.store:
        tag = 'store';
        break;
    }

    return XMLNode.xmlns(
      tag: tag,
      xmlns: messageProcessingHintsXmlns,
    );
  }
}
