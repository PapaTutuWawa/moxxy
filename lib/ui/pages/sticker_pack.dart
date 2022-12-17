import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class StickerPackPage extends StatelessWidget {
  const StickerPackPage({ super.key });

  static MaterialPageRoute<void> get route => MaterialPageRoute<void>(
    builder: (_) => const StickerPackPage(),
    settings: const RouteSettings(
      name: stickerPackRoute,
    ),
  );

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
                  state.stickerPack?.description ?? 'Lorem Ipsum Dolor what the fuck',
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SharedMediaContainer(
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const ColoredBox(
                    color: Colors.red,
                    child: Icon(
                      Icons.delete,
                      size: 32,
                    ),
                  ),
                ),
                onTap: () async {
                  final result = await showConfirmationDialog(
                    'Remove sticker pack',
                    'Are you sure you want to remove this sticker pack?',
                    context,
                  );
                  if (result) {
                    // ignore: use_build_context_synchronously
                    context.read<StickerPackBloc>().add(
                      StickerPackRemovedEvent(state.stickerPack!.id),
                    );
                  }
                },
              ),
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
                      final file = File(state.stickerPack!.stickers[index * 4 + rowIndex].path);
                      return Padding(
                        padding: const EdgeInsets.all(15),
                        child: InkWell(
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) {
                                return IgnorePointer(
                                  child: Image.file(
                                    file,
                                    width: width - 80 * 2,
                                  ),
                                );
                              },
                            );
                          },
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
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
