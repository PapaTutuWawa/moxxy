import "package:flutter/material.dart";
import "package:external_path/external_path.dart";
import "package:path/path.dart" as pathlib;

class UIDataService {
  late String _thumbnailBase;

  UIDataService();

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    final base = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES);
    _thumbnailBase = pathlib.join(base, "Moxxy", ".thumbnail");
  }

  // The base path for thumbnails
  String get thumbnailBase => _thumbnailBase;
}
