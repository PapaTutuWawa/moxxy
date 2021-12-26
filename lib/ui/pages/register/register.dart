import "dart:collection";
import "dart:math";
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/register/state.dart';
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/redux/registration/actions.dart';
import "package:moxxyv2/data/generated/providers.dart";

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _RegistrationPageViewModel {
  final int providerIndex;
  final bool doingWork;
  final void Function(int index) setProviderIndex;
  final void Function() performRegistration;

  _RegistrationPageViewModel({ required this.providerIndex, required this.setProviderIndex, required this.doingWork, required this.performRegistration });
}

class RegistrationPage extends StatelessWidget {
  void _generateNewProvider(_RegistrationPageViewModel viewModel) {
    int newIndex = Random().nextInt(xmppProviderList.length);
    // Prevent generating the same provider twice back-to-back
    if (newIndex == viewModel.providerIndex) {
      newIndex = newIndex + 1 % xmppProviderList.length;
    }

    viewModel.setProviderIndex(newIndex);
  }

  void _performRegistration(BuildContext context, _RegistrationPageViewModel viewModel) {
    viewModel.performRegistration();

    Future.delayed(Duration(seconds: 3), () => Navigator.pushNamedAndRemoveUntil(context, "/register/post", (route) => false));
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _RegistrationPageViewModel>(
      converter: (store) => _RegistrationPageViewModel(
        providerIndex: store.state.registerPageState.providerIndex,
        setProviderIndex: (index) => store.dispatch(NewProviderAction(
            index: index
        )),
        doingWork: store.state.registerPageState.doingWork,
        performRegistration: () => store.dispatch(PerformRegistrationAction())
      ),
      builder: (context, viewModel) => Scaffold(
        appBar: BorderlessTopbar.simple(title: "Register"),
        // TODO: The TextFields look a bit too smal
        // TODO: Hide the LinearProgressIndicator if we're not doing anything
        // TODO: Disable the inputs and the BackButton if we're working on loggin in
        body: Column(
          children: [
            Visibility(
              visible: viewModel.doingWork,
              child: LinearProgressIndicator(
                value: null,
                valueColor: AlwaysStoppedAnimation<Color>(PRIMARY_COLOR)
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE, vertical: 16.0),
              child: Text(
                "XMPP is a lot like e-mail: You can send e-mails to people who are not using your specific e-mail provider. As such, there are a lot of XMPP providers. To help you, we chose a random one from a curated list. You only have to pick a username.",
                style: TextStyle(
                  fontSize: FONTSIZE_BODY
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(bottom: 8.0)),
              child: CustomTextField(
                maxLines: 1,
                labelText: "Username",
                suffixText: "@" + xmppProviderList[viewModel.providerIndex].jid,
                suffixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(end: 6.0),
                  child: IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: viewModel.doingWork ? null : () => this._generateNewProvider(viewModel)
                  )
                ),
                cornerRadius: TEXTFIELD_RADIUS_REGULAR
              )
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
                    child: ElevatedButton(
                      child: Text("Register"),
                      onPressed: viewModel.doingWork ? null : () => this._performRegistration(context, viewModel)
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
