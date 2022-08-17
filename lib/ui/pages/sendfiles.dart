import 'dart:io';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mime/mime.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';
import 'package:moxxyv2/ui/widgets/chat/thumbnail.dart';
import 'package:path/path.dart' as pathlib;

Widget _deleteIconWithShadow() {
  return const Center(
    child: DecoratedIcon(
      Icons.delete,
      size: 32,
      shadows: [BoxShadow(blurRadius: 8)],
    ),
  );
}

class SendFilesPage extends StatelessWidget {
 
  const SendFilesPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const SendFilesPage(),
    settings: const RouteSettings(
      name: sendFilesRoute,
    ),
  );

  Widget _renderPreview(BuildContext context, String path, bool selected, int index) {
    final mime = lookupMimeType(path) ?? '';

    if (mime.startsWith('image/')) {
      // Render the image preview
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SharedImageWidget(
          path,
          () {
            if (selected) {
              // The trash can icon has been tapped
              context.read<SendFilesBloc>().add(
                ItemRemovedEvent(index),
              );
            } else {
              // Another item has been tapped
              context.read<SendFilesBloc>().add(
                IndexSetEvent(index),
              );
            }
          },
          borderColor: selected ? Colors.blue : null,
          child: selected ? _deleteIconWithShadow() : null,
        ),
      );
    } else if (mime.startsWith('video/')) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SharedVideoWidget(
          path,
          () {
            if (selected) {
              // The trash can icon has been tapped
              context.read<SendFilesBloc>().add(
                ItemRemovedEvent(index),
              );
            } else {
              // Another item has been tapped
              context.read<SendFilesBloc>().add(
                IndexSetEvent(index),
              );
            }
          },
          borderColor: selected ? Colors.blue : null,
          child: selected ? _deleteIconWithShadow(): null,
        ),
      );
    } else {
      // Render a generic file
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SharedMediaContainer(
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black,
              border: selected ? Border.all(
                color: Colors.blue,
                width: 4,
              ) : null,
            ),
            child: selected
              ? const Icon(Icons.delete, size: 32)
              : const Icon(Icons.file_present),
          ),
          onTap: () {
            if (selected) {
              // The trash can icon has been tapped
              context.read<SendFilesBloc>().add(
                ItemRemovedEvent(index),
              );
            } else {
              // Another item has been tapped
              context.read<SendFilesBloc>().add(
                IndexSetEvent(index),
              );
            }
          },
        ),
      );
    }
  }

  Widget _renderBackground(BuildContext context, String path) {
    final mime = lookupMimeType(path) ?? '';

    if (mime.startsWith('image/')) {
      // Render the image
      return Image.file(
        File(path),
      );
    } else if (mime.startsWith('video/')) {
      // Render the video thumbnail
      // TODO(PapaTutuWawa): Maybe allow playing the video back inline
      return VideoThumbnailWidget(
        path,
        Image.memory,
      );
    } else {
      // Generic file
      final width = MediaQuery.of(context).size.width;
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.file_present,
              size: width / 2,
            ),
            // TODO(PapaTutuWawa): Truncate if the filename is too long
            Text(pathlib.basename(path)),
          ],
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const barPadding = 8.0;
    
    // TODO(Unknown): Fix the typography
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<SendFilesBloc, SendFilesState>(
          builder: (context, state) => Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _renderBackground(context, state.files[state.index]),
                    ],
                  ),
                ),
              ),
              // TODO(Unknown): Add a TextField for entering a message
              Positioned(
                left: 0,
                right: 0,
                bottom: 72,
                  child: SizedBox(
                  height: sharedMediaContainerDimension + 2 * barPadding,
                  child: ColoredBox(
                    color: const Color.fromRGBO(0, 0, 0, 0.7),
                    child: Padding(
                      padding: const EdgeInsets.all(barPadding),
                      child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: state.files.length + 1,
                        itemBuilder: (context, index) {
                          if (index < state.files.length) {
                            final item = state.files[index];

                            return _renderPreview(context, item, index == state.index, index);
                          } else {
                            return SharedMediaContainer(
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey,
                                ),
                                child: const Icon(Icons.attach_file),
                              ),
                              onTap: () => context.read<SendFilesBloc>().add(AddFilesRequestedEvent()),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: FittedBox(
                    // Without wrapping the button in a Material, the image will be drawn
                    // over the button, partly or entirely hiding it.
                    child: Material(
                      color: const Color.fromRGBO(0, 0, 0, 0),
                      child: Ink(
                        decoration: const ShapeDecoration(
                          color: primaryColor,
                          shape: CircleBorder(),
                        ),
                        child: IconButton(
                          color: Colors.white,
                          icon: const Icon(Icons.send),
                          onPressed: () => context.read<SendFilesBloc>().add(FileSendingRequestedEvent()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () => context.read<NavigationBloc>().add(PoppedRouteEvent()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
