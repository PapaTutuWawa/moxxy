import "dart:async";
import "dart:io";

import "package:flutter/material.dart";

import "package:file_picker/file_picker.dart";
import "package:image_cropping/constant/enums.dart";
import "package:image_cropping/image_cropping.dart";
import "package:path_provider/path_provider.dart";

Future<void> showNotImplementedDialog(String feature, BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Not Implemented"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text("The $feature feature is not yet implemented.")
            ]
          )
        ),
        actions: [
          TextButton(
            child: Text("Okay"),
            onPressed: () => Navigator.of(context).pop()
          )
        ]
      );
    }
  );
}

void dismissSoftKeyboard(BuildContext context) {
  // NOTE: Thank you, https://flutterigniter.com/dismiss-keyboard-form-lose-focus/
  FocusScopeNode current = FocusScope.of(context);
  if (!current.hasPrimaryFocus) {
    current.unfocus();
  }
}

/*
 * Open the file picker to pick an image and open the cropping tool.
 * The Future either resolves to null if the user cancels the action or
 * the actual image data
 */
Future<dynamic> pickAndCropImage(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.image,
    withData: true
  );

  if (result != null) {
    Completer completer = new Completer();
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

/*
 * Open the file picker to pick an image, open the cropping tool and then send it to
 * the backend.
 */
Future<void> pickAndSetAvatar(BuildContext context, void Function(String) setAvatarUrl) async {
  final data = await pickAndCropImage(context);

  if (data != null) {
    String cacheDir = (await getTemporaryDirectory()).path;
    Directory accountDir = Directory(cacheDir + "/account");
    await accountDir.create();
    File avatar = File(accountDir.path + "/avatar.png");
    await avatar.writeAsBytes(data);

    // TODO: If the path doesn't change then the UI won't be updated. Hash it and use that as the filename?
    setAvatarUrl(avatar.path);
  }
}
