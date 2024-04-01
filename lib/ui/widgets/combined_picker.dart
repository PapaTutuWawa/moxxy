import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/ui/state/stickers.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/sticker_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CombinedPicker extends StatelessWidget {
  const CombinedPicker({
    required this.tabController,
    required this.onEmojiTapped,
    required this.onBackspaceTapped,
    required this.onStickerTapped,
    super.key,
  });

  /// The controlling tab controller
  final TabController tabController;

  /// Called when an emoji has been tapped from the list.
  final void Function(Emoji) onEmojiTapped;

  /// Called when the backspace button has been tapped
  final void Function() onBackspaceTapped;

  /// Called when a sticker has been tapped
  final void Function(Sticker) onStickerTapped;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickersCubit, StickersState>(
      builder: (context, state) {
        final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
        final width = MediaQuery.of(context).size.width;
        return SizedBox(
          height: pickerHeight,
          width: width,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                TabBar(
                  controller: tabController,
                  indicatorColor: primaryColor,
                  tabs: [
                    const Tab(icon: Icon(Icons.insert_emoticon)),
                    Tab(icon: Icon(PhosphorIcons.regular.sticker)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      EmojiPicker(
                        onEmojiSelected: (_, emoji) => onEmojiTapped(emoji),
                        onBackspacePressed: onBackspaceTapped,
                        config: getEmojiPickerConfig(
                          scaffoldColor,
                        ),
                      ),
                      StickerPicker(
                        width: width,
                        onStickerTapped: onStickerTapped,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
