import "package:moxxyv2/xmpp/xeps/0030.dart";
import "package:moxxyv2/xmpp/xeps/0115.dart";

import "package:test/test.dart";

void main() {
  test("Test XEP example", () async {
      final data = DiscoInfo(
        features: [
          "http://jabber.org/protocol/caps",
          "http://jabber.org/protocol/disco#info",
          "http://jabber.org/protocol/disco#items",
          "http://jabber.org/protocol/muc"
        ],
        identities: [
          Identity(
            category: "client",
            type: "pc",
            name: "Exodus 0.9.1"
          )
        ]
      );

      final hash = await calculateCapabilityHash(data);
      expect(hash, "QgayPKawpkPSDYmwT/WM94uAlu0=");
  });

  test("Test complex generation example", () async {
      final data = DiscoInfo(
        identities: [
          Identity(
            category: "client",
            type: "pc",
            name: "Psi 0.11",
            lang: "en"
          ),
          Identity(
            category: "client",
            type: "pc",
            name: "Ψ 0.11",
            lang: "el"
          ),
        ],
        features: [
          "http://jabber.org/protocol/caps",
          "http://jabber.org/protocol/disco#info",
          "http://jabber.org/protocol/disco#items",
          "http://jabber.org/protocol/muc"
        ],
        extendedInfo: {
          "FORM_TYPE": [ "urn:xmpp:dataforms:softwareinfo" ],
          "ip_version": [ "ipv4", "ipv6" ],
          "os": [ "Mac" ],
          "os_version": [ "10.5.1" ],
          "software": [ "Psi" ],
          "software_version": [ "0.11" ]
        }
      );

      final hash = await calculateCapabilityHash(data);
      expect(hash, "q07IKJEyjvHSyhy//CH0CxmKi8w=");
  });
  
  test("Test Gajim capability hash computation", () async {
      // TODO: This one fails
      final data = DiscoInfo(
        features: [
          "http://jabber.org/protocol/bytestreams",
          "http://jabber.org/protocol/muc",
          "http://jabber.org/protocol/commands",
          "http://jabber.org/protocol/disco#info",
          "jabber:iq:last",
          "jabber:x:data",
          "jabber:x:encrypted",
          "urn:xmpp:ping",
          "http://jabber.org/protocol/chatstates",
          "urn:xmpp:receipts",
          "urn:xmpp:time",
          "jabber:iq:version",
          "http://jabber.org/protocol/rosterx",
          "urn:xmpp:sec-label:0",
          "jabber:x:conference",
          "urn:xmpp:message-correct:0",
          "urn:xmpp:chat-markers:0",
          "urn:xmpp:eme:0",
          "http://jabber.org/protocol/xhtml-im",
          "urn:xmpp:hashes:2",
          "urn:xmpp:hash-function-text-names:md5",
          "urn:xmpp:hash-function-text-names:sha-1",
          "urn:xmpp:hash-function-text-names:sha-256",
          "urn:xmpp:hash-function-text-names:sha-512",
          "urn:xmpp:hash-function-text-names:sha3-256",
          "urn:xmpp:hash-function-text-names:sha3-512",
          "urn:xmpp:hash-function-text-names:id-blake2b256",
          "urn:xmpp:hash-function-text-names:id-blake2b512",
          "urn:xmpp:jingle:1",
          "urn:xmpp:jingle:apps:file-transfer:5",
          "urn:xmpp:jingle:security:xtls:0",
          "urn:xmpp:jingle:transports:s5b:1",
          "urn:xmpp:jingle:transports:ibb:1",
          "urn:xmpp:avatar:metadata+notify",
          "urn:xmpp:message-moderate:0",
          "http://jabber.org/protocol/tune+notify",
          "http://jabber.org/protocol/geoloc+notify",
          "http://jabber.org/protocol/nick+notify",
          "eu.siacs.conversations.axolotl.devicelist+notify",
        ],
        identities: [
          Identity(
            category: "client",
            type: "pc",
            name: "Gajim"
          )
        ]
      );

      final hash = await calculateCapabilityHash(data);
      expect(hash, "T7fOZrtBnV8sDA2fFTS59vyOyUs=");
  });

  test("Test Conversations hash computation", () async {
      final data = DiscoInfo(
        features: [
          "eu.siacs.conversations.axolotl.devicelist+notify",
          "http://jabber.org/protocol/caps",
          "http://jabber.org/protocol/chatstates",
          "http://jabber.org/protocol/disco#info",
          "http://jabber.org/protocol/muc",
          "http://jabber.org/protocol/nick+notify",
          "jabber:iq:version",
          "jabber:x:conference",
          "jabber:x:oob",
          "storage:bookmarks+notify",
          "urn:xmpp:avatar:metadata+notify",
          "urn:xmpp:chat-markers:0",
          "urn:xmpp:jingle-message:0",
          "urn:xmpp:jingle:1",
          "urn:xmpp:jingle:apps:dtls:0",
          "urn:xmpp:jingle:apps:file-transfer:3",
          "urn:xmpp:jingle:apps:file-transfer:4",
          "urn:xmpp:jingle:apps:file-transfer:5",
          "urn:xmpp:jingle:apps:rtp:1",
          "urn:xmpp:jingle:apps:rtp:audio",
          "urn:xmpp:jingle:apps:rtp:video",
          "urn:xmpp:jingle:jet-omemo:0",
          "urn:xmpp:jingle:jet:0",
          "urn:xmpp:jingle:transports:ibb:1",
          "urn:xmpp:jingle:transports:ice-udp:1",
          "urn:xmpp:jingle:transports:s5b:1",
          "urn:xmpp:message-correct:0",
          "urn:xmpp:ping",
          "urn:xmpp:receipts",
          "urn:xmpp:time"
        ],
        identities: [
          Identity(
            category: "client",
            type: "phone",
            name: "Conversations"
          )
        ]
      );

      final hash = await calculateCapabilityHash(data);
      expect(hash, "zcIke+Rk13ah4d1pwDG7bEZsVwA=");
  });
}
