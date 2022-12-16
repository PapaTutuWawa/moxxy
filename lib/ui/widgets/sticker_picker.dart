import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';

class StickerPicker extends StatelessWidget {
  StickerPicker({
    required this.width,
    super.key,
  }) {
    _itemSize = (width - 2 * 15 - 3 * 30) / 4;
  }

  final double width;
  late final double _itemSize;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersBloc, StickersState>(
      builder: (context, state) {
        return SizedBox(
          height: 250,
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            itemCount: state.stickerPacks.length * 2,
            itemBuilder: (_, si) {
              if (si.isEven) {
                return Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text(
                    state.stickerPacks[si ~/ 2].name,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                );
              }
              
              final sindex = (si - 1) ~/ 2;
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: (state.stickerPacks[sindex].stickers.length / 4).ceil(),
                itemBuilder: (_, index) {
                  final stickersLength = state.stickerPacks[sindex].stickers.length - index * 4;
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
                              onTap: () => print(index),
                              child: Image.file(
                                File(
                                  state.stickerPacks[sindex].stickers[index * 4 + rowIndex].path,
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
        );
      },
    );
  }
}
