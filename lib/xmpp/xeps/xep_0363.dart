import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/types/error.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";

const errorNoUploadServer = 1;
const errorFileTooBig = 2;
const errorGeneric = 3;

class HttpFileUploadSlot {
  final String putUrl;
  final String getUrl;
  final Map<String, String> headers;

  const HttpFileUploadSlot(this.putUrl, this.getUrl, this.headers);
}

class HttpFileUploadManager extends XmppManagerBase {
  String? _entityJid;
  int? _maxUploadSize;

  HttpFileUploadManager() : super();

  @override
  String getId() => httpFileUploadManager;

  @override
  String getName() => "HttpFileUploadManager";

  /// Returns whether the entity provided an identity that tells us that we can ask it
  /// for an HTTP upload slot.
  bool _containsFileUploadIdentity(DiscoInfo info) {
    return listContains(info.identities, (Identity id) => id.category == "store" && id.type == "file");
  }

  /// Extract the maximum filesize in octets from the disco response. Returns null
  /// if none was specified.
  int? _getMaxFileSize(DiscoInfo info) {
    for (final form in info.extendedInfo) {
      for (final field in form.fields) {
        if (field.varAttr == "max-file-size") {
          return int.parse(field.values.first);
        }
      }
    }

    return null;
  }

  /// Returns true if we are allowed to include the header in the put request. False if not.
  bool _isHeaderAllowed(String name) => [ "authorization", "cookie", "expires" ].contains(name.toLowerCase());

  @override
  void onXmppEvent(XmppEvent event) {
    if (event is ServerItemDiscoEvent) {
      if (_containsFileUploadIdentity(event.info) && event.info.features.contains(httpFileUploadXmlns)) {
        logger.info("Discovered HTTP File Upload for ${event.jid}");

        _entityJid = event.jid;
        _maxUploadSize = _getMaxFileSize(event.info);
        return;
      }
    }
  }

  /// Request a slot to upload a file to. [filename] is the file's name and [filesize] is
  /// the file's size in octets. [contentType] is optional and refers to the file's
  /// Mime type.
  /// Returns an [HttpFileUploadSlot] if the request was successful; null otherwise.
  Future<MayFail<HttpFileUploadSlot>> requestUploadSlot(String filename, int filesize, { String? contentType }) async {
    if (_entityJid == null) {
      logger.warning("Attempted to request HTTP File Upload slot but no entity is known to send this request to.");
      return MayFail.failure(errorNoUploadServer);
    }

    if (_maxUploadSize != null && filesize > _maxUploadSize!) {
      logger.warning("Attempted to request HTTP File Upload slot for a file that exceeds the filesize limit");
      return MayFail.failure(errorFileTooBig);
    }
    
    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        to: _entityJid,
        type: "get",
        children: [
          XMLNode.xmlns(
            tag: "request",
            xmlns: httpFileUploadXmlns,
            attributes: {
              "filename": filename,
              "size": filesize.toString(),
              ...(contentType != null ? { "content-type": contentType } : {})
            }
          )
        ]
      )
    );

    if (response.attributes["type"]! != "result") {
      logger.severe("Failed to request HTTP File Upload slot.");
      // TODO: Be more precise
      return MayFail.failure(errorGeneric);
    }

    final slot = response.firstTag("slot", xmlns: httpFileUploadXmlns)!;
    final putUrl = slot.firstTag("put")!.attributes["url"]!;
    final getUrl = slot.firstTag("get")!.attributes["url"]!;
    final Map<String, String> headers = {};

    for (final headerElement in slot.findTags("header")) {
      final name = headerElement.attributes["name"]!.replaceAll("\n", "");
      final value = headerElement.innerText().replaceAll("\n", "");

      if (!_isHeaderAllowed(name)) continue;

      headers[name] = value;
    }

    return MayFail.success(
      HttpFileUploadSlot(
        putUrl,
        getUrl,
        headers
      )
    );
  }
}
