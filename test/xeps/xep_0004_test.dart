import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/xeps/xep_0004.dart";

import "package:test/test.dart";

void main() {
  test("Parsing", () {
      const testData = "<x xmlns='jabber:x:data' type='result'><field var='FORM_TYPE' type='hidden'><value>urn:xmpp:dataforms:softwareinfo</value></field><field var='ip_version' type='text-multi' ><value>ipv4</value><value>ipv6</value></field><field var='os'><value>Mac</value></field><field var='os_version'><value>10.5.1</value></field><field var='software'><value>Psi</value></field><field var='software_version'><value>0.11</value></field></x>";

      final form = parseDataForm(XMLNode.fromString(testData));
      expect(form.getFieldByVar("FORM_TYPE")?.values.first, "urn:xmpp:dataforms:softwareinfo");
      expect(form.getFieldByVar("ip_version")?.values, [ "ipv4", "ipv6" ]);
      expect(form.getFieldByVar("os")?.values.first, "Mac");
      expect(form.getFieldByVar("os_version")?.values.first, "10.5.1");
      expect(form.getFieldByVar("software")?.values.first, "Psi");
      expect(form.getFieldByVar("software_version")?.values.first, "0.11");
  });
}
