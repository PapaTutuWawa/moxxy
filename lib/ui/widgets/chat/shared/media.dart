import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/summary.dart';

class SharedMediaDisplay extends StatelessWidget {
  const SharedMediaDisplay({
    required this.preview,
    required this.jid,
    required this.title,
    required this.sharedMediaAmount,
    super.key,
  });

  /// The list of preview shared media items.
  final List<SharedMedium> preview;

  /// The JID of the conversation.
  final String jid;

  /// The title of the conversation.
  final String title;

  /// The total amount of shared media items associated with the conversation.
  final int sharedMediaAmount;
  
  @override
  Widget build(BuildContext context) {
    if (preview.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 25,
            left: 16,
            right: 16,
          ),
          child: Text(
            t.pages.profile.conversation.sharedMedia,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: Container(
            alignment: Alignment.topLeft,
            child: GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              children: preview
                .sublist(0, 8)
                .map((el) {
                  if (el == preview.last) {
                    return SharedSummaryWidget(
                      notShown: sharedMediaAmount - 7,
                      conversationJid: jid,
                      conversationTitle: title,
                    );
                  }

                  return buildSharedMediaWidget(el, jid);
                }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
