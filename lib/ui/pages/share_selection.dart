import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/ui/bloc/share_selection_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class ShareSelectionPage extends StatelessWidget {
  const ShareSelectionPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const ShareSelectionPage(),
    settings: const RouteSettings(
      name: shareSelectionRoute,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final maxTextWidth = MediaQuery.of(context).size.width * 0.6;

    return WillPopScope(
      onWillPop: () async {
        context.read<ShareSelectionBloc>().add(ResetEvent());

        return true;
      },
      child: BlocBuilder<ShareSelectionBloc, ShareSelectionState>(
        builder: (context, state) => Scaffold(
          appBar: BorderlessTopbar.simple('Share with...'),
          body: ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              final isSelected = state.selection.contains(index);
              
              return InkWell(
                onTap: () {
                  context.read<ShareSelectionBloc>().add(
                    SelectionToggledEvent(index),
                  );
                },
                child: ConversationsListRow(
                  item.avatarPath,
                  item.title,
                  item.jid,
                  0,
                  maxTextWidth,
                  timestampNever,
                  false,
                  extra: isSelected ?
                  Radio(
                    value: true,
                    groupValue: true,
                    onChanged: (_) {},
                  ) :
                  null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
