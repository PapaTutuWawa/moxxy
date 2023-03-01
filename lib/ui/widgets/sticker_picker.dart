import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart' as nav;
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';

class StickerPicker extends StatelessWidget {
  StickerPicker({
    required this.width,
    required this.onStickerTapped,
    super.key,
  }) {
    _itemSize = (width - 2 * 15 - 3 * 30) / 4;
  }

  final double width;
  late final double _itemSize;
  final void Function(Sticker, StickerPack) onStickerTapped;

  Widget _buildList(BuildContext context, StickersState state) {
    // TODO(PapaTutuWawa): Solve this somewhere else
    final stickerPacks = state.stickerPacks
      .where((pack) => !pack.restricted)
      .toList();

    if (stickerPacks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${t.pages.conversation.stickerPickerNoStickersLine1}\n${t.pages.conversation.stickerPickerNoStickersLine2}',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  context.read<nav.NavigationBloc>().add(
                    nav.PushedNamedEvent(
                      const nav.NavigationDestination(stickersRoute),
                    ),
                  );
                },
                child: Text(t.pages.conversation.stickerSettings),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: stickerPacks.length * 2,
      itemBuilder: (_, si) {
        if (si.isEven) {
          return Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Text(
              stickerPacks[si ~/ 2].name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
          );
        }

        final sindex = (si - 1) ~/ 2;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: stickerPacks[sindex].stickers.length,
            itemBuilder: (_, index) {
              return InkWell(
                onTap: () {
                  onStickerTapped(
                    stickerPacks[sindex].stickers[index],
                    stickerPacks[sindex],
                  );
                },
                onLongPress: () {
                  Vibrate.feedback(FeedbackType.medium);

                  context.read<StickerPackBloc>().add(
                    LocallyAvailableStickerPackRequested(
                      stickerPacks[sindex].id,
                    ),
                  );
                },
                child: Image.file(
                  File(
                    stickerPacks[sindex].stickers[index].path,
                  ),
                  key: ValueKey('${state.stickerPacks[sindex].id}_$index'),
                  fit: BoxFit.contain,
                  width: _itemSize,
                  height: _itemSize,
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersBloc, StickersState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _buildList(context, state),
        );
      },
    );
  }
}
