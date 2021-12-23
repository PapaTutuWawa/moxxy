import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/constants.dart';

class _LoginPageState extends State<LoginPage> {
  bool _doingWork = false;
  bool _showPassword = false;

  void _navigateToConversations(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/conversations",
      (route) => false
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
        this._showPassword = !this._showPassword;
    });
  }
  
  void _performLogin(BuildContext context) {
    // TODO: Stub
    setState(() {
        this._doingWork = true;
    });

    Future.delayed(Duration(seconds: 3), () => this._navigateToConversations(context));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton(),
            Text(
              "Login",
              style: TextStyle(
                fontSize: 19
              )
            )
          ]
        )
      ),
      // TODO: The TextFields look a bit too smal
      // TODO: Hide the LinearProgressIndicator if we're not doing anything
      // TODO: Disable the inputs and the BackButton if we're working on loggin in
      body: Column(
        children: [
          Visibility(
            visible: this._doingWork,
            child: LinearProgressIndicator(value: null)
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
                enabled: !this._doingWork,
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
                obscureText: this._showPassword,
                enabled: !this._doingWork,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                  suffixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.0),
                    // TODO: Switch this icon depending on the state
                    child: InkWell(
                      onTap: () => this._togglePasswordVisibility(),
                      child: Icon(
                        this._showPassword ? Icons.visibility : Icons.visibility_off
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
                      onChanged: this._doingWork ? null : (value) {}
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
                    onPressed: this._doingWork ? null : () => this._performLogin(context)
                  )
                )
              )
            ]
          )
        ]
      )
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({ Key? key }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}
