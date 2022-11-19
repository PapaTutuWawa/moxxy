import 'dart:async';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get_it/get_it.dart';
import 'package:hex/hex.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/avatar.dart';
import 'package:moxxyv2/ui/bloc/crop_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

/// Shows a dialog asking the user if they are sure that they want to proceed with an
/// action.
Future<void> showConfirmationDialog(String title, String body, BuildContext context, void Function() callback) async {
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
          onPressed: () {
            Navigator.of(context).pop();
            callback();
          },
          child: Text(t.global.yes),
        ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(t.global.no),
        )
      ],
    ),
  );
}

/// Shows a dialog telling the user that the [feature] feature is not implemented.
Future<void> showNotImplementedDialog(String feature, BuildContext context) async {
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
            children: [
              Text('The $feature feature is not yet implemented.')
            ],
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
Future<void> showInfoDialog(String title, String body, BuildContext context) async {
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
    return GetIt.I.get<CropBloc>().cropImageWithData(result.files.single.bytes!);
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
Future<PickedAvatar?> pickAvatar(BuildContext context, String jid, String oldPath) async {
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
    final avatarPath = await saveAvatarInCache(compressedData, hashhex, jid, oldPath);
    
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
    case Brightness.light: return tileColorLight;
    case Brightness.dark: return tileColorDark;
  }
}

/// Return the corresponding language name (in its language) for the given
/// language code [localeCode], e.g. "de", "en", ...
String localeCodeToLanguageName(String localeCode) {
  switch (localeCode) {
    case 'de': return 'Deutsch';
    case 'en': return 'English';
    case 'default': return t.pages.settings.appearance.systemLanguage;
  }

  assert(false, 'Language code $localeCode has no name');
  return '';
}
