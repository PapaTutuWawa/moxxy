import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/groupchat/joingroupchat_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/button.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

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
    return BlocBuilder<JoinGroupchatBloc, JoinGroupchatState>(
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          if (state.isWorking) {
            return false;
          }

          context.read<JoinGroupchatBloc>().add(
                PageResetEvent(),
              );
          return true;
        },
        child: Scaffold(
          appBar: BorderlessTopbar.title(t.pages.newconversation.enterNickname),
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
                child: CustomTextField(
                  onChanged: (value) => context.read<JoinGroupchatBloc>().add(
                        NickChangedEvent(value),
                      ),
                  labelText: t.pages.newconversation.nick,
                  controller: _nickController,
                  enabled: !state.isWorking,
                  cornerRadius: textfieldRadiusRegular,
                  borderColor: primaryColor,
                  borderWidth: 1,
                  errorText: state.nickError,
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
                      child: RoundedButton(
                        cornerRadius: 32,
                        onTap: () => context.read<JoinGroupchatBloc>().add(
                              StartGroupchatEvent(
                                widget.arguments.jid,
                              ),
                            ),
                        enabled: !state.isWorking,
                        child: Text(t.pages.newconversation.joinGroupChat),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
