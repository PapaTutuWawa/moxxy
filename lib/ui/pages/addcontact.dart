import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/addcontact_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/button.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class AddContactPage extends StatelessWidget {
  const AddContactPage({ Key? key }) : super(key: key);

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (_) => const AddContactPage(),
    settings: const RouteSettings(
      name: addContactRoute,
    ),
  );
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddContactBloc, AddContactState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.simple('Add new contact'),
        body: Column(
          children: [
            Visibility(
              visible: state.working,
              child: const LinearProgressIndicator(),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8)),
              child: CustomTextField(
                labelText: 'XMPP-Address',
                onChanged: (value) => context.read<AddContactBloc>().add(
                  JidChangedEvent(value),
                ),
                enabled: !state.working,
                cornerRadius: textfieldRadiusRegular,
                borderColor: primaryColor,
                borderWidth: 1,
                errorText: state.jidError,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () {
                    showNotImplementedDialog('QR-code scanning', context);
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8)),
              child: const Text(
                'You can add a contact either by typing in their XMPP address or by scanning their QR code',
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 32)),
              child: Row(
                children: [
                  Expanded(
                    child: RoundedButton(
                      cornerRadius: 32,
                      onTap: () => context.read<AddContactBloc>().add(AddedContactEvent()),
                      enabled: !state.working,
                      child: const Text('Add to contacts'),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
