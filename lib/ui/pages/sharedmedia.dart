import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/shared_media_controller.dart';
import 'package:moxxyv2/ui/widgets/chat/message.dart';
import 'package:moxxyv2/ui/widgets/grouped_grid_view.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class SharedMediaPageArguments {
  SharedMediaPageArguments(
    this.conversationJid,
    this.conversationTitle,
  );

  /// The JID of the conversation we display the shared media items of.
  final String conversationJid;

  /// The title of the conversation.
  final String conversationTitle;
}

class SharedMediaPage extends StatefulWidget {
  const SharedMediaPage({
    required this.arguments,
    super.key,
  });

  static MaterialPageRoute<void> getRoute(SharedMediaPageArguments arguments) {
    return MaterialPageRoute<void>(
      builder: (_) => SharedMediaPage(arguments: arguments),
      settings: const RouteSettings(
        name: sharedMediaRoute,
      ),
    );
  }

  /// The arguments passed to the page.
  final SharedMediaPageArguments arguments;

  @override
  SharedMediaPageState createState() => SharedMediaPageState();
}

class SharedMediaPageState extends State<SharedMediaPage> {
  late final BidirectionalSharedMediaController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        BidirectionalSharedMediaController(widget.arguments.conversationJid);
    _controller.fetchOlderData();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: BorderlessTopbar.simple(widget.arguments.conversationTitle),
      body: StreamBuilder<List<SharedMedium>>(
        initialData: const [],
        stream: _controller.dataStream,
        builder: (context, snapshot) {
          return GroupedGridView<SharedMedium, DateTime>(
            controller: _controller.scrollController,
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
            itemBuilder: (_, medium) => buildSharedMediaWidget(
              medium,
              widget.arguments.conversationJid,
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
    );
  }
}
