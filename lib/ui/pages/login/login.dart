import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/constants.dart';
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/login/actions.dart";

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _LoginPageViewModel {
  final void Function() togglePasswordVisibility;
  final void Function() performLogin;
  final bool doingWork;
  final bool showPassword;

  _LoginPageViewModel({ required this.togglePasswordVisibility, required this.performLogin, required this.doingWork, required this.showPassword });
}

class LoginPage extends StatelessWidget {
  void _navigateToConversations(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/conversations",
      (route) => false
    );
  }

  void _performLogin(BuildContext context, _LoginPageViewModel viewModel) {
    // TODO: Remove
    Future.delayed(Duration(seconds: 3), () => this._navigateToConversations(context));

    viewModel.performLogin();
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _LoginPageViewModel>(
      converter: (store) => _LoginPageViewModel(
        togglePasswordVisibility: () => store.dispatch(TogglePasswordVisibilityAction()),
        performLogin: () => store.dispatch(PerformLoginAction()),
        doingWork: store.state.loginPageState.doingWork,
        showPassword: store.state.loginPageState.showPassword
      ),
      builder: (context, viewModel) => Scaffold(
        appBar: BorderlessTopbar.simple(title: "Login"),
        // TODO: The TextFields look a bit too smal
        // TODO: Hide the LinearProgressIndicator if we're not doing anything
        // TODO: Disable the inputs and the BackButton if we're working on loggin in
        body: Column(
          children: [
            Visibility(
              visible: viewModel.doingWork,
              child: LinearProgressIndicator(
                value: null,
                valueColor: AlwaysStoppedAnimation<Color>(PRIMARY_COLOR)
              )
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
                  decoration: InputDecoration(
                    labelText: "XMPP-Address",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0)
                  )
                )
              )
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
                  obscureText: !viewModel.showPassword,
                  enabled: !viewModel.doingWork,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                    suffixIcon: Padding(
                      padding: EdgeInsetsDirectional.only(end: 8.0),
                      child: InkWell(
                        onTap: () => viewModel.togglePasswordVisibility(),
                        child: Icon(
                          viewModel.showPassword ? Icons.visibility : Icons.visibility_off
                        )
                      )
                    )
                  )
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 8.0)),
              child: ExpansionTile(
                title: Text("Advanced options"),
                children: [
                  Column(
                    children: [
                      SwitchListTile(
                        title: Text("Create account on server"),
                        value: false,
                        // TODO
                        onChanged: viewModel.doingWork ? null : (value) {}
                      )
                    ]
                  )
                ]
              )
            ), 
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 8.0)),
                    child: ElevatedButton(
                      child: Text("Login"),
                      onPressed: viewModel.doingWork ? null : () => this._performLogin(context, viewModel)
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
