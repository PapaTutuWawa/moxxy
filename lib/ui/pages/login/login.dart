import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/button.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/login/actions.dart";
import "package:moxxyv2/shared/helpers.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";

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

  const _LoginPageViewModel({ required this.togglePasswordVisibility, required this.performLogin, required this.doingWork, required this.showPassword, required this.setJidError, required this.setPasswordError, this.passwordError, this.jidError, required this.resetErrors, this.loginError });
}

class LoginPage extends StatelessWidget {
  final TextEditingController _jidController;
  final TextEditingController _passwordController;

  LoginPage({ Key? key }) : _jidController = TextEditingController(), _passwordController = TextEditingController(), super(key: key);
  
  void _performLogin(BuildContext context, _LoginPageViewModel viewModel) {
    if (viewModel.doingWork) return;

    viewModel.resetErrors();

    String jid = _jidController.text;
    String password = _passwordController.text;
    
    // Validate first
    switch (validateJid(jid)) {
      case JidFormatError.empty:
        viewModel.setJidError("XMPP-Address cannot be empty");
        return;
      case JidFormatError.noSeparator:
      case JidFormatError.tooManySeparators:
        viewModel.setJidError("XMPP-Address must contain exactly one @");
        return;
      case JidFormatError.noDomain:
        // TODO: Find a better text
        viewModel.setJidError("A domain must follow the @");
        return;
      case JidFormatError.noLocalpart:
        viewModel.setJidError("Your username must preceed the @");
        return;
      case JidFormatError.none: break;
    }

    if (password.isEmpty) {
      viewModel.setPasswordError("Password cannot be empty");
      return;
    }
    
    viewModel.performLogin(jid, password);
  }
  
  @override Widget build(BuildContext context) {
    return StoreConnector<MoxxyState, _LoginPageViewModel>(
      converter: (store) => _LoginPageViewModel(
        togglePasswordVisibility: () => store.dispatch(TogglePasswordVisibilityAction()),
        performLogin: (jid, password) => store.dispatch(PerformLoginAction(jid: jid, password: password)),
        doingWork: store.state.globalState.doingWork,
        showPassword: store.state.loginPageState.showPassword,
        passwordError: store.state.loginPageState.passwordError,
        jidError: store.state.loginPageState.jidError,
        loginError: store.state.loginPageState.loginError,
        setJidError: (text) => store.dispatch(LoginSetErrorAction(jidError: text)),
        setPasswordError: (text) => store.dispatch(LoginSetErrorAction(passwordError: text)),
        resetErrors: () => store.dispatch(LoginSetErrorAction())
      ),
      builder: (context, viewModel) => WillPopScope(
        onWillPop: () async => !viewModel.doingWork,
        child: Scaffold(
          appBar: BorderlessTopbar.simple(title: "Login"),
          body: Column(
            children: [
              Visibility(
                visible: viewModel.doingWork,
                child: const LinearProgressIndicator(
                  value: null,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor)
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8.0)),
                child: CustomTextField(
                  errorText: viewModel.jidError,
                  labelText: "XMPP-Address",
                  enabled: !viewModel.doingWork,
                  controller: _jidController,
                  maxLines: 1,
                  cornerRadius: textfieldRadiusRegular,
                  enableIMEFeatures: false
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8.0)),
                child: CustomTextField(
                  errorText: viewModel.passwordError,
                  labelText: "Password",
                  controller: _passwordController,
                  suffixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8.0),
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
                  cornerRadius: textfieldRadiusRegular,
                  enableIMEFeatures: false
                )
              ),
              Visibility(
                visible: viewModel.loginError != null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 3.0)),
                  child: Text(
                    viewModel.loginError ?? "",
                    style: const TextStyle(
                      color: Colors.red
                    )
                  )
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8.0)),
                child: ExpansionTile(
                  title: const Text("Advanced options"),
                  children: [
                    Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Create account on server"),
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
                    child: RoundedButton(
                      color: Colors.purple,
                      cornerRadius: 32.0,
                      child: const Text("Login"),
                      onTap: () => _performLogin(context, viewModel)
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
