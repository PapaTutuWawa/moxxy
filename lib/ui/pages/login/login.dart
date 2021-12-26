import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/constants.dart';
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/login/actions.dart";

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _LoginPageViewModel {
  final void Function() togglePasswordVisibility;
  final void Function() performLogin;
  final void Function(String text) setJidError;
  final void Function(String text) setPasswordError;
  final void Function() resetErrors;
  final bool doingWork;
  final bool showPassword;
  final String? passwordError;
  final String? jidError;

  _LoginPageViewModel({ required this.togglePasswordVisibility, required this.performLogin, required this.doingWork, required this.showPassword, required this.setJidError, required this.setPasswordError, this.passwordError, this.jidError, required this.resetErrors });
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
    viewModel.resetErrors();

    /*
    if (!false) {
      viewModel.setPasswordError("Fuck you");

      return;
    }
    */
    
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
        showPassword: store.state.loginPageState.showPassword,
        passwordError: store.state.loginPageState.passwordError,
        setJidError: (text) => store.dispatch(LoginSetJidErrorAction(text: text)),
        setPasswordError: (text) => store.dispatch(LoginSetPasswordErrorAction(text: text)),
        resetErrors: () => store.dispatch(LoginResetErrorsAction())

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
              child: CustomTextField(
                errorText: viewModel.jidError,
                labelText: "XMPP-Address",
                enabled: !viewModel.doingWork,
                maxLines: 1,
                cornerRadius: TEXTFIELD_RADIUS_REGULAR
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 8.0)),
              child: CustomTextField(
                errorText: viewModel.passwordError,
                labelText: "Password",
                suffixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.0),
                  child: InkWell(
                    onTap: () => viewModel.togglePasswordVisibility(),
                    child: Icon(
                      viewModel.showPassword ? Icons.visibility : Icons.visibility_off
                    )
                  )
                ),
                enabled: !viewModel.doingWork,
                obscureText: true,
                maxLines: 1,
                cornerRadius: TEXTFIELD_RADIUS_REGULAR
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
