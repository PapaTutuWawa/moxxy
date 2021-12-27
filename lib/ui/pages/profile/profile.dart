import "package:flutter/material.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/sharedmedia.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/snackbar.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/profile/actions.dart";

import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";
import "package:qr_flutter/qr_flutter.dart";

// TODO: Move to separate file
class ProfilePageArguments {
  final Conversation? conversation;
  final bool isSelfProfile;

  ProfilePageArguments({ this.conversation, required this.isSelfProfile }) {
    assert(this.isSelfProfile ? true : this.conversation != null);
  }
}

class _ProfilePageViewModel {
  final bool showSnackbar;
  final void Function(bool show) setShowSnackbar;
  final String displayName;
  final String jid;
  final String avatarUrl;

  _ProfilePageViewModel({required this.showSnackbar, required this.setShowSnackbar, required this.displayName, required this.jid, required this.avatarUrl });
}

class SelfProfileHeader extends StatelessWidget {
  // This is to keep the snackbar only on this page. This also removes it once
  // we navigate away from this page.
  final _ProfilePageViewModel viewModel;
  // TODO
  final TextEditingController controller;
  bool _showingSnackBar = false;
  
  SelfProfileHeader({ required this.viewModel, required this.controller });

  Future<void> _showJidQRCode(BuildContext context, String jid) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: Text(jid),
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: QrImage(
                data: jid,
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white
              )
            )
          ) 
        ]
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: this.viewModel.avatarUrl,
          altIcon: Icons.person,
          showEditButton: false,
          onTapFunction: () {}
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 220
            ),
            child: CustomTextField(
              maxLines: 1,
              controller: this.controller,
              onChanged: (value) {
                if (!this.viewModel.showSnackbar) {
                  this.viewModel.setShowSnackbar(true);
                }
              },
              labelText: "Display name",
              isDense: true,
              cornerRadius: TEXTFIELD_RADIUS_REGULAR
            )
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 3.0),
          child: Row(
            children: [
              Text(
                viewModel.jid,
                style: TextStyle(
                  fontSize: 15
                )
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(start: 3.0),
                child: IconButton(
                  icon: Icon(Icons.qr_code),
                  onPressed: () => this._showJidQRCode(context, viewModel.jid)
                )
              )
            ]
          )
        )
      ]
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final Conversation conversation;

  ProfileHeader({ required this.conversation });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: this.conversation.avatarUrl,
          alt: Text(this.conversation.title[0])
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            this.conversation.title,
            style: TextStyle(
              fontSize: 30
            )
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 3.0),
          child: Text(
            this.conversation.jid,
            style: TextStyle(
              fontSize: 15
            )
          )
        )
      ]
    );
  }
}

class ProfilePage extends StatelessWidget {
  // NOTE: We need to keep the controller here because a state update would otherwise
  //       mess with the IME
  TextEditingController? _controller;

  // Wrapper so that we can set the display name on first initialization
  TextEditingController _getController(_ProfilePageViewModel viewModel) {
    if (this._controller == null) {
      this._controller = TextEditingController(text: viewModel.displayName);
    }

    return this._controller!;
  }

  
  void _applyDisplayName(BuildContext context, _ProfilePageViewModel viewModel) {
    // TODO
    dismissSoftKeyboard(context);
    viewModel.setShowSnackbar(false);
  }

  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as ProfilePageArguments;

    return SafeArea(
      child: Scaffold(
        body: StoreConnector<MoxxyState, _ProfilePageViewModel>(
          converter: (store) => _ProfilePageViewModel(
            showSnackbar: store.state.profilePageState.showSnackbar,
            setShowSnackbar: (show) => store.dispatch(ProfileSetShowSnackbarAction(show: show)),
            displayName: store.state.accountState.displayName,
            jid: store.state.accountState.jid,
            avatarUrl: store.state.accountState.avatarUrl
          ),
          builder: (context, viewModel) => Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                child: Visibility(
                  visible: viewModel.showSnackbar,
                  child: SizedBox(
                    height: 60,
                    width: MediaQuery.of(context).size.width,
                    child: PermanentSnackBar(
                      text: "Display name not applied",
                      actionText: "Apply",
                      onPressed: () => this._applyDisplayName(context, viewModel)
                    )
                  )
                )
              ),
              Positioned(
                child: Column(
                  children: [
                    args.isSelfProfile ? SelfProfileHeader(viewModel: viewModel, controller: this._getController(viewModel)) : ProfileHeader(conversation: args.conversation!),
                    Visibility(
                      visible: !args.isSelfProfile && args.conversation!.sharedMediaPaths.length > 0,
                      child: args.isSelfProfile ? SizedBox() : SharedMediaDisplay(
                        sharedMediaPaths: args.conversation!.sharedMediaPaths
                      )
                    ) 
                  ]
                ),
                top: 8.0,
                bottom: null,
                left: null,
                right: null
              ),
              Positioned(
                top: 8.0,
                left: 8.0,
                child: BackButton()
              )
            ]
          )
        )
      )
    );
  }
}
