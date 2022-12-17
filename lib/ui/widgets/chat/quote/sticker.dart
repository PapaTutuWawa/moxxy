import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/media.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QuotedStickerWidget extends StatelessWidget {
  const QuotedStickerWidget(
    this.message,
    this.sent, {
      this.resetQuote,
      super.key,
    }
  );
  final Message message;
  final bool sent;
  final void Function()? resetQuote;

  @override
  Widget build(BuildContext context) {
    Sticker? sticker;
    if (message.stickerPackId != null &&
        message.stickerHashKey != null &&
        GetIt.I.get<PreferencesBloc>().state.enableStickers) {
      final stickerKey = StickerKey(message.stickerPackId!, message.stickerHashKey!);
      sticker = GetIt.I.get<StickersBloc>().state.stickerMap[stickerKey];
    }

    if (sticker != null) {
      return QuotedMediaBaseWidget(
        message,
        SharedImageWidget(
          sticker.path,
          size: 48,
          borderRadius: 8,
        ),
        message.body,
        sent,
        resetQuote: resetQuote,
      );
    } else {
      return QuoteBaseWidget(
        message,
        Row(
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
        sent,
        resetQuotedMessage: resetQuote,
      );
    }
  }
}
