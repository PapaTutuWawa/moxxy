import 'package:meta/meta.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/types/error.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';

const errorNoUploadServer = 1;
const errorFileTooBig = 2;
const errorGeneric = 3;

const allowedHTTPHeaders = [ 'authorization', 'cookie', 'expires' ];

class HttpFileUploadSlot {

  const HttpFileUploadSlot(this.putUrl, this.getUrl, this.headers);
  final String putUrl;
  final String getUrl;
  final Map<String, String> headers;
}

/// Strips out all newlines from [value].
String _stripNewlinesFromString(String value) {
  return value.replaceAll('\n', '').replaceAll('\r', '');
}

/// Prepares a list of headers by removing newlines from header names and values
/// and also removes any headers that are not allowed by the XEP.
@visibleForTesting
Map<String, String> prepareHeaders(Map<String, String> headers) {
  return headers.map((key, value) {
      return MapEntry(
        _stripNewlinesFromString(key),
        _stripNewlinesFromString(value),
      );
  })
  ..removeWhere((key, _) => !allowedHTTPHeaders.contains(key.toLowerCase()));
}

class HttpFileUploadManager extends XmppManagerBase {

  HttpFileUploadManager() : _gotSupported = false, _supported = false, super();
  JID? _entityJid;
  int? _maxUploadSize;
  bool _gotSupported;
  bool _supported;

  @override
  String getId() => httpFileUploadManager;

  @override
  String getName() => 'HttpFileUploadManager';

  /// Returns whether the entity provided an identity that tells us that we can ask it
  /// for an HTTP upload slot.
  bool _containsFileUploadIdentity(DiscoInfo info) {
    return listContains(info.identities, (Identity id) => id.category == 'store' && id.type == 'file');
  }

  /// Extract the maximum filesize in octets from the disco response. Returns null
  /// if none was specified.
  int? _getMaxFileSize(DiscoInfo info) {
    for (final form in info.extendedInfo) {
      for (final field in form.fields) {
        if (field.varAttr == 'max-file-size') {
          return int.parse(field.values.first);
        }
      }
    }

    return null;
  }

  @override
  Future<bool> isSupported() async {
    if (_gotSupported) return _supported;
    
    final infos = await getAttributes().getManagerById<DiscoManager>(discoManager)!.performDiscoSweep();
    if (infos == null) {
      _gotSupported = false;
      _supported = false;
      return false;
    }

    
    _gotSupported = true;
    for (final info in infos) {
      if (_containsFileUploadIdentity(info) && info.features.contains(httpFileUploadXmlns)) {
         logger.info('Discovered HTTP File Upload for ${info.jid}');

        _entityJid = info.jid;
        _maxUploadSize = _getMaxFileSize(info);
        _supported = true;
        break;
      }
    }

    return _supported;
  }

  /// Request a slot to upload a file to. [filename] is the file's name and [filesize] is
  /// the file's size in octets. [contentType] is optional and refers to the file's
  /// Mime type.
  /// Returns an [HttpFileUploadSlot] if the request was successful; null otherwise.
  Future<MayFail<HttpFileUploadSlot>> requestUploadSlot(String filename, int filesize, { String? contentType }) async {
    if (_entityJid == null) {
      logger.warning('Attempted to request HTTP File Upload slot but no entity is known to send this request to.');
      return MayFail.failure(errorNoUploadServer);
    }

    if (_maxUploadSize != null && filesize > _maxUploadSize!) {
      logger.warning('Attempted to request HTTP File Upload slot for a file that exceeds the filesize limit');
      return MayFail.failure(errorFileTooBig);
    }
    
    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        to: _entityJid.toString(),
        type: 'get',
        children: [
          XMLNode.xmlns(
            tag: 'request',
            xmlns: httpFileUploadXmlns,
            attributes: {
              'filename': filename,
              'size': filesize.toString(),
              ...contentType != null ? { 'content-type': contentType } : {}
            },
          )
        ],
      ),
    );

    if (response.attributes['type']! != 'result') {
      logger.severe('Failed to request HTTP File Upload slot.');
      // TODO(Unknown): Be more precise
      return MayFail.failure(errorGeneric);
    }

    final slot = response.firstTag('slot', xmlns: httpFileUploadXmlns)!;
    final putUrl = slot.firstTag('put')!.attributes['url']! as String;
    final getUrl = slot.firstTag('get')!.attributes['url']! as String;
    final headers = Map<String, String>.fromEntries(
      slot.findTags('header').map((tag) {
        return MapEntry(
          tag.attributes['name']! as String,
          tag.innerText(),
        );
      }),
    );

    return MayFail.success(
      HttpFileUploadSlot(
        putUrl,
        getUrl,
        prepareHeaders(headers),
      ),
    );
  }
}
