import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/button.dart";
import "package:moxxyv2/ui/bloc/addcontact_bloc.dart";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class AddContactPage extends StatelessWidget {
  const AddContactPage({ Key? key }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddContactBloc, AddContactState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple(title: "Add new contact"),
        body: Column(
          children: [
            Visibility(
              visible: state.working,
              child: const LinearProgressIndicator(value: null)
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8.0)),
              child: CustomTextField(
                maxLines: 1,
                labelText: "XMPP-Address",
                onChanged: (value) => context.read<AddContactBloc>().add(
                  JidChangedEvent(value)
                ),
                enabled: !state.working,
                cornerRadius: textfieldRadiusRegular,
                contentPadding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                errorText: state.jidError,
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
                      onTap: () => context.read<AddContactBloc>().add(AddedContactEvent())
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
