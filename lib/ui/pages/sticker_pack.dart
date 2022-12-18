import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:moxxyv2/ui/widgets/shimmer.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

/// Wrapper around displaying stickers that may or may not be installed on the system.
class StickerWrapper extends StatelessWidget {
  const StickerWrapper(
    this.sticker, {
      this.width,
      this.height,
      this.cover = true,
      super.key,
    }
  );
  final Sticker sticker;
  final double? width;
  final double? height;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    if (sticker.path.isNotEmpty) {
      return Image.file(
        File(sticker.path),
        fit: cover ?
          BoxFit.contain :
          null,
        width: width,
        height: height,
      );
    } else {
      return Image.network(
        sticker.urlSources.first,
         fit: cover ?
          BoxFit.contain :
          null,
        width: width,
        height: height,
        loadingBuilder: (_, child, event) {
          if (event == null) return child;

          return ClipRRect(
            borderRadius: const BorderRadius.all(radiusLarge),
            child: SizedBox(
              width: width,
              height: height,
              child: const ShimmerWidget(),
            ),
          );
        },
      );
    }
  }
}

class StickerPackPage extends StatelessWidget {
  const StickerPackPage({ super.key });

  static MaterialPageRoute<void> get route => MaterialPageRoute<void>(
    builder: (_) => const StickerPackPage(),
    settings: const RouteSettings(
      name: stickerPackRoute,
    ),
  );

  Future<void> _onDeletePressed(BuildContext context, StickerPackState state) async {
    final result = await showConfirmationDialog(
      t.pages.stickerPack.removeConfirmTitle,
      t.pages.stickerPack.removeConfirmBody,
      context,
    );
    if (result) {
      // ignore: use_build_context_synchronously
      context.read<StickerPackBloc>().add(
        StickerPackRemovedEvent(state.stickerPack!.id),
      );
    }
  }

  Future<void> _onInstallPressed(BuildContext context, StickerPackState state) async {
    final result = await showConfirmationDialog(
      t.pages.stickerPack.installConfirmTitle,
      t.pages.stickerPack.installConfirmBody,
      context,
    );
    if (result) {
      // ignore: use_build_context_synchronously
      context.read<StickerPackBloc>().add(
        StickerPackInstalledEvent(),
      );
    }
  }

  Widget _buildButton(BuildContext context, StickerPackState state) {
    Widget child;
    Color color;
    if (state.stickerPack!.local) {
      color = Colors.red;
      child = const Icon(
        Icons.delete,
        size: 32,
      );
    } else {
      color = Colors.green;
      if (state.isInstalling) {
        child = const Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        );
      } else {
        child = const Icon(
          Icons.download,
          size: 32,
        );
      }
    }

    return SharedMediaContainer(
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: color,
          child: child,
        ),
      ),
      onTap: () {
        if (state.stickerPack!.local) {
          _onDeletePressed(context, state);
        } else {
          if (state.isInstalling) return;

          _onInstallPressed(context, state);
        }
      },
    );
  }
  
  Widget _buildBody(BuildContext context, StickerPackState state) {
    final width = MediaQuery.of(context).size.width;
    final itemSize = (width - 2 * 15 - 3 * 30) / 4;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  state.stickerPack?.description ?? '',
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildButton(context, state),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: (state.stickerPack!.stickers.length / 4).ceil(),
            itemBuilder: (_, index) {
              final length = state.stickerPack!.stickers.length - index * 4;

              return SizedBox(
                width: width,
                child: Row(
                  children: List<int>.generate(
                    length >= 4 ?
                    4 :
                    length,
                    (i) => i,
                  ).map((rowIndex) {
                      final sticker = state.stickerPack!.stickers[index * 4 + rowIndex];
                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: InkWell(
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) {
                                return IgnorePointer(
                                  child: StickerWrapper(
                                    sticker,
                                    width: width - 80 * 2,
                                    cover: false,
                                  ),
                                );
                              },
                            );
                          },
                          child: StickerWrapper(
                            sticker,
                            width: itemSize,
                            height: itemSize,
                          ),
                        ),
                      );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickerPackBloc, StickerPackState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(
          state.stickerPack?.name ?? '...',
        ),
        body: state.isWorking ?
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
              ],
            ),
          ) :
          _buildBody(context, state),
      ),
    );
  }
}
