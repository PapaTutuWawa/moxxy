import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/state/groupchat/joingroupchat.dart';

class JoinGroupchatArguments {
  JoinGroupchatArguments(this.jid);

  /// The JID of the conversation entity.
  final String jid;
}

class JoinGroupchatPage extends StatefulWidget {
  const JoinGroupchatPage(this.arguments, {super.key});

  final JoinGroupchatArguments arguments;

  static MaterialPageRoute<dynamic> getRoute(
    JoinGroupchatArguments arguments,
  ) =>
      MaterialPageRoute<dynamic>(
        builder: (_) => JoinGroupchatPage(arguments),
        settings: const RouteSettings(
          name: joinGroupchatRoute,
        ),
      );

  @override
  JoinGroupchatPageState createState() => JoinGroupchatPageState();
}

class JoinGroupchatPageState extends State<JoinGroupchatPage> {
  final TextEditingController _nickController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoinGroupchatCubit, JoinGroupchatState>(
      builder: (context, state) => PopScope(
        onPopInvoked: (didPop) {
          if (didPop) {
            context.read<JoinGroupchatCubit>().reset();
          }
        },
        canPop: !state.isWorking,
        child: Scaffold(
          appBar: AppBar(
            title: Text(t.pages.newconversation.enterNickname),
          ),
          body: Column(
            children: [
              Visibility(
                visible: state.isWorking,
                child: const LinearProgressIndicator(),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: TextField(
                  onChanged: context.read<JoinGroupchatCubit>().onNickChanged,
                  controller: _nickController,
                  enabled: !state.isWorking,
                  decoration: InputDecoration(
                    error:
                        state.nickError != null ? Text(state.nickError!) : null,
                    labelText: t.pages.newconversation.nick,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: Text(t.pages.newconversation.nicknameSubtitle),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 32)),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: state.isWorking
                            ? null
                            : () => context
                                .read<JoinGroupchatCubit>()
                                .startGroupchat(
                                  widget.arguments.jid,
                                ),
                        child: Text(t.pages.newconversation.joinGroupChat),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
