import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/login.dart';
import 'package:moxxyv2/ui/constants.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const Login(),
        settings: const RouteSettings(
          name: loginRoute,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (BuildContext context, LoginState state) => PopScope(
        canPop: !state.working,
        child: Scaffold(
          appBar: AppBar(
            title: Text(t.pages.login.title),
          ),
          body: Column(
            children: [
              Visibility(
                visible: state.working,
                child: const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: TextField(
                  enabled: !state.working,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.pages.login.xmppAddress,
                    errorText: state.jidState.error,
                  ),
                  onChanged: context.read<LoginCubit>().onJidChanged,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: TextField(
                  enabled: !state.working,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: t.pages.login.password,
                    errorText: state.passwordState.error,
                    suffixIcon: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: InkWell(
                        onTap: () => context
                            .read<LoginCubit>()
                            .onPasswordVisibilityToggled(),
                        child: Icon(
                          state.passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  ),
                  obscureText: !state.passwordVisible,
                  onChanged: context.read<LoginCubit>().onPasswordChanged,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: ExpansionTile(
                  title: Text(t.pages.login.advancedOptions),
                  children: [
                    Column(
                      children: [
                        SwitchListTile(
                          title: Text(t.pages.login.createAccount),
                          value: false,
                          // TODO(Unknown): Implement
                          onChanged: state.working ? null : (value) {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: state.working
                            ? null
                            : context.read<LoginCubit>().submit,
                        child: Text(
                          t.pages.login.login,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
