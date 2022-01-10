import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";

class _AddContactPageViewModel {
  final bool doingWork;
  final String? errorText;
  final void Function(String jid) addContact;
  final void Function() resetErrors;

  _AddContactPageViewModel({ required this.addContact, required this.doingWork, required this.resetErrors, this.errorText });
}

// TODO: Reset the errorText using WillPopScope
class AddContactPage extends StatelessWidget {
  TextEditingController controller = TextEditingController();

  void _addToRoster(BuildContext context, _AddContactPageViewModel viewModel) {
    viewModel.resetErrors();
    viewModel.addContact(this.controller.text);
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
              child: LinearProgressIndicator(value: null)
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 8.0)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    width: 1,
                    color: Colors.purple
                  )
                ),
                child: CustomTextField(
                  maxLines: 1,
                  controller: this.controller,
                  labelText: "XMPP-Address",
                  cornerRadius: TEXTFIELD_RADIUS_REGULAR,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                  errorText: viewModel.errorText,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.qr_code),
                    onPressed: () {
                      showNotImplementedDialog("QR-code scanning", context);
                    }
                  )
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 8.0)),
              child: Text("You can add a contact either by typing in their XMPP address or by scanning their QR code")
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
                    child: ElevatedButton(
                      child: Text("Add to contacts"),
                      onPressed: viewModel.doingWork ? null : () => _addToRoster(context, viewModel)
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
