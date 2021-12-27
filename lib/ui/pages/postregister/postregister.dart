import "dart:io";
import "package:flutter/material.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/snackbar.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/postregister/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/ui/pages/postregister/state.dart";

import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";
import "package:file_picker/file_picker.dart";
import "package:image_cropping/constant/enums.dart";
import "package:image_cropping/image_cropping.dart";
import "package:path_provider/path_provider.dart";

class _PostRegistrationPageViewModel {
  final bool showSnackbar;
  final void Function(bool show) setShowSnackbar;
  final String jid;
  final String displayName;
  final String avatarUrl;
  final void Function(String avatarUrl) setAvatarUrl;

  _PostRegistrationPageViewModel({required this.showSnackbar, required this.setShowSnackbar, required this.jid, required this.displayName, required this.avatarUrl, required this.setAvatarUrl });
}

class PostRegistrationPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController? _controller;

  void _applyDisplayNameChange(BuildContext context, _PostRegistrationPageViewModel viewModel) {
    // TODO
    // TODO: Maybe show a LinearProgressIndicator
    dismissSoftKeyboard(context);
    viewModel.setShowSnackbar(false);
  }

  // Wrapper so that we can set the display name on first initialization
  TextEditingController _getController(_PostRegistrationPageViewModel viewModel) {
    if (this._controller == null) {
      this._controller = TextEditingController(text: viewModel.displayName);
    }

    return this._controller!;
  }

  void _pickAvatar(BuildContext context, _PostRegistrationPageViewModel viewModel) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true
    );

    if (result != null) {
      // TODO: Maybe factor this out into a helper
      ImageCropping.cropImage(
        context: context,
        imageBytes: result.files.single.bytes!,
        onImageDoneListener: (data) async {
          String cacheDir = (await getTemporaryDirectory()).path;
          Directory accountDir = Directory(cacheDir + "/account");
          await accountDir.create();
          File avatar = File(accountDir.path + "/avatar.png");
          await avatar.writeAsBytes(data);

          // TODO: If the path doesn't change then the UI won't be updated. Hash it and use that as the filename?
          viewModel.setAvatarUrl(avatar.path);
        },
        selectedImageRatio: ImageRatio.RATIO_1_1
      );
      print(result.files.single.path);
    }
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
                      onPressed: () => this._applyDisplayNameChange(context, viewModel)
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
                        AvatarWrapper(
                          radius: 35.0,
                          avatarUrl: viewModel.avatarUrl,
                          altIcon: Icons.person,
                          showEditButton: false,
                          onTapFunction: () => this._pickAvatar(context, viewModel)
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.4,
                                child: CustomTextField(
                                  maxLines: 1,
                                  labelText: "Display name",
                                  controller: this._getController(viewModel),
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
                                  cornerRadius: TEXTFIELD_RADIUS_REGULAR
                                )
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Text(viewModel.jid)
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
