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

  final actualAttributeLength = !ignoreId ? actual.attributes.length : (
    actual.attributes.containsKey("id") ? actual.attributes.length - 1 : actual.attributes.length
  );
  final expectedAttributeLength = !ignoreId ? expectation.attributes.length : (
    expectation.attributes.containsKey("id") ? expectation.attributes.length - 1 : expectation.attributes.length
  );
  if (actualAttributeLength != expectedAttributeLength) return false;

  if (expectation.innerText() != "" && actual.innerText() != expectation.innerText()) return false;

  return expectation.children.every((childe) {
      return actual.children.any((childa) => compareXMLNodes(childa, childe));
  });
}
