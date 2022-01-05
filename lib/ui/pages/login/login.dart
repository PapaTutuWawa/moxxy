import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/constants.dart';
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/helpers.dart";

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _LoginPageViewModel {
  final void Function() togglePasswordVisibility;
  final void Function(String jid, String password) performLogin;
  final void Function(String text) setJidError;
  final void Function(String text) setPasswordError;
  final void Function() resetErrors;
  final bool doingWork;
  final bool showPassword;
  final String? passwordError;
  final String? jidError;
  final String? loginError;

  _LoginPageViewModel({ required this.togglePasswordVisibility, required this.performLogin, required this.doingWork, required this.showPassword, required this.setJidError, required this.setPasswordError, this.passwordError, this.jidError, required this.resetErrors, this.loginError });
}

class LoginPage extends StatelessWidget {
  final TextEditingController jidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _performLogin(BuildContext context, _LoginPageViewModel viewModel) {
    viewModel.resetErrors();

    String jid = this.jidController.text;
    String password = this.passwordController.text;
    
    // Validate first
    switch (validateJid(jid)) {
      case JidFormatError.EMPTY: {
        viewModel.setJidError("XMPP-Address cannot be empty");
        return;
      }
      break;
      case JidFormatError.NO_SEPARATOR:
      case JidFormatError.TOO_MANY_SEPARATORS: {
        viewModel.setJidError("XMPP-Address must contain exactly one @");
        return;
      }
      break;
      case JidFormatError.NO_DOMAIN: {
        // TODO: Find a better text
        viewModel.setJidError("A domain must follow the @");
        return;
      }
      break;
      case JidFormatError.NO_LOCALPART: {
        viewModel.setJidError("Your username must preceed the @");
        return;
      }
      case JidFormatError.NONE: break;
    }

    if (password.isEmpty) {
      viewModel.setPasswordError("Password cannot be empty");
      return;
    }
    
    viewModel.performLogin(jid, password);
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _LoginPageViewModel>(
      converter: (store) => _LoginPageViewModel(
        togglePasswordVisibility: () => store.dispatch(TogglePasswordVisibilityAction()),
        performLogin: (jid, password) => store.dispatch(PerformLoginAction(jid: jid, password: password)),
        doingWork: store.state.globalState.doingWork,
        showPassword: store.state.loginPageState.showPassword,
        passwordError: store.state.loginPageState.passwordError,
        jidError: store.state.loginPageState.jidError,
        loginError: store.state.loginPageState.loginError,
        setJidError: (text) => store.dispatch(LoginSetJidErrorAction(text: text)),
        setPasswordError: (text) => store.dispatch(LoginSetPasswordErrorAction(text: text)),
        resetErrors: () => store.dispatch(LoginResetErrorsAction())
      ),
      builder: (context, viewModel) => WillPopScope(
        onWillPop: () async => !viewModel.doingWork,
        child: Scaffold(
          appBar: BorderlessTopbar.simple(title: "Login"),
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
                  controller: this.jidController,
                  maxLines: 1,
                  cornerRadius: TEXTFIELD_RADIUS_REGULAR
                )
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 8.0)),
                child: CustomTextField(
                  errorText: viewModel.passwordError,
                  labelText: "Password",
                  controller: this.passwordController,
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
                  obscureText: !viewModel.showPassword,
                  maxLines: 1,
                  cornerRadius: TEXTFIELD_RADIUS_REGULAR
                )
              ),
              Visibility(
                visible: viewModel.loginError != null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(top: 3.0)),
                  child: Text(
                    viewModel.loginError ?? "",
                    style: TextStyle(
                      color: Colors.red
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
      )
    );
  }
}
