import 'dart:async';
import 'dart:typed_data';
import 'package:better_open_file/better_open_file.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:moxxmpp/moxxmpp.dart' as moxxmpp;
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/avatar.dart';
import 'package:moxxyv2/shared/models/omemo_device.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/util/qrcode.dart';
import 'package:moxxyv2/ui/redirects.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a dialog asking the user if they are sure that they want to proceed with an
/// action. Resolves to true if the user pressed the confirm button. Returns false if
/// the cancel button was pressed.
Future<bool> showConfirmationDialog(
  String title,
  String body,
  BuildContext context,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(textfieldRadiusRegular),
      ),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.global.yes),
        ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(t.global.no),
        )
      ],
    ),
  );

  return result != null;
}

/// Shows a dialog telling the user that the [feature] feature is not implemented.
Future<void> showNotImplementedDialog(
  String feature,
  BuildContext context,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Not Implemented'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(textfieldRadiusRegular),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [Text('The $feature feature is not yet implemented.')],
          ),
        ),
        actions: [
          TextButton(
            child: Text(t.global.dialogAccept),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    },
  );
}

/// Shows a dialog giving the user a very simple information with an "Okay" button.
Future<void> showInfoDialog(
  String title,
  String body,
  BuildContext context,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(textfieldRadiusRegular),
      ),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(t.global.dialogAccept),
        )
      ],
    ),
  );
}

/// Dismissed the softkeyboard.
void dismissSoftKeyboard(BuildContext context) {
  // NOTE: Thank you, https://flutterigniter.com/dismiss-keyboard-form-lose-focus/
  final current = FocusScope.of(context);
  if (!current.hasPrimaryFocus) {
    current.unfocus();
  }
}

/// Open the file picker to pick an image and open the cropping tool.
/// The Future either resolves to null if the user cancels the action or
/// the actual image data.
Future<Uint8List?> pickAndCropImage(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );

  if (result != null) {
    return GetIt.I
        .get<CropBloc>()
        .cropImageWithData(result.files.single.bytes!);
  }

  return null;
}

class PickedAvatar {
  const PickedAvatar(this.path, this.hash);
  final String path;
  final String hash;
}

/// Open the file picker to pick an image, open the cropping tool and then save it.
/// [oldPath] is the path of the old avatar or "" if none has been set.
/// Returns the path of the new avatar path.
Future<PickedAvatar?> pickAvatar(
  BuildContext context,
  String jid,
  String oldPath,
) async {
  final data = await pickAndCropImage(context);

  if (data != null) {
    // TODO(Unknown): Maybe tweak these values
    final compressedData = await FlutterImageCompress.compressWithList(
      data,
      minHeight: 200,
      minWidth: 200,
      quality: 60,
      format: CompressFormat.png,
    );

    final hash = (await Sha1().hash(compressedData)).bytes;
    final hashhex = HEX.encode(hash);
    final avatarPath =
        await saveAvatarInCache(compressedData, hashhex, jid, oldPath);

    return PickedAvatar(avatarPath, hashhex);
  }

  return null;
}

/// Turn [text] into a text that can be used with the AvatarWrapper's alt.
/// [text] must be non-empty.
String avatarAltText(String text) {
  assert(text.isNotEmpty, 'Text for avatar alt must be non-empty');

  if (text.length == 1) return text[0].toUpperCase();

  return (text[0] + text[1]).toUpperCase();
}

/// Return the color used for tiles depending on the system brightness.
Color getTileColor(BuildContext context) {
  final theme = Theme.of(context);
  switch (theme.brightness) {
    case Brightness.light:
      return tileColorLight;
    case Brightness.dark:
      return tileColorDark;
  }
}

/// Return the corresponding language name (in its language) for the given
/// language code [localeCode], e.g. "de", "en", ...
String localeCodeToLanguageName(String localeCode) {
  switch (localeCode) {
    case 'de':
      return 'Deutsch';
    case 'en':
      return 'English';
    case 'default':
      return t.pages.settings.appearance.systemLanguage;
  }

  assert(false, 'Language code $localeCode has no name');
  return '';
}

/// Scans QR Codes for an URI with a scheme of xmpp:. Returns the URI when found.
/// Returns null if not.
Future<Uri?> scanXmppUriQrCode(BuildContext context) async {
  final value = await Navigator.of(context).pushNamed<String>(
    qrCodeScannerRoute,
    arguments: QrCodeScanningArguments(
      (value) {
        if (value == null) return false;

        final uri = Uri.tryParse(value);
        if (uri == null) return false;

        if (uri.scheme == 'xmpp') {
          return true;
        }

        return false;
      },
    ),
  );

  if (value != null) {
    return Uri.parse(value);
  }

  return null;
}

/// Shows a dialog with the given data string encoded as a QR Code.
void showQrCode(BuildContext context, String data, {bool embedLogo = true}) {
  showDialog<void>(
    context: context,
    builder: (BuildContext context) => Center(
      child: ClipRRect(
        borderRadius: const BorderRadius.all(radiusLarge),
        child: SizedBox(
          width: 220,
          height: 220,
          child: QrImage(
            data: data,
            size: 220,
            backgroundColor: Colors.white,
            embeddedImage:
                embedLogo ? const AssetImage('assets/images/logo.png') : null,
            embeddedImageStyle: embedLogo
                ? QrEmbeddedImageStyle(
                    size: const Size(50, 50),
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}

/// Compares the scanned fingerprint (encoded by [scannedUri]) against the device list
/// [devices] for the device with id [deviceId] with the JID [deviceJid].
///
/// Returns the index of the device in [devices] on success. On failure of any kind,
/// returns -1.
int isVerificationUriValid(
  List<OmemoDevice> devices,
  Uri scannedUri,
  String deviceJid,
  int deviceId,
) {
  if (scannedUri.queryParameters.isEmpty) {
    // No query parameters
    Fluttertoast.showToast(
      msg: t.errors.omemo.verificationInvalidOmemoUrl,
      gravity: ToastGravity.SNACKBAR,
      toastLength: Toast.LENGTH_SHORT,
    );
    return -1;
  }

  final jid = scannedUri.path;
  if (deviceJid != jid) {
    // The Jid is wrong
    Fluttertoast.showToast(
      msg: t.errors.omemo.verificationWrongJid,
      gravity: ToastGravity.SNACKBAR,
      toastLength: Toast.LENGTH_SHORT,
    );
    return -1;
  }

  // TODO(PapaTutuWawa): Use an exception safe version of firstWhere
  final sidParam = scannedUri.queryParameters.keys
      .firstWhere((param) => param.startsWith('omemo2-sid-'));
  final id = int.parse(sidParam.replaceFirst('omemo2-sid-', ''));
  final fp = scannedUri.queryParameters[sidParam];

  if (id != deviceId) {
    // The scanned device has the wrong Id
    Fluttertoast.showToast(
      msg: t.errors.omemo.verificationWrongDevice,
      gravity: ToastGravity.SNACKBAR,
      toastLength: Toast.LENGTH_SHORT,
    );
    return -1;
  }

  final index = devices.indexWhere((device) => device.deviceId == deviceId);
  if (index == -1) {
    // The device is not in the list
    Fluttertoast.showToast(
      msg: t.errors.omemo.verificationNotInList,
      gravity: ToastGravity.SNACKBAR,
      toastLength: Toast.LENGTH_SHORT,
    );
    return -1;
  }

  final device = devices[index];
  if (device.fingerprint != fp) {
    // The fingerprint is not what we expected
    Fluttertoast.showToast(
      msg: t.errors.omemo.verificationWrongFingerprint,
      gravity: ToastGravity.SNACKBAR,
      toastLength: Toast.LENGTH_SHORT,
    );
    return -1;
  }

  return index;
}

/// Parse the URI [uriString] and trigger an appropriate UI action.
Future<void> handleUri(String uriString) async {
  final uri = Uri.tryParse(uriString);
  if (uri == null) return;

  if (uri.scheme == 'xmpp') {
    final psAction = uri.queryParameters['pubsub;action'];
    if (psAction != null) {
      final parts = psAction.split(';');
      String? node;
      String? item;

      for (final p in parts) {
        if (p.startsWith('node=')) {
          node = p.substring(5);
        } else if (p.startsWith('item=')) {
          item = p.substring(5);
        }
      }

      if (node == moxxmpp.stickersXmlns && item != null) {
        // Retrieve a sticker pack
        GetIt.I.get<StickerPackBloc>().add(
              StickerPackRequested(
                uri.path,
                item,
              ),
            );
      }
    }

    return;
  }

  await launchUrl(
    redirectUrl(uri),
    mode: LaunchMode.externalNonBrowserApplication,
  );
}

/// Open the file [path] using the system native means. Shows a toast if the
/// file cannot be opened.
Future<void> openFile(String path) async {
  final result = await OpenFile.open(path);

  if (result.type != ResultType.done) {
    String message;
    if (result.type == ResultType.noAppToOpen) {
      message = t.errors.conversation.openFileNoAppError;
    } else {
      message = t.errors.conversation.openFileGenericError;
    }

    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
    );
  }
}
