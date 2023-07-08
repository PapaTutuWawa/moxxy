import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/shared_media_controller.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/date.dart';
import 'package:moxxyv2/ui/widgets/chat/shared.dart';
import 'package:moxxyv2/ui/widgets/grouped_grid_view.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

/// A widget that displays a lazily-loaded list of media files in a grid, grouped
/// by the send/receive date.
class SharedMediaView extends StatelessWidget {
  const SharedMediaView(
    this.mediaController, {
    required this.emptyText,
    required this.showBackButton,
    required this.onTap,
    this.title,
    this.onLongPress,
    super.key,
  });

  /// The controller used for requesting shared media messages.
  final BidirectionalSharedMediaController mediaController;

  /// Indicate whether to show the back button in the top bar or not.
  final bool showBackButton;

  /// An optional title to show in the top bar. If null, then the top bar is kept
  /// in size by a [SizedBox].
  final String? title;

  /// The text to show, when no media files are available, i.e. when no files have been
  /// sent/received in the chat.
  final String emptyText;

  /// Callback for when a widget has been tapped.
  final SharedMediaWidgetCallback onTap;

  /// Callback for when a widget has been long pressed.
  final SharedMediaWidgetCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: BorderlessTopbar(
        showBackButton: showBackButton,
        // Ensure the top bar has a height
        children: [
          if (title == null)
            const SizedBox(
              height: BorderlessTopbar.topbarPreferredHeight,
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: fontsizeAppbar,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<bool>(
              stream: mediaController.isFetchingStream,
              initialData: mediaController.isFetching,
              builder: (context, snapshot) {
                return snapshot.data!
                    ? const LinearProgressIndicator()
                    : const SizedBox();
              },
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<List<Message>>(
              stream: mediaController.dataStream,
              initialData: mediaController.cache,
              builder: (context, snapshot) {
                // Only show the image if we have no media files
                if (snapshot.connectionState != ConnectionState.none &&
                    snapshot.connectionState != ConnectionState.waiting &&
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/empty.png'),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            emptyText,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GroupedGridView<Message, DateTime>(
                  controller: mediaController.scrollController,
                  elements: snapshot.data!,
                  getKey: (m) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(m.timestamp);
                    return DateTime(
                      dt.year,
                      dt.month,
                      dt.day,
                    );
                  },
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  gridPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemBuilder: (_, message) => buildSharedMediaWidget(
                    message.fileMetadata!,
                    message.conversationJid,
                    onTap,
                    onLongPress: onLongPress,
                  ),
                  separatorBuilder: (_, timestamp) => Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                    ),
                    child: DateBubble(
                      formatDateBubble(timestamp, now),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
