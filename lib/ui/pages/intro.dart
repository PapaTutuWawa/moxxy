import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/button.dart";
import "package:moxxyv2/ui/bloc/navigation_bloc.dart";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class Intro extends StatelessWidget {
  const Intro({ Key? key }) : super(key: key);

  static Page page() {
    return MaterialPage<void>(child: const Intro());
  }
  
  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<NavigationBloc, NavigationState>(
          builder: (context, state) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 200, height: 200
                )
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  "moxxy",
                  style: TextStyle(
                    fontSize: fontsizeTitle
                  )
                )
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingVeryLarge),
                child: Text(
                  "An experiment into building a modern, easy and beautiful XMPP client.",
                  style: TextStyle(
                    fontSize: fontsizeBody
                  )
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(top: 8.0)),
                child: Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        color: Colors.purple,
                        child: const Text("Login"),
                        cornerRadius: 32.0,
                        onTap: () => context.read<NavigationBloc>().add(
                          NavigatedToEvent(
                            NavigationStatus.login
                          )
                        )
                      )
                    )
                  ]
                )
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingVeryLarge),
                child: Text(
                  "Have no XMPP account? No worries, creating one is really easy.",
                  style: TextStyle(
                    fontSize: fontsizeBody
                  )
                )
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge).add(const EdgeInsets.only(bottom: paddingVeryLarge)),
                      child: TextButton(
                        child: const Text("Register"),
                        onPressed: () {
                          // Navigator.pushNamed(context, registrationRoute);
                          showNotImplementedDialog("registration", context);
                        }
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
