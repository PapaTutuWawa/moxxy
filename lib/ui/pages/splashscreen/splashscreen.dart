import "package:flutter/material.dart";

class Splashscreen extends StatelessWidget {
  const Splashscreen({ Key? key }) : super(key: key);

  static Page page() {
    return MaterialPage<void>(
      child: const Splashscreen()
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/logo.png",
          width: 200, height: 200
        )
      )
    );
  }
}
