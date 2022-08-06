import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0060.dart';

class UserAvatar {

  const UserAvatar({ required this.base64, required this.hash });
  final String base64;
  final String hash;
}

class UserAvatarMetadata {

  const UserAvatarMetadata(
    this.id,
    this.length,
    this.width,
    this.height,
    this.mime,
  );
  /// The amount of bytes in the file
  final int length;
  /// The identifier of the avatar
  final String id;
  /// Image proportions
  final int width;
  final int height;
  /// The MIME type of the avatar
  final String mime;
}

/// NOTE: This class requires a PubSubManager
class UserAvatarManager extends XmppManagerBase {
  @override
  String getId() => userAvatarManager;

  @override
  String getName() => 'UserAvatarManager';

  PubSubManager _getPubSubManager() => getAttributes().getManagerById(pubsubManager)! as PubSubManager;
  
  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PubSubNotificationEvent) {
      getAttributes().sendEvent(
        AvatarUpdatedEvent(
          jid: event.from,
          base64: event.item.payload.innerText(),
          hash: event.item.id,
        ),
      );
    }
  }

  // TODO(PapaTutuWawa): Check for PEP support
  @override
  Future<bool> isSupported() async => true;
  
  /// Requests the avatar from [jid]. Returns the avatar data if the request was
  /// successful. Null otherwise
  Future<UserAvatar?> getUserAvatar(String jid) async {
    final pubsub = _getPubSubManager();
    final results = await pubsub.getItems(jid, userAvatarDataXmlns);
    if (results == null || results.isEmpty) return null;

    final item = results[0];
    return UserAvatar(
      base64: item.payload.innerText(),
      hash: item.id,
    );
  }

  /// Publish the avatar data, [base64], on the pubsub node using [hash] as
  /// the item id. [hash] must be the SHA-1 hash of the image data, while
  /// [base64] must be the base64-encoded version of the image data.
  Future<bool> publishUserAvatar(String base64, String hash, bool public) async {
    final pubsub = _getPubSubManager();
    return pubsub.publish(
      getAttributes().getFullJID().toBare().toString(),
      userAvatarDataXmlns,
      XMLNode.xmlns(
        tag: 'data',
        xmlns: userAvatarDataXmlns,
        text: base64,
      ),
      id: hash,
      options: PubSubPublishOptions(
        accessModel: public ? 'open' : 'roster',
      ),
    );
  }

  /// Publish avatar metadata [metadata] to the User Avatar's metadata node. If [public]
  /// is true, then the node will be set to an 'open' access model. If [public] is false,
  /// then the node will be set to an 'roster' access model.
  Future<bool> publishUserAvatarMetadata(UserAvatarMetadata metadata, bool public) async {
    final pubsub = _getPubSubManager();
    return pubsub.publish(
      getAttributes().getFullJID().toBare().toString(),
      userAvatarMetadataXmlns,
      XMLNode.xmlns(
        tag: 'metadata',
        xmlns: userAvatarMetadataXmlns,
        children: [
          XMLNode(
            tag: 'info',
            attributes: <String, String>{
              'bytes': metadata.length.toString(),
              'height': metadata.height.toString(),
              'width': metadata.width.toString(),
              'type': metadata.mime,
              'id': metadata.id,
            },
          ),
        ],
      ),
      id: metadata.id,
      options: PubSubPublishOptions(
        accessModel: public ? 'open' : 'roster',
      ),
    );
  }
  
  /// Subscribe the data and metadata node of [jid].
  Future<bool> subscribe(String jid) async {
    await _getPubSubManager().subscribe(jid, userAvatarDataXmlns);
    await _getPubSubManager().subscribe(jid, userAvatarMetadataXmlns);

    return true;
  }

  /// Unsubscribe the data and metadata node of [jid].
  Future<bool> unsubscribe(String jid) async {
    await _getPubSubManager().unsubscribe(jid, userAvatarDataXmlns);
    await _getPubSubManager().subscribe(jid, userAvatarMetadataXmlns);

    return true;
  }

  /// Returns the PubSub Id of an avatar after doing a disco#items query.
  /// Note that this assumes that there is only one (1) item published on
  /// the node.
  Future<String?> getAvatarId(String jid) async {
    final disco = getAttributes().getManagerById(discoManager)! as DiscoManager;
    final response = await disco.discoItemsQuery(jid, node: userAvatarDataXmlns);
    if (response == null || response.isEmpty) return null;

    return response.first.name;
  }
}
