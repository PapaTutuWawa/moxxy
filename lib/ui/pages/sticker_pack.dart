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
    this.cover = true,
    super.key,
  });
  final Sticker sticker;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    if (sticker.fileMetadata.path != null) {
      return Image.file(
        File(sticker.fileMetadata.path!),
        fit: cover ? BoxFit.contain : null,
      );
    } else {
      return Image.network(
        sticker.fileMetadata.sourceUrls!.first,
        fit: cover ? BoxFit.contain : null,
        loadingBuilder: (_, child, event) {
          if (event == null) return child;

          return const ClipRRect(
            borderRadius: BorderRadius.all(radiusLarge),
            child: ShimmerWidget(),
          );
        },
      );
    }
  }
}

class StickerPackPage extends StatelessWidget {
  const StickerPackPage({super.key});

  static MaterialPageRoute<void> get route => MaterialPageRoute<void>(
        builder: (_) => const StickerPackPage(),
        settings: const RouteSettings(
          name: stickerPackRoute,
        ),
      );

  Future<void> _onDeletePressed(
    BuildContext context,
    StickerPackState state,
  ) async {
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

  Future<void> _onInstallPressed(
    BuildContext context,
    StickerPackState state,
  ) async {
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
      child,
      color: color,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.stickerPack?.description ?? '',
                    ),
                    if (state.stickerPack?.restricted ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          t.pages.stickerPack.restricted,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
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
          padding: const EdgeInsets.only(
            top: 16,
            left: 8,
            right: 8,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: state.stickerPack!.stickers.length,
            itemBuilder: (_, index) {
              final sticker = state.stickerPack!.stickers[index];
              return InkWell(
                child: StickerWrapper(
                  sticker,
                  cover: false,
                ),
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return IgnorePointer(
                        child: StickerWrapper(
                          sticker,
                          cover: false,
                        ),
                      );
                    },
                  );
                },
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
        body: state.isWorking
            ? SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                  ],
                ),
              )
            : _buildBody(context, state),
      ),
    );
  }
}
