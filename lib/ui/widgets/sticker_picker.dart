import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersBloc, StickersState>(
      builder: (context, state) {
        final stickerPacks = state.stickerPacks
          .where((pack) => !pack.restricted)
          .toList();

        return SizedBox(
          height: 250,
          width: MediaQuery.of(context).size.width,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ListView.builder(
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
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (stickerPacks[sindex].stickers.length / 4).ceil(),
                    itemBuilder: (_, index) {
                      final stickersLength = stickerPacks[sindex].stickers.length - index * 4;
                      return SizedBox(
                        width: width,
                        child: Row(
                          children: List<int>.generate(
                            stickersLength >= 4 ?
                              4 :
                              stickersLength,
                            (i) => i,
                          ).map((rowIndex) {
                              return Padding(
                                padding: const EdgeInsets.all(15),
                                child: InkWell(
                                  onTap: () {
                                    onStickerTapped(
                                      stickerPacks[sindex].stickers[index * 4 + rowIndex],
                                      stickerPacks[sindex],
                                    );
                                  },
                                  child: Image.file(
                                    File(
                                      stickerPacks[sindex].stickers[index * 4 + rowIndex].path,
                                    ),
                                    key: ValueKey('${state.stickerPacks[sindex].id}_${index * 4 + rowIndex}'),
                                    fit: BoxFit.contain,
                                    width: _itemSize,
                                    height: _itemSize,
                                  ),
                                ),
                              );
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
