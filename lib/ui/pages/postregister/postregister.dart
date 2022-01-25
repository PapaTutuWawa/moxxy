import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/snackbar.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/postregister/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";

class _PostRegistrationPageViewModel {
  final bool showSnackbar;
  final void Function(bool show) setShowSnackbar;
  final String jid;
  final String displayName;
  final String avatarUrl;
  final void Function(String avatarUrl) setAvatarUrl;

  const _PostRegistrationPageViewModel({required this.showSnackbar, required this.setShowSnackbar, required this.jid, required this.displayName, required this.avatarUrl, required this.setAvatarUrl });
}

class PostRegistrationPage extends StatefulWidget {
  const PostRegistrationPage({ Key? key }) : super(key: key);

  @override
  _PostRegistrationPageState createState() => _PostRegistrationPageState();
}

class _PostRegistrationPageState extends State<PostRegistrationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey;
  TextEditingController? _controller;

  _PostRegistrationPageState() : _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    }

    super.dispose();
  }
  
  void _applyDisplayNameChange(BuildContext context, _PostRegistrationPageViewModel viewModel) {
    // TODO
    // TODO: Maybe show a LinearProgressIndicator
    dismissSoftKeyboard(context);
    viewModel.setShowSnackbar(false);
  }

  // Wrapper so that we can set the display name on first initialization
  TextEditingController _getController(_PostRegistrationPageViewModel viewModel) {
    _controller ??= TextEditingController(text: viewModel.displayName);
    return _controller!;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        body: StoreConnector<MoxxyState, _PostRegistrationPageViewModel>(
          converter: (store) => _PostRegistrationPageViewModel(
            showSnackbar: store.state.postRegisterPageState.showSnackbar,
            setShowSnackbar: (show) => store.dispatch(PostRegisterSetShowSnackbarAction(show: show)),
            jid: store.state.accountState.jid,
            displayName: store.state.accountState.displayName,
            avatarUrl: store.state.accountState.avatarUrl,
            setAvatarUrl: (url) => store.dispatch(SetAvatarAction(avatarUrl: url))
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
                      onPressed: () => _applyDisplayNameChange(context, viewModel)
                    )
                  )
                )
              ),
              Column(
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(top: 32.0),
                    child: Text(
                      "This is you!",
                      style: TextStyle(
                        fontSize: fontsizeTitle
                      )
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
                    child: Row(
                      children: [
                        AvatarWrapper(
                          radius: 35.0,
                          avatarUrl: viewModel.avatarUrl,
                          altIcon: Icons.person,
                          showEditButton: false,
                          onTapFunction: () => pickAndSetAvatar(context, viewModel.setAvatarUrl)
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: CustomTextField(
                                  maxLines: 1,
                                  labelText: "Display name",
                                  controller: _getController(viewModel),
                                  isDense: true,
                                  onChanged: (value) {
                                    // NOTE: Since hitting the (software) back button triggers this function, "debounce" it
                                    //       by only showing the snackbar if the value differs from the state
                                    if (value == viewModel.displayName) {
                                      if (viewModel.showSnackbar) {
                                        viewModel.setShowSnackbar(false);
                                      }
                                    } else {
                                      if (!viewModel.showSnackbar) {
                                        viewModel.setShowSnackbar(true);
                                      }
                                    }
                                  },
                                  cornerRadius: textfieldRadiusRegular
                                )
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(viewModel.jid)
                              )
                            ]
                          )
                        )
                      ]
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 16.0)),
                    child: const Text(
                      "We have auto-generated a password for you. You should write it down somewhere safe.",
                      style: TextStyle(
                        fontSize: fontsizeBody
                      )
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 16.0)),
                    child: const ExpansionTile(
                      title: Text("Show password"),
                      children: [
                        ListTile(title: Text("s3cr3t_p4ssw0rd"))
                      ]
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
                    child: ExpansionTile(
                      title: const Text("Advanced settings"),
                      children: [
                        SwitchListTile(
                          title: const Text("Enable link previews"),
                          value: false,
                          // TODO
                          onChanged: (value) {}
                        ),
                        SwitchListTile(
                          title: const Text("Use Push Notification Services"),
                          value: false,
                          // TODO
                          onChanged: (value) {}
                        )
                      ]
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 16.0)),
                    child: const Text(
                      // TODO: Maybe rephrase
                      "You can now be contacted by your XMPP address. If you want, you can set a profile picture now.",
                      style: TextStyle(
                        fontSize: fontsizeBody
                      )
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            child: const Text("Start chatting"),
                            // TODO
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, conversationsRoute, (route) => false)
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
