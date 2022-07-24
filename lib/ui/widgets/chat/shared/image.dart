import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/service/thumbnail.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedImageWidget extends StatelessWidget {

  const SharedImageWidget(this.path, this.onTap, { this.borderColor, Key? key }) : super(key: key);
  final String path;
  final Color? borderColor;
  final void Function() onTap;
  
  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      FutureBuilder<Uint8List>(
        future: GetIt.I.get<ThumbnailCacheService>().getImageThumbnail(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: borderColor != null ? Border.all(
                  color: borderColor!,
                  width: 4,
                ) : null,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: MemoryImage(snapshot.data!),
                ),
              ),
              clipBehavior: Clip.hardEdge,
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      onTap: onTap,
    );
  }
}
