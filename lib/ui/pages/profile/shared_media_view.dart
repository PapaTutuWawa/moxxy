import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/controller/shared_media_controller.dart';
import 'package:moxxyv2/ui/widgets/chat/message.dart';
import 'package:moxxyv2/ui/widgets/grouped_grid_view.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class SharedMediaView extends StatelessWidget {
  const SharedMediaView(this.mediaController, {super.key});

  /// The controller used for requesting shared media messages.
  final BidirectionalSharedMediaController mediaController;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: const BorderlessTopbar(
        showBackButton: false,
        // Ensure the top bar has a height
        children: [
          SizedBox(
            height: BorderlessTopbar.topbarPreferredHeight,
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
                  ),
                  separatorBuilder: (_, timestamp) => Padding(
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 4,
                      left: 16,
                    ),
                    child: Text(
                      formatDateBubble(timestamp, now),
                      style: const TextStyle(
                        fontSize: 25,
                      ),
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
