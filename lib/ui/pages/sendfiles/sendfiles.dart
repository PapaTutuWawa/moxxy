import 'dart:io';
import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mime/mime.dart';
import 'package:moxxyv2/ui/bloc/navigation.dart';
import 'package:moxxyv2/ui/bloc/sendfiles.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/sendfiles/conversation_indicator.dart';
import 'package:moxxyv2/ui/widgets/cancel_button.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/base.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/image.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/video.dart';
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
  const SendFilesPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (context) => const SendFilesPage(),
        settings: const RouteSettings(
          name: sendFilesRoute,
        ),
      );

  Widget _renderPreview(
    BuildContext context,
    String path,
    bool selected,
    int index,
  ) {
    final mime = lookupMimeType(path) ?? '';

    if (mime.startsWith('image/')) {
      // Render the image preview
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: SharedImageWidget(
          path,
          onTap: () {
            if (selected) {
              // The trash can icon has been tapped
              context.read<SendFilesCubit>().remove(index);
            } else {
              // Another item has been tapped
              context.read<SendFilesCubit>().setIndex(index);
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
          // TODO(PapaTutuWawa): Fix
          'sendfiles',
          mime,
          onTap: () {
            if (selected) {
              // The trash can icon has been tapped
              context.read<SendFilesCubit>().remove(index);
            } else {
              // Another item has been tapped
              context.read<SendFilesCubit>().setIndex(index);
            }
          },
          borderColor: selected ? Colors.blue : null,
          child: selected ? _deleteIconWithShadow() : null,
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
              border: selected
                  ? Border.all(
                      color: Colors.blue,
                      width: 4,
                    )
                  : null,
            ),
            child: selected
                ? const Icon(Icons.delete, size: 32)
                : const Icon(Icons.file_present),
          ),
          color: sharedMediaItemBackgroundColor,
          onTap: () {
            if (selected) {
              // The trash can icon has been tapped
              context.read<SendFilesCubit>().remove(index);
            } else {
              // Another item has been tapped
              context.read<SendFilesCubit>().setIndex(index);
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
      return ImageViewer(
        path: path,
        controller: ViewerUIVisibilityController(),
      );
    } else if (mime.startsWith('video/')) {
      return VideoViewer(
        path: path,
        controller: ViewerUIVisibilityController(),
        showScrubBar: false,
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

  void _maybeRemoveTemporaryFiles() {
    if (Platform.isAndroid) {
      // Remove temporary files.
      GetIt.I.get<SendFilesCubit>().removeCacheFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    const barPadding = 8.0;

    // TODO(Unknown): Fix the typography
    return PopScope(
      onPopInvoked: (_) {
        _maybeRemoveTemporaryFiles();
      },
      child: SafeArea(
        child: Scaffold(
          body: BlocBuilder<SendFilesCubit, SendFilesState>(
            builder: (context, state) => Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: _renderBackground(context, state.files[state.index]),
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

                              return _renderPreview(
                                context,
                                item,
                                index == state.index,
                                index,
                              );
                            } else {
                              return SharedMediaContainer(
                                const Icon(Icons.attach_file),
                                color: sharedMediaItemBackgroundColor,
                                onTap: context.read<SendFilesCubit>().addFiles,
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
                            onPressed: context.read<SendFilesCubit>().submit,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      CancelButton(
                        onPressed: () {
                          _maybeRemoveTemporaryFiles();

                          // If we do a direct share and the user presses the "x" button, then it
                          // happens that just popping the stack results in just a gray screen.
                          // By using `SystemNavigator.pop`, we can tell the Flutter to "pop the
                          // entire app".
                          context
                              .read<Navigation>()
                              .popWithSystemNavigator();
                        },
                      ),
                      if (state.hasRecipientData)
                        ConversationIndicator(state.recipients)
                      else
                        FetchingConversationIndicator(
                          state.recipients
                              .map((SendFilesRecipient r) => r.jid)
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
