import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/state/preferences.dart';
import 'package:moxxyv2/ui/state/sticker_pack.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/sender_name.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StickerChatWidget extends StatelessWidget {
  const StickerChatWidget(
    this.message,
    this.maxWidth,
    this.sent,
    this.isGroupchat, {
    this.quotedMessage,
    super.key,
  });

  /// The message containing the sticker.
  final Message message;

  /// The maximum possible width of the message.
  final double maxWidth;

  /// True, if the sticker was sent by us. False, if not.
  final bool sent;

  /// Whether the message was sent/received in a groupchat context (true) or not (false).
  final bool isGroupchat;

  /// A built message quote, if [message] quotes another message.
  final Widget? quotedMessage;

  Widget _buildNotAvailable(BuildContext context) {
    return Align(
      alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: sent ? bubbleColorSent : bubbleColorReceived,
          borderRadius: const BorderRadius.all(radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  PhosphorIconsRegular.sticker,
                ),
              ),
              Text(
                message.body,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final density = MediaQuery.of(context).devicePixelRatio;
    return IntrinsicHeight(
      child: Column(
        children: [
          if (isGroupchat)
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                top: 8,
                bottom: 8,
              ),
              child: SenderName(
                message.senderJid,
                sent,
                isGroupchat,
              ),
            ),

          if (quotedMessage != null) quotedMessage!,

          // ignore: prefer_if_elements_to_conditional_expressions
          message.fileMetadata?.path != null &&
                  GetIt.I.get<PreferencesCubit>().state.enableStickers
              ? InkWell(
                  onTap: () {
                    GetIt.I.get<StickerPackCubit>().requestLocalStickerPack(
                          message.stickerPackId!,
                        );
                  },
                  child: Image.file(
                    File(message.fileMetadata!.path!),
                    cacheWidth: (300 * density).toInt(),
                    cacheHeight: (300 * density).toInt(),
                  ),
                )
              : InkWell(
                  onTap: () {
                    context.read<StickerPackCubit>().requestRemoteStickerPack(
                          message.stickerPackId!,
                          // TODO(PapaTutuWawa): This does not feel clean
                          message.sender.split('/').first,
                        );
                  },
                  child: _buildNotAvailable(context),
                ),

          Align(
            alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: sent ? bubbleColorSent : bubbleColorReceived,
                  borderRadius: const BorderRadius.all(radiusLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: MessageBubbleBottom(
                    message,
                    sent,
                    shrink: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
