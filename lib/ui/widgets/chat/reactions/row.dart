import 'package:flutter/material.dart';

typedef ReactionTappedCallback = void Function(String);

class ReactionsRow extends StatelessWidget {
  const ReactionsRow(
    {
      required this.avatar,
      required this.displayName,
      required this.emojis,
      this.onAddPressed,
      this.onReactionPressed,
      super.key,
    }
  );

  /// The avatar shown on the left size.
  final Widget avatar;

  /// The name to show next to the avatar.
  final String displayName;
  
  /// The list of emojis that are used as a reaction.
  final List<String> emojis;

  /// If non-null, display an "add button" that triggers this function
  /// when tapped. If null, does nothing.
  final VoidCallback? onAddPressed;

  /// If non-null, treats all reactions are our own reactions. If such a reaction
  /// is tapped, calls this callback with the corresponding emoji. If null, treats
  /// all reactions as someone else's reactions.
  final ReactionTappedCallback? onReactionPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              avatar,

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    displayName,
                    maxLines: 1,
                    style: const TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              if (onAddPressed != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: IconButton(
                    iconSize: 35,
                    icon: const Icon(Icons.add),
                    onPressed: onAddPressed,
                  ),
                ),
            ],
          ),

          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: emojis.map((e) => ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(40)),
                child: Material(
                  color: onReactionPressed != null
                    // TODO: Move to ui/constants.dart
                    ? const Color(0xff2993FB)
                    : const Color(0xff757575),
                  child: InkWell(
                    onTap: onReactionPressed != null
                      ? () => onReactionPressed!(e)
                      : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }
}
