import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/bloc/navigation_bloc.dart' as nav;
import 'package:moxxyv2/ui/bloc/sticker_pack.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/sticker_pack_controller.dart';

/// A wrapper data class to group by a sticker pack's id, but display its title.
@immutable
class _StickerPackSeparator {
  const _StickerPackSeparator(
    this.name,
    this.id,
  );

  /// The title of the sticker pack.
  final String name;

  /// The identifier of the sticker pack.
  final String id;

  @override
  bool operator ==(Object other) {
    return other is _StickerPackSeparator &&
        other.name == name &&
        other.id == id;
  }

  @override
  int get hashCode => name.hashCode ^ id.hashCode;
}

class StickerPicker extends StatefulWidget {
  StickerPicker({
    required this.width,
    required this.onStickerTapped,
    super.key,
  }) {
    itemSize = (width - 2 * 15 - 3 * 30) / 4;
  }

  final double width;

  final void Function(Sticker) onStickerTapped;

  late final double itemSize;

  @override
  StickerPickerState createState() => StickerPickerState();
}

class StickerPickerState extends State<StickerPicker> {
  final BidirectionalStickerPackController _controller =
      BidirectionalStickerPackController(true);

  @override
  void initState() {
    super.initState();

    // Fetch the initial state
    _controller.fetchOlderData();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersBloc, StickersState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: StreamBuilder<List<StickerPack>>(
            stream: _controller.dataStream,
            initialData: const [],
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.none &&
                  snapshot.connectionState != ConnectionState.waiting &&
                  snapshot.data!.isEmpty) {
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
                                    const nav.NavigationDestination(
                                      stickersRoute,
                                    ),
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

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GroupedListView<StickerPack, _StickerPackSeparator>(
                  controller: _controller.scrollController,
                  elements: snapshot.data!,
                  groupBy: (stickerPack) => _StickerPackSeparator(
                    stickerPack.name,
                    stickerPack.id,
                  ),
                  groupSeparatorBuilder: (separator) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      separator.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  sort: false,
                  indexedItemBuilder: (context, stickerPack, index) =>
                      GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemCount: stickerPack.stickers.length,
                    itemBuilder: (_, index) {
                      return InkWell(
                        onTap: () {
                          widget.onStickerTapped(
                            stickerPack.stickers[index],
                          );
                        },
                        onLongPress: () {
                          Vibrate.feedback(FeedbackType.medium);

                          context
                              .read<StickerPackCubit>()
                              .requestLocalStickerPack(
                                stickerPack.id,
                              );
                        },
                        child: Image.file(
                          File(
                            stickerPack.stickers[index].fileMetadata.path!,
                          ),
                          key: ValueKey('${stickerPack.id}_$index'),
                          fit: BoxFit.contain,
                          width: widget.itemSize,
                          height: widget.itemSize,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
