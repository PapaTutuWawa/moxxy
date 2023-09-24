import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/theme.dart';

// TODO: Somehow merge with SenderName
class QuoteSenderText extends StatelessWidget {
  const QuoteSenderText({
    required this.sender,
    required this.resetQuoteNotNull,
    required this.sent,
    super.key,
  });

  /// The sender JID of the quoted message.
  final String sender;

  /// True if resetQuote is not null.
  final bool resetQuoteNotNull;

  /// The sent attribute passed to the quote widget.
  final bool sent;

  @override
  Widget build(BuildContext context) {
    final sentBySelf = resetQuoteNotNull
        ? sent
        : sender == GetIt.I.get<UIDataService>().ownJid;

    return Text(
      sentBySelf
          ? t.messages.you
          : GetIt.I
              .get<ConversationBloc>()
              .state
              .conversation!
              .titleWithOptionalContact,
      style: const TextStyle(
        color: bubbleTextQuoteSenderColor,
        fontWeight: FontWeight.bold,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Figures out the best text color for quotes. [context] is the surrounding
/// BuildContext. [insideTextField] is true if the quote is used as a widget inside
/// the TextField.
Color getQuoteTextColor(BuildContext context, bool insideTextField) {
  if (!insideTextField) return bubbleTextQuoteColor;

  return Theme.of(context)
      .extension<MoxxyThemeData>()!
      .bubbleQuoteInTextFieldTextColor;
}
