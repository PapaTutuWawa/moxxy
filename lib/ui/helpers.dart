import "dart:async";

import "package:moxxyv2/shared/avatar.dart";
import "package:moxxyv2/xmpp/sasl/errors.dart";

import "package:flutter/material.dart";
import "package:file_picker/file_picker.dart";
import "package:image_cropping/image_cropping.dart";
import "package:cryptography/cryptography.dart";
import "package:hex/hex.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";

/// Shows a dialog asking the user if they are sure that they want to proceed with an
/// action.
Future<void> showConfirmationDialog(String title, String body, BuildContext context, void Function() callback) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          child: const Text("Yes"),
          onPressed: callback
        ),
        TextButton(
          child: const Text("No"),
          onPressed: Navigator.of(context).pop
        )
      ]
    )
  );
}

/// Shows a dialog telling the user that the [feature] feature is not implemented.
Future<void> showNotImplementedDialog(String feature, BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Not Implemented"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text("The $feature feature is not yet implemented.")
            ]
          )
        ),
        actions: [
          TextButton(
            child: const Text("Okay"),
            onPressed: () => Navigator.of(context).pop()
          )
        ]
      );
    }
  );
}

/// Dismissed the softkeyboard.
void dismissSoftKeyboard(BuildContext context) {
  // NOTE: Thank you, https://flutterigniter.com/dismiss-keyboard-form-lose-focus/
  FocusScopeNode current = FocusScope.of(context);
  if (!current.hasPrimaryFocus) {
    current.unfocus();
  }
}

/// Open the file picker to pick an image and open the cropping tool.
/// The Future either resolves to null if the user cancels the action or
/// the actual image data.
Future<dynamic> pickAndCropImage(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.image,
    withData: true
  );

  if (result != null) {
    Completer completer = Completer();
    ImageCropping.cropImage(
      context: context,
      imageBytes: result.files.single.bytes!,
      onImageDoneListener: (data) => completer.complete(data),
      selectedImageRatio: ImageRatio.RATIO_1_1
    );
    return completer.future;
  }

  return null;
}

class PickedAvatar {
  final String path;
  final String hash;

  const PickedAvatar(this.path, this.hash);
}

/// Open the file picker to pick an image, open the cropping tool and then save it.
/// [avatarUrl] is the path of the old avatar or "" if none has been set.
/// Returns the path of the new avatar path.
Future<PickedAvatar?> pickAvatar(BuildContext context, String jid, String oldPath) async {
  final data = await pickAndCropImage(context);

  if (data != null) {
    // TODO: Maybe tweak these values
    final compressedData = await FlutterImageCompress.compressWithList(
      data,
      minHeight: 200,
      minWidth: 200,
      quality: 60,
      format: CompressFormat.png
    );

    final hash = (await Sha1().hash(compressedData)).bytes;
    final hashhex = HEX.encode(hash);
    final avatarPath = await saveAvatarInCache(compressedData, hashhex, jid, oldPath);
    
    return PickedAvatar(avatarPath, hashhex);
  }

  return null;
}

/// Turn the SASL error into a string that a regular user could understand.
String saslErrorToHumanReadable(String saslError) {
  switch (saslError) {
    case saslErrorNotAuthorized: return "Wrong XMPP address or password";
  }

  return "SASL error: " + saslError;
}

/// Turn [text] into a text that can be used with the [AvatarWrapper]'s alt.
/// [text] must be non-empty.
String avatarAltText(String text) {
  assert(text.isNotEmpty);

  if (text.length == 1) return text[0].toUpperCase();

  return (text[0] + text[1]).toUpperCase();
}
