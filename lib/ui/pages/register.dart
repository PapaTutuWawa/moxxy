import "dart:collection";
import "dart:math";
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/register/state.dart';
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/redux/registration/actions.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _RegistrationPageViewModel {
  final int providerIndex;
  final void Function(int index) setProviderIndex;

  _RegistrationPageViewModel({ required this.providerIndex, required this.setProviderIndex });
}

// TODO: Maybe generate this at build time
const List<String> _XMPP_PROVIDERS = [
  "chapril.org",
  "hookipa.net",
  "jabbers.one",
  "lightswitch.org",
  "magicbroccoli.de",
  "nixnet.services",
  "sure.im"
];

class RegistrationPage extends StatelessWidget {
  void _generateNewProvider(_RegistrationPageViewModel viewModel) {
    int newIndex = Random().nextInt(_XMPP_PROVIDERS.length);
    // Prevent generating the same provider twice back-to-back
    if (newIndex == viewModel.providerIndex) {
      newIndex = newIndex + 1 % _XMPP_PROVIDERS.length;
    }

    viewModel.setProviderIndex(newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _RegistrationPageViewModel>(
      converter: (store) => _RegistrationPageViewModel(
        providerIndex: store.state.registerPageState.providerIndex,
        setProviderIndex: (index) => store.dispatch(NewProviderAction(
            index: index
        ))
      ),
      builder: (context, viewModel) => Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: BorderlessTopbar(
            children: [
              BackButton(),
              Text(
                "Register",
                style: TextStyle(
                  fontSize: 19
                )
              )
            ]
          )
        ),
        // TODO: The TextFields look a bit too smal
        // TODO: Hide the LinearProgressIndicator if we're not doing anything
        // TODO: Disable the inputs and the BackButton if we're working on loggin in
        body: Column(
          children: [
            LinearProgressIndicator(value: null),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE, vertical: 16.0),
              child: Text("XMPP is a lot like e-mail: You can send e-mails to people who are not using your specific e-mail provider. As such, there are a lot of XMPP providers. To help you, we chose a random one from a curated list. You only have to pick a username.")
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(bottom: 8.0)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    width: 1,
                    color: Colors.purple
                  )
                ),
                child: TextField(
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: "Username",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                    suffixText: "@" + _XMPP_PROVIDERS[viewModel.providerIndex],
                    suffixIcon: Padding(
                      padding: EdgeInsetsDirectional.only(end: 6.0),
                      child: IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () => this._generateNewProvider(viewModel)
                      )
                    )
                  )
                )
              )
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
                    child: ElevatedButton(
                      child: Text("Register"),
                      onPressed: () {}
                    )
                  )
                )
              ]
            )
          ]
        )
      )
    );
  }
}
