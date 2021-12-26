import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/snackbar.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/redux/postregister/actions.dart';
import 'package:moxxyv2/ui/pages/postregister/state.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _PostRegistrationPageViewModel {
  final bool showSnackbar;
  final void Function(bool show) setShowSnackbar;

  _PostRegistrationPageViewModel({required this.showSnackbar, required this.setShowSnackbar });
}

class PostRegistrationPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  // TODO
  final TextEditingController controller = TextEditingController(text: "Testuser");

  void _applyDisplayNameChange(_PostRegistrationPageViewModel viewModel) {
    // TODO
    // TODO: Maybe show a LinearProgressIndicator
    viewModel.setShowSnackbar(false);
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Scaffold(
        key: this.scaffoldKey,
        body: StoreConnector<MoxxyState, _PostRegistrationPageViewModel>(
          converter: (store) => _PostRegistrationPageViewModel(
            showSnackbar: store.state.postRegisterPageState.showSnackbar,
            setShowSnackbar: (show) => store.dispatch(PostRegisterSetShowSnackbarAction(show: show))
          ),
          builder: (context, viewModel) => Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                child: Visibility(
                  visible: viewModel.showSnackbar,
                  maintainAnimation: false,
                  child: SizedBox(
                    height: 60,
                    width: MediaQuery.of(context).size.width,
                    child: PermanentSnackBar(
                      text: "Display name not applied",
                      actionText: "Apply",
                      onPressed: () => this._applyDisplayNameChange(viewModel)
                    )
                  )
                )
              ),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: 32.0),
                    child: Text(
                      "This is you!",
                      style: TextStyle(
                        fontSize: FONTSIZE_TITLE
                      )
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
                    child: Row(
                      children: [
                        // TODO
                        AvatarWrapper(
                          radius: 35.0,
                          avatarUrl: "https://3.bp.blogspot.com/-tXOVVeovbNA/XI8EEkbKjgI/AAAAAAAAJrs/3lOV4RQx9kIp9jWBmZhSKyng9iNQrDivgCLcBGAs/s2560/hatsune-miku-4k-fx-2048x2048.jpg",
                          alt: Text("Tu"),
                          showEditButton: false,
                          onTapFunction: () {}
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TODO: Show a SnackBar if changed
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: CustomTextField(
                                  maxLines: 1,
                                  labelText: "Display name",
                                  controller: this.controller,
                                  isDense: true,
                                  onChanged: (value) {
                                    if (!viewModel.showSnackbar) {
                                      viewModel.setShowSnackbar(true); 
                                    }
                                  },
                                  cornerRadius: TEXTFIELD_RADIUS_REGULAR
                                )
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                // TODO
                                child: Text("testuser@someprovider.net")
                              )
                            ]
                          )
                        )
                      ]
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 16.0)),
                    child: Text(
                      "We have auto-generated a password for you. You should write it down somewhere safe.",
                      style: TextStyle(
                        fontSize: FONTSIZE_BODY
                      )
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 16.0)),
                    child: ExpansionTile(
                      title: Text("Show password"),
                      children: [
                        ListTile(title: Text("s3cr3t_p4ssw0rd"))
                      ]
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
                    child: ExpansionTile(
                      title: Text("Advanced settings"),
                      children: [
                        SwitchListTile(
                          title: Text("Enable link previews"),
                          value: true,
                          // TODO
                          onChanged: (value) {}
                        ),
                        SwitchListTile(
                          title: Text("Use Push Services"),
                          value: true,
                          // TODO
                          onChanged: (value) {}
                        )
                      ]
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 16.0)),
                    child: Text(
                      // TODO: Maybe rephrase
                      "You can now be contacted by your XMPP address. If you want, you can set a profile picture now.",
                      style: TextStyle(
                        fontSize: FONTSIZE_BODY
                      )
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            child: Text("Start chatting"),
                            // TODO
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, "/conversations", (route) => false)
                          )
                        )
                      ]
                    )
                  )
                ]
              )
            ]
          )
        )
      )
    );
  }
}
