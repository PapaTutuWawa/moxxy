/*
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/blocklist/actions.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";

enum BlocklistOptions {
  unblockAll
}

class _BlocklistPageViewModel {
  final List<String> blocklist;
  final void Function() unblockAll;
  final void Function(String) unblockJid;

  const _BlocklistPageViewModel({
      required this.blocklist,
      required this.unblockAll,
      required this.unblockJid
  });
}

class BlocklistPage extends StatelessWidget {
  Widget _buildListView(_BlocklistPageViewModel viewModel) {
    if (viewModel.blocklist.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Image.asset("assets/images/happy_news.png")
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("You have no users blocked")
            )
          ]
        )
      );
    }

    return ListView.builder(
      itemCount: viewModel.blocklist.length,
      itemBuilder: (context, index) {
        final jid = viewModel.blocklist[index];

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32.0,
            vertical: 16.0
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(jid)
              ),
              IconButton(
                icon: Icon(Icons.delete),
                color: Colors.red,
                onPressed: () => showConfirmationDialog(
                  "Unblock $jid?",
                  "Are you sure you want to unblock $jid? You will receive messages from this user again.",
                  context,
                  () {
                    viewModel.unblockJid(jid);
                    Navigator.of(context).pop();
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // 
    return StoreConnector<MoxxyState, _BlocklistPageViewModel>(
      converter: (store) => _BlocklistPageViewModel(
        blocklist: store.state.blocklist,
        unblockAll: () => store.dispatch(UnblockAllUIAction()),
        unblockJid: (jid) => store.dispatch(UnblockJidUIAction(jid: jid))
      ),
      builder: (context, viewModel) => Scaffold(
        appBar: BorderlessTopbar.simple(
          title: "Blocklist",
          extra: [
            Expanded(child: Container()),
            PopupMenuButton(
              onSelected: (BlocklistOptions result) {
                if (result == BlocklistOptions.unblockAll) {
                  showConfirmationDialog(
                    "Are you sure?",
                    "Are you sure you want to unblock all users?",
                    context,
                    () {
                      viewModel.unblockAll();
                      Navigator.of(context).pop();
                    }
                  );
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: BlocklistOptions.unblockAll,
                  child: Text("Unblock all")
                )
              ]
            )
          ]
        ),
        body: _buildListView(viewModel)
      )
    );
  }
}
*/
