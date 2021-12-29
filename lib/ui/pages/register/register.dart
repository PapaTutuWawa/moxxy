import "dart:collection";
import "dart:math";
import "package:flutter/material.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/redux/registration/state.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/registration/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/data/generated/providers.dart";

import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";

class _RegistrationPageViewModel {
  final int providerIndex;
  final bool doingWork;
  final String? errorText;
  final void Function(String jid) setAccountJid;
  final void Function(String displayName) setAccountDisplayName;
  final void Function(String text) setErrorText;
  final void Function() resetErrors;
  final void Function(int index) setProviderIndex;
  final void Function() performRegistration;

  _RegistrationPageViewModel({ required this.providerIndex, required this.setProviderIndex, required this.doingWork, required this.performRegistration, this.errorText, required this.setErrorText, required this.resetErrors, required this.setAccountJid, required this.setAccountDisplayName });
}

class RegistrationPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  void _generateNewProvider(_RegistrationPageViewModel viewModel) {
    int newIndex = Random().nextInt(xmppProviderList.length);
    // Prevent generating the same provider twice back-to-back
    if (newIndex == viewModel.providerIndex) {
      newIndex = newIndex + 1 % xmppProviderList.length;
    }

    viewModel.setProviderIndex(newIndex);
  }

  String _getCurrentJid(_RegistrationPageViewModel viewModel) {
    return this.controller.text + "@" + xmppProviderList[viewModel.providerIndex].jid;
  }
  
  void _performRegistration(BuildContext context, _RegistrationPageViewModel viewModel) {
    viewModel.resetErrors();

    if (this.controller.text.isEmpty) {
      viewModel.setErrorText("Username cannot be empty");
      return;
    }

    dismissSoftKeyboard(context);

    // TODO: Do this in the middleware
    viewModel.setAccountJid(this._getCurrentJid(viewModel));
    viewModel.setAccountDisplayName(this.controller.text);
    viewModel.performRegistration();
  }

  // Just a safety net to ensure we don't crash during first initialization
  int _getProviderIndex(_RegistrationPageViewModel viewModel) {
    return viewModel.providerIndex < 0 ? 0 : viewModel.providerIndex;
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _RegistrationPageViewModel>(
      converter: (store) => _RegistrationPageViewModel(
        providerIndex: store.state.registerPageState.providerIndex,
        setProviderIndex: (index) => store.dispatch(NewProviderAction(
            index: index
        )),
        doingWork: store.state.globalState.doingWork,
        performRegistration: () => store.dispatch(PerformRegistrationAction()),
        errorText: store.state.registerPageState.errorText,
        setErrorText: (text) => store.dispatch(RegistrationSetErrorTextAction(text: text)),
        resetErrors: () => store.dispatch(RegistrationResetErrorsAction()),
        setAccountJid: (jid) => store.dispatch(SetJidAction(jid: jid)),
        setAccountDisplayName: (displayName) => store.dispatch(SetDisplayNameAction(displayName: displayName))
      ),
      builder: (context, viewModel) {
        if (viewModel.providerIndex < 0) {
          this._generateNewProvider(viewModel);
        }

        return WillPopScope(
          onWillPop: () async => !viewModel.doingWork,
          child: Scaffold(
          appBar: BorderlessTopbar.simple(title: "Register"),
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
                  suffixText: "@" + xmppProviderList[this._getProviderIndex(viewModel)].jid,
                  suffixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.0),
                    child: IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: viewModel.doingWork ? null : () => this._generateNewProvider(viewModel)
                    )
                  ),
                  errorText: viewModel.errorText,
                  controller: this.controller,
                  enabled: !viewModel.doingWork,
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
    );
  }
}
