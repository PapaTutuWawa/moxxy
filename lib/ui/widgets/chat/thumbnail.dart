import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/service/thumbnail.dart';

typedef ChildBuilderFunction = Widget Function(Uint8List);

/// A widget that allows easy access to thumbnails using a pattern similar to that of
/// the FutureBuilder.
abstract class ThumbnailBaseWidget extends StatelessWidget {
  const ThumbnailBaseWidget(this.path, this.builder, {Key? key}) : super(key: key);

  final String path;
  final ChildBuilderFunction builder;

  Future<Uint8List> getThumbnail();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: getThumbnail(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            // TODO(Unknown): Maybe have some error handling here
            return builder(snapshot.data!);
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }
}

class ImageThumbnailWidget extends ThumbnailBaseWidget {
  const ImageThumbnailWidget(
    String path,
    ChildBuilderFunction builder,
    {
      Key? key,
    }
  ) : super(path, builder, key: key);

  @override
  Future<Uint8List> getThumbnail() {
    return GetIt.I.get<ThumbnailCacheService>().getImageThumbnail(path);
  }
}

class VideoThumbnailWidget extends ThumbnailBaseWidget {
  const VideoThumbnailWidget(
    String path,
    ChildBuilderFunction builder,
    {
      Key? key,
    }
  ) : super(path, builder, key: key);

  @override
  Future<Uint8List> getThumbnail() {
    return GetIt.I.get<ThumbnailCacheService>().getVideoThumbnail(path);
  }
}
