import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';

class StickerChatWidget extends StatelessWidget {
  const StickerChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent,
    {
      super.key,
    }
  );
  final Message message;
  final double maxWidth;
  final BorderRadius radius;
  final bool sent;

  @override
  Widget build(BuildContext context) {
    // TODO(PapaTutuWawa): Handle stickers we don't have
    final stickerKey = StickerKey(message.stickerPackId!, message.stickerId!);
    final sticker = GetIt.I.get<StickersBloc>().state.stickerMap[stickerKey]!;

    return IntrinsicHeight(
      child: Column(
        children: [
          Image.file(File(sticker.path)),

          Align(
            alignment: sent ?
              Alignment.centerRight :
              Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sent ?
                    bubbleColorSent :
                    bubbleColorReceived,
                  borderRadius: const BorderRadius.all(radiusLarge),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: MessageBubbleBottom(message, sent, shrink: true), 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
