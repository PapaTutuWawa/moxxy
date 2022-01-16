import "package:moxxyv2/xmpp/stringxml.dart";

bool compareXMLNodes(XMLNode actual, XMLNode expectation, { bool ignoreId = true}) {
  // Compare attributes
  if (expectation.tag != actual.tag) return false;

  final attributesEqual = expectation.attributes.keys.every((key) {
      // Ignore the stanza ID
      if (key == "id" && ignoreId) return true;

      return actual.attributes[key] == expectation.attributes[key];
  });
  if (!attributesEqual) return false;
  if (actual.attributes.length != expectation.attributes.length) return false;

  if (expectation.innerText() != "" && actual.innerText() != expectation.innerText()) return false;

  return expectation.children.every((childe) {
      return actual.children.any((childa) => compareXMLNodes(childa, childe));
  });
}
