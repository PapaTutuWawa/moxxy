import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/ui/widgets/chat/message.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/summary.dart';

/// A class for adding a shadow to Containers which even works if the
/// Container is transparent.
///
/// NOTE: https://stackoverflow.com/a/55833281; Thank you kind stranger
class TransparentBoxShadow extends BoxShadow {
  const TransparentBoxShadow({
    required super.blurRadius,
  });

  @override
  Paint toPaint() {
    final result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    return result;
  }
}

const sharedMediaContainerDimension = 75.0;

/// A widget to show a message that was sent within a chat or is about to be sent.
class SharedMediaContainer extends StatelessWidget {
  const SharedMediaContainer(
    this.child, {
    required this.color,
    this.onTap,
    this.size = sharedMediaContainerDimension,
    this.borderRadius = 10,
    super.key,
  });
  final double borderRadius;
  final Widget? child;
  final void Function()? onTap;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final childWidget = SizedBox(
      height: size,
      width: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: child,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: color,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                child: childWidget,
              )
            : childWidget,
      ),
    );
  }
}

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
            style: Theme.of(context).textTheme.headlineSmall,
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
              children: preview.length < 8
                  ? preview
                      .map((el) => buildSharedMediaWidget(el, jid))
                      .toList()
                  : preview.sublist(0, 8).map((el) {
                      if (el == preview.last && sharedMediaAmount >= 8) {
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
