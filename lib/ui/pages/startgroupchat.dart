import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/groupchat/startgroupchat_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/button.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class StartGroupChatPage extends StatefulWidget {
  const StartGroupChatPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StartGroupChatPage(),
        settings: const RouteSettings(
          name: newGroupchatRoute,
        ),
      );

  @override
  StartGroupChatPageState createState() => StartGroupChatPageState();
}

class StartGroupChatPageState extends State<StartGroupChatPage> {
  final TextEditingController _jidController = TextEditingController();
  final TextEditingController _nickController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartGroupchatBloc, StartGroupchatState>(
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          if (state.isWorking) {
            return false;
          }

          context.read<StartGroupchatBloc>().add(
                PageResetEvent(),
              );
          return true;
        },
        child: Scaffold(
          appBar:
              BorderlessTopbar.title(t.pages.newconversation.createGroupchat),
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
                  labelText: t.pages.startchat.xmppAddress,
                  onChanged: (value) => context.read<StartGroupchatBloc>().add(
                        JidChangedEvent(value),
                      ),
                  controller: _jidController,
                  enabled: !state.isWorking,
                  cornerRadius: textfieldRadiusRegular,
                  borderColor: primaryColor,
                  borderWidth: 1,
                  errorText: state.jidError,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: () async {
                      final jid = await scanXmppUriQrCode(context);
                      if (jid == null) return;

                      _jidController.text = jid.path;
                      // ignore: use_build_context_synchronously
                      context.read<StartGroupchatBloc>().add(
                            JidChangedEvent(jid.path),
                          );
                    },
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: CustomTextField(
                  onChanged: (value) => context.read<StartGroupchatBloc>().add(
                        NickChangedEvent(value),
                      ),
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
                child: Text(t.pages.startchat.subtitle),
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
                        onTap: () => context
                            .read<StartGroupchatBloc>()
                            .add(JoinGroupchatEvent()),
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
