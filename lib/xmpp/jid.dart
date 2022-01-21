abstract class JID {
  final String local;
  final String domain;
  final String resource;

  JID({ required this.local, required this.domain, required this.resource });
}

class BareJID extends JID {
  BareJID({ required String local, required String domain }) : super(local: local, domain: domain, resource: "");

  static BareJID fromString(String bareJid) {
    final index = bareJid.indexOf("/");
    if (index != -1) {
      bareJid = bareJid.substring(0, index);
    }

    final jidParts = bareJid.split("@");
    return BareJID(local: jidParts[0], domain: jidParts[1]);
  }

  FullJID withResource(String resource) {
    return FullJID(local: local, domain: domain, resource: resource);
  }

  @override
  String toString() {
    return "$local@$domain";
  }
}

class FullJID extends JID {
  FullJID({ required String local, required String domain, required String resource }) : super(local: local, domain: domain, resource: resource);
  
  BareJID toBare() {
    return BareJID(local: local, domain: domain);
  }

  static FullJID fromString(String fullJid) {
    final jidParts = fullJid.split("@");
    final other = jidParts[1].split("/");
    return FullJID(local: jidParts[0], domain: other[0], resource: other[1]);
  }

  @override
  String toString() {
    return "$local@$domain/$resource";
  }
}
