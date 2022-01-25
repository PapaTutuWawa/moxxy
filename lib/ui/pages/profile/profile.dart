import "package:moxxyv2/ui/widgets/sharedmedia.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/snackbar.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/profile/actions.dart";
import "package:moxxyv2/ui/redux/account/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:qr_flutter/qr_flutter.dart";

// TODO: Move to separate file
class ProfilePageArguments {
  final Conversation? conversation;
  final bool isSelfProfile;

  ProfilePageArguments({ this.conversation, required this.isSelfProfile }) {
    assert(isSelfProfile ? true : conversation != null);
  }
}

class _ProfilePageViewModel {
  final bool showSnackbar;
  final void Function(bool show) setShowSnackbar;
  final void Function(String name) setDisplayName;
  final void Function(String avatarUrl) setAvatarUrl;
  final String displayName;
  final String jid;
  final String avatarUrl;

  const _ProfilePageViewModel({required this.showSnackbar, required this.setShowSnackbar, required this.displayName, required this.jid, required this.avatarUrl, required this.setDisplayName, required this.setAvatarUrl });
}

class SelfProfileHeader extends StatelessWidget {
  // This is to keep the snackbar only on this page. This also removes it once
  // we navigate away from this page.
  final _ProfilePageViewModel viewModel;
  final TextEditingController _controller;
  
  const SelfProfileHeader({ required this.viewModel, required TextEditingController controller, Key? key }) : _controller = controller, super(key: key);

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
                // TODO: Check if the URI is correct
                data: "xmpp:" + jid,
                version: QrVersions.auto,
                size: 220.0,
                backgroundColor: Colors.white,
                embeddedImage: const AssetImage("assets/images/logo.png"),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: const Size(50, 50)
                )
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
          avatarUrl: viewModel.avatarUrl,
          altIcon: Icons.person,
          showEditButton: false,
          onTapFunction: () => pickAndSetAvatar(context, viewModel.setAvatarUrl)
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 220
            ),
            child: CustomTextField(
              maxLines: 1,
              controller: _controller,
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
              labelText: "Display name",
              isDense: true,
              cornerRadius: textfieldRadiusRegular
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Row(
            children: [
              Text(
                viewModel.jid,
                style: const TextStyle(
                  fontSize: 15
                )
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 3.0),
                child: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => _showJidQRCode(context, viewModel.jid)
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

  const ProfileHeader({ required this.conversation, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AvatarWrapper(
          radius: 110.0,
          avatarUrl: conversation.avatarUrl,
          alt: Text(conversation.title[0])
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            conversation.title,
            style: const TextStyle(
              fontSize: 30
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Text(
            conversation.jid,
            style: const TextStyle(
              fontSize: 15
            )
          )
        )
      ]
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({ Key? key }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // NOTE: We need to keep the controller here because a state update would otherwise
  //       mess with the IME
  TextEditingController? _controller;

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.dispose();
    }

    super.dispose();
  }
  
  // Wrapper so that we can set the display name on first initialization
  TextEditingController _getController(_ProfilePageViewModel viewModel) {
    _controller ??= TextEditingController(text: viewModel.displayName);
    return _controller!;
  }

  
  void _applyDisplayName(BuildContext context, _ProfilePageViewModel viewModel) {
    viewModel.setDisplayName(_controller!.text);
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
            avatarUrl: store.state.accountState.avatarUrl,
            setDisplayName: (name) => store.dispatch(SetDisplayNameAction(displayName: name)),
            setAvatarUrl: (avatarUrl) => store.dispatch(SetAvatarAction(avatarUrl: avatarUrl))
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
                      onPressed: () => _applyDisplayName(context, viewModel)
                    )
                  )
                )
              ),
              Positioned(
                child: Column(
                  children: [
                    args.isSelfProfile ? SelfProfileHeader(viewModel: viewModel, controller: _getController(viewModel)) : ProfileHeader(conversation: args.conversation!),
                    Visibility(
                      visible: !args.isSelfProfile && args.conversation!.sharedMediaPaths.isEmpty,
                      child: args.isSelfProfile ? const SizedBox() : SharedMediaDisplay(
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
              const Positioned(
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
