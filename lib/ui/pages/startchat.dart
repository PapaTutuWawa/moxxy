import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/state/startchat.dart';

class StartChatPage extends StatefulWidget {
  const StartChatPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StartChatPage(),
        settings: const RouteSettings(
          name: addContactRoute,
        ),
      );

  @override
  StartChatPageState createState() => StartChatPageState();
}

class StartChatPageState extends State<StartChatPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartChatCubit, StartChatState>(
      builder: (context, state) => PopScope(
        canPop: !state.isWorking,
        onPopInvoked: (didPop) {
          if (didPop) {
            context.read<StartChatCubit>().reset();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(t.pages.startchat.title),
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
                  onChanged: context.read<StartChatCubit>().onJidChanged,
                  controller: _controller,
                  enabled: !state.isWorking,
                  decoration: InputDecoration(
                    error:
                        state.jidError != null ? Text(state.jidError!) : null,
                    labelText: t.pages.startchat.xmppAddress,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () async {
                        final jid = await scanXmppUriQrCode(context);
                        if (jid == null) return;

                        _controller.text = jid.path;
                        // ignore: use_build_context_synchronously
                        context.read<StartChatCubit>().onJidChanged(jid.path);
                      },
                    ),
                  ),
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
                      child: FilledButton(
                        onPressed: state.isWorking
                            ? null
                            : context.read<StartChatCubit>().addContact,
                        child: Text(t.pages.startchat.buttonAddToContact),
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
