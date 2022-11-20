import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum BlocklistOptions {
  unblockAll
}

class BlocklistPage extends StatelessWidget {
  const BlocklistPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const BlocklistPage(),
    settings: const RouteSettings(
      name: blocklistRoute,
    ),
  );
  
  Widget _buildListView(BlocklistState state) {
    // ignore: non_bool_condition,avoid_dynamic_calls
    if (state.blocklist.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.asset('assets/images/happy_news.png'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(t.pages.blocklist.noUsersBlocked),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.blocklist.length,
      itemBuilder: (BuildContext context, int index) {
        // ignore: avoid_dynamic_calls
        final jid = state.blocklist[index];

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(jid),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: () => showConfirmationDialog(
                  t.pages.blocklist.unblockJidConfirmTitle(jid: jid),
                  t.pages.blocklist.unblockJidConfirmBody(jid: jid),
                  context,
                  () {
                    context.read<BlocklistBloc>().add(UnblockedJidEvent(jid));
                  }
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlocklistBloc, BlocklistState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(
          t.pages.blocklist.title,
          extra: [
            Expanded(child: Container()),
            PopupMenuButton(
              onSelected: (BlocklistOptions result) {
                if (result == BlocklistOptions.unblockAll) {
                  showConfirmationDialog(
                    t.pages.blocklist.unblockAllConfirmTitle,
                    t.pages.blocklist.unblockAllConfirmBody,
                    context,
                    () {
                      context.read<BlocklistBloc>().add(UnblockedAllEvent());
                      Navigator.of(context).pop();
                    }
                  );
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: BlocklistOptions.unblockAll,
                  child: Text(t.pages.blocklist.unblockAll),
                ),
              ],
            )
          ],
        ),
        body: _buildListView(state),
      ),
    );
  }
}
