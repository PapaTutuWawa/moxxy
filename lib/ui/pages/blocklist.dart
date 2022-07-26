import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum BlocklistOptions {
  unblockAll
}

class BlocklistPage extends StatelessWidget {
  const BlocklistPage({ Key? key }) : super(key: key);

  static MaterialPageRoute get route => MaterialPageRoute<dynamic>(builder: (_) => const BlocklistPage());
  
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
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('You have no users blocked'),
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
                  'Unblock $jid?',
                  'Are you sure you want to unblock $jid? You will receive messages from this user again.',
                  context,
                  () {
                    context.read<BlocklistBloc>().add(UnblockedJidEvent(jid));
                    Navigator.of(context).pop();
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
          'Blocklist',
          extra: [
            Expanded(child: Container()),
            PopupMenuButton(
              onSelected: (BlocklistOptions result) {
                if (result == BlocklistOptions.unblockAll) {
                  showConfirmationDialog(
                    'Are you sure?',
                    'Are you sure you want to unblock all users?',
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
                const PopupMenuItem(
                  value: BlocklistOptions.unblockAll,
                  child: Text('Unblock all'),
                )
              ],
            )
          ],
        ),
        body: _buildListView(state),
      ),
    );
  }
}
