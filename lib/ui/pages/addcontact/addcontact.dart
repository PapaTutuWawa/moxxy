/*
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/button.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/addcontact/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";

class _AddContactPageViewModel {
  final bool doingWork;
  final String? errorText;
  final void Function(String jid) addContact;
  final void Function() resetErrors;

  const _AddContactPageViewModel({ required this.addContact, required this.doingWork, required this.resetErrors, this.errorText });
}

// TODO: Reset the errorText using WillPopScope
class AddContactPage extends StatelessWidget {
  final TextEditingController _controller;

  AddContactPage({ Key? key }) : _controller = TextEditingController(), super(key: key);
  
  void _addToRoster(BuildContext context, _AddContactPageViewModel viewModel) {
    if (_controller.text.isEmpty) return;

    viewModel.resetErrors();
    viewModel.addContact(_controller.text);
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _AddContactPageViewModel>(
      converter: (store) => _AddContactPageViewModel(
        doingWork: store.state.globalState.doingWork,
        errorText: store.state.addContactErrorText,
        addContact: (jid) => store.dispatch(AddContactAction(jid: jid)),
        resetErrors: () => store.dispatch(AddContactSetErrorLogin())
      ),
      builder: (context, viewModel) => Scaffold(
        appBar: BorderlessTopbar.simple(title: "Add new contact"),
        body: Column(
          children: [
            Visibility(
              visible: viewModel.doingWork,
              child: const LinearProgressIndicator(value: null)
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8.0)),
              child: CustomTextField(
                maxLines: 1,
                controller: _controller,
                labelText: "XMPP-Address",
                cornerRadius: textfieldRadiusRegular,
                contentPadding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                errorText: viewModel.errorText,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () {
                    showNotImplementedDialog("QR-code scanning", context);
                  }
                )
              )
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8.0)),
              child: const Text(
                "You can add a contact either by typing in their XMPP address or by scanning their QR code"
              )
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 32.0)),
              child: Row(
                children: [
                  Expanded(
                    child: RoundedButton(
                      color: Colors.purple,
                      child: const Text("Add to contacts"),
                      cornerRadius: 32.0,
                      onTap: () => _addToRoster(context, viewModel)
                    )
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }
}
*/
