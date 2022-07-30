import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/ui/bloc/login_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/button.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class Login extends StatelessWidget {
  const Login({ Key? key }) : super(key: key);
 
  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(builder: (_) => const Login());
  
  @override Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (BuildContext context, LoginState state) => WillPopScope(
        onWillPop: () async => !state.working,
        child: Scaffold(
          appBar: BorderlessTopbar.simple('Login'),
          body: Column(
            children: [
              Visibility(
                visible: state.working,
                child: const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8)),
                child: CustomTextField(
                  // ignore: avoid_dynamic_calls
                  errorText: state.jidState.error,
                  labelText: 'XMPP-Address',
                  enabled: !state.working,
                  cornerRadius: textfieldRadiusRegular,
                  borderColor: primaryColor,
                  borderWidth: 1,
                  enableIMEFeatures: false,
                  onChanged: (value) => context.read<LoginBloc>().add(LoginJidChangedEvent(value)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8)),
                child: CustomTextField(
                  // ignore: avoid_dynamic_calls
                  errorText: state.passwordState.error,
                  labelText: 'Password',
                  suffixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: InkWell(
                      onTap: () => context.read<LoginBloc>().add(LoginPasswordVisibilityToggledEvent()),
                      child: Icon(
                        state.passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  enabled: !state.working,
                  obscureText: !state.passwordVisible,
                  cornerRadius: textfieldRadiusRegular,
                  borderColor: primaryColor,
                  borderWidth: 1,
                  enableIMEFeatures: false,
                  onChanged: (value) => context.read<LoginBloc>().add(LoginPasswordChangedEvent(value)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8)),
                child: ExpansionTile(
                  title: const Text('Advanced options'),
                  children: [
                    Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Create account on server'),
                          value: false,
                          // TODO(Unknown): Implement
                          onChanged: state.working ? null : (value) {},
                        )
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8)),
                child: Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        color: Colors.purple,
                        cornerRadius: 32,
                        onTap: state.working ? null : () => context.read<LoginBloc>().add(LoginSubmittedEvent()),
                        child: const Text('Login'),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
