import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/sticker_pack_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class StickerChatWidget extends StatelessWidget {
  const StickerChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent, {
    super.key,
  });
  final Message message;
  final double maxWidth;
  final BorderRadius radius;
  final bool sent;

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
                  PhosphorIcons.stickerBold,
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
    return IntrinsicHeight(
      child: Column(
        children: [
          // ignore: prefer_if_elements_to_conditional_expressions
          message.fileMetadata?.path != null &&
                  GetIt.I.get<PreferencesBloc>().state.enableStickers
              ? InkWell(
                  onTap: () {
                    GetIt.I.get<StickerPackBloc>().add(
                          LocallyAvailableStickerPackRequested(
                            message.stickerPackId!,
                          ),
                        );
                  },
                  child: Image.file(
                    File(message.fileMetadata!.path!),
                    // TODO(Unknown): Maybe set the cache size based on display dimensions
                    cacheWidth: 300,
                    cacheHeight: 300,
                  ),
                )
              : InkWell(
                  onTap: () {
                    context.read<StickerPackBloc>().add(
                          RemoteStickerPackRequested(
                            message.stickerPackId!,
                            // TODO(PapaTutuWawa): This does not feel clean
                            message.sender.split('/').first,
                          ),
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
