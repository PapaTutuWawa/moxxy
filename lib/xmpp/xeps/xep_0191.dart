import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class BlockingManager extends XmppManagerBase {
  @override
  String getId() => blockingManager;

  @override
  String getName() => "BlockingManager";

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "iq",
      tagName: "unblock",
      tagXmlns: blockingXmlns,
      callback: _unblockPush
    ),
    StanzaHandler(
      stanzaTag: "iq",
      tagName: "block",
      tagXmlns: blockingXmlns,
      callback: _blockPush
    )
  ];
  
  Future<StanzaHandlerData> _blockPush(Stanza iq, StanzaHandlerData state) async {
    final block = iq.firstTag("block", xmlns: blockingXmlns)!;

    getAttributes().sendEvent(
      BlocklistBlockPushEvent(
        items: block.findTags("item").map((i) => i.attributes["jid"]! as String).toList()
      )
    );

    return state.copyWith(done: true);
  }

  Future<StanzaHandlerData> _unblockPush(Stanza iq, StanzaHandlerData state) async {
    final unblock = iq.firstTag("unblock", xmlns: blockingXmlns)!;
    final items = unblock.findTags("item");

    if (items.isNotEmpty) {
      getAttributes().sendEvent(
        BlocklistUnblockPushEvent(
          items: items.map((i) => i.attributes["jid"]! as String).toList()
        )
      );
    } else {
      getAttributes().sendEvent(
        BlocklistUnblockAllPushEvent()
      );
    }

    return state.copyWith(done: true);
  }
  
  Future<bool> block(String item) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: "set",
        children: [
          XMLNode.xmlns(
            tag: "unblock",
            xmlns: blockingXmlns,
            children: [
              XMLNode(
                tag: "item",
                attributes: { "jid": item }
              )
            ]
          )
        ]
      )
    );

    return result.attributes["type"] == "result";
  }

  Future<bool> unblockAll() async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: "set",
        children: [
          XMLNode.xmlns(
            tag: "unblock",
            xmlns: blockingXmlns
          )
        ]
      )
    );

    return result.attributes["type"] == "result";
  }
  
  Future<bool> unblock(String item) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: "set",
        children: [
          XMLNode.xmlns(
            tag: "block",
            xmlns: blockingXmlns,
            children: [
              XMLNode(
                tag: "item",
                attributes: { "jid": item }
              )
            ]
          )
        ]
      )
    );

    return result.attributes["type"] == "result";
  }

  Future<List<String>> getBlocklist(String item) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: "get",
        children: [
          XMLNode.xmlns(
            tag: "blocklist",
            xmlns: blockingXmlns
          )
        ]
      )
    );

    final blocklist = result.firstTag("blocklist", xmlns: blockingXmlns)!;
    return blocklist.findTags("item").map((item) => item.attributes["jid"]! as String).toList();
  }
}