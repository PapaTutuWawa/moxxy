import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";
import "package:moxxyv2/ui/helpers.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";

class _AddContactPageViewModel {
  final bool doingWork;
  final void Function(String jid) addContact;

  _AddContactPageViewModel({ required this.addContact, required this.doingWork});
}

class AddContactPage extends StatelessWidget {TextEditingController controller = TextEditingController();

  void _addToRoster(BuildContext context, _AddContactPageViewModel viewModel) {
    viewModel.addContact(this.controller.text);
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _AddContactPageViewModel>(
      converter: (store) => _AddContactPageViewModel(
        doingWork: store.state.globalState.doingWork,
        addContact: (jid) => store.dispatch(AddContactAction(jid: jid))
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
                child: TextField(
                  maxLines: 1,
                  enabled: !viewModel.doingWork,
                  controller: this.controller,
                  decoration: InputDecoration(
                    labelText: "XMPP-Address",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                    suffixIcon: Padding(
                      padding: EdgeInsetsDirectional.only(end: 6.0),
                      child: IconButton(
                        icon: Icon(Icons.qr_code),
                        onPressed: () {
                          showNotImplementedDialog("QR-code scanning", context);
                        }
                      )
                    )
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
