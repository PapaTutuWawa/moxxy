import 'package:flutter/material.dart';
import 'ui/widgets/topbar.dart';
import 'ui/widgets/chatbubble.dart';
import 'ui/widgets/sharedimage.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moxxy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark
      ),
      themeMode: ThemeMode.system,
      routes: {
        "/intro": (context) => IntroPage(),
        "/login": (context) => LoginPage(),
        "/register": (context) => RegistrationPage(),
        "/conversations": (context) => ContactListPage(),
        "/conversation": (context) => ConversationPage(),
        "/conversation/profile": (context) => ProfilePage(),
        "/new_conversation": (context) => NewConversationPage(),
        "/new_conversation/add_contact": (context) => AddContactPage(),
      },
      home: IntroPage(),
    );
  }
}

/*
class Contact {
  String name;

  const Contact(this.name);
}
*/
class ContactsListRow extends StatelessWidget {
  //Contact[] contacts = [ new User("Hallo") ];
  String avatarUrl;
  String name;

  ContactsListRow(this.avatarUrl, this.name);

  Widget _buildAvatar() {
    if (this.avatarUrl != "") {
      return CircleAvatar(
        backgroundImage: NetworkImage(this.avatarUrl),
        radius: 35.0
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.grey,
        child: Text(this.name[0]),
        radius: 35.0
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, "/conversation");
      },
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: this._buildAvatar()
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  this.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text("Did you really just call me \"Maru Maru\"?")
              ]
            )
          )
        ]
      )
    );
  }
}

class ContactListPage extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 3.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse3.mm.bing.net%2Fth%3Fid%3DOIP.MkXhyVPrn9eQGC1CTOyTYAHaHa%26pid%3DApi&f=1"),
                radius: 20.0
              )
            ),
            Text(
              "Ojou",
              style: TextStyle(
                fontSize: 18
              )
            )
          ]
        )
      ),
      body: ListView(
        children: <Widget>[
          ContactsListRow("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fyt3.ggpht.com%2Fa%2FAGF-l78YnmyE3snkHMp_18AZOP5QRH2WOYSBlnPKFA%3Ds900-c-k-c0xffffffff-no-rj-mo&f=1&nofb=1", "Ars Almal"),
          ContactsListRow("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse4.mm.bing.net%2Fth%3Fid%3DOIP.N1bqs6sYnkcHO9cp4VY56ACwCw%26pid%3DApi&f=1", "Millie Parfait"),
          ContactsListRow("", "Normal dude"),
        ]
      ),
      // TODO: Maybe don't use a SpeedDial
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        visible: true,
        curve: Curves.bounceInOut,
        children: [
          SpeedDialChild(
            child: Icon(Icons.person_add),
            onTap: () => Navigator.pushNamed(context, "/new_conversation"),
            label: "Add contact"
          ),
          SpeedDialChild(
            child: Icon(Icons.group_add),
            onTap: () => print("OK"),
            label: "Create groupchat"
          ),
          SpeedDialChild(
            child: Icon(Icons.group),
            onTap: () => print("OK"),
            label: "Join groupchat"
          )
        ]
      ),
    );
  }
}

class _ConversationPageState extends State<ConversationPage> {
  bool _showSendButton = false;
  TextEditingController controller = TextEditingController();

  _ConversationPageState();
  
  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }


  void _onMessageTextChanged(String value) {
    setState(() {
        this._showSendButton = value != "";
    });
  }

  void _onSendButtonPressed() {
    if (this._showSendButton) {
      // TODO: Actual sending
      this.controller.clear();
      // NOTE: Calling clear on the controller does not trigger a onChanged on the
      //       TextField
      this._onMessageTextChanged("");
    } else {
      // TODO: This
      print("Adding file");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back)
              )
            ),
            Center(
              child: InkWell(
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 16.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse3.mm.bing.net%2Fth%3Fid%3DOIP.MkXhyVPrn9eQGC1CTOyTYAHaHa%26pid%3DApi&f=1"),
                        radius: 25.0
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 2.0),
                      child: Text(
                        "Ojou",
                        style: TextStyle(
                          fontSize: 20
                        )
                      )
                    )
                  ]
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/conversation/profile");
                }
              )
            ),
            Spacer(),
            Center(
              child: InkWell(
                // TODO: Implement
                onTap: () {},
                // TODO: Find a better icon
                child: Icon(Icons.menu)
              )
            )
          ]
        )
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ChatBubble(
                  messageContent: "Hello",
                  sentBySelf: true
                ),
                ChatBubble(
                  messageContent: "Hello right back",
                  sentBySelf: false
                ),
                ChatBubble(
                  messageContent: "What a nice person you are!",
                  sentBySelf: true
                )
              ]
            )
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 1,
                        color: Colors.purple
                      )
                    ),
                    // TODO: Fix the TextField being too tall
                    child: TextField(
                      maxLines: 5,
                      minLines: 1,
                      controller: this.controller,
                      onChanged: this._onMessageTextChanged,
                      decoration: InputDecoration(
                        hintText: "Send a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(5)
                      )
                    )
                  )
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  // NOTE: https://stackoverflow.com/a/52786741
                  //       Thank you kind sir
                  child: Container(
                    height: 45.0,
                    width: 45.0,
                    child: FittedBox(
                      child: FloatingActionButton(
                        child: Icon(
                          this._showSendButton ? Icons.send : Icons.add
                        ),
                        onPressed: this._onSendButtonPressed
                      )
                    )
                  )
                ) 
              ]
            )
          )
        ]
      )
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({ Key? key }) : super(key: key);

  @override
  _ConversationPageState createState() => _ConversationPageState();
  
}

class ProfilePage extends StatelessWidget {
  ProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse3.mm.bing.net%2Fth%3Fid%3DOIP.MkXhyVPrn9eQGC1CTOyTYAHaHa%26pid%3DApi&f=1"),
                    radius: 110.0
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Nakiri Ayame",
                      style: TextStyle(
                        fontSize: 30
                      )
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 3.0),
                    child: Text(
                      "nakiri.ayame@hololive.tv",
                      style: TextStyle(
                        fontSize: 15)
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 25.0),
                    child: Text(
                      "Shared Media",
                      style: TextStyle(
                        fontSize: 25
                      )
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          SharedImage(
                            image: NetworkImage(
                              "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fi.redd.it%2Fv2ybdgx5cow61.jpg&f=1&nofb=1"
                            )
                          ),
                          SharedImage(
                            image: NetworkImage(
                              "https://ih1.redbubble.net/image.1660387906.9194/bg,f8f8f8-flat,750x,075,f-pad,750x1000,f8f8f8.jpg"
                            )
                          ),
                          SharedImage(
                            image: NetworkImage(
                              "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fcdn.donmai.us%2Fsample%2Fb6%2Fe6%2Fsample-b6e62e3edc1c6dfe6afdb54614b4a710.jpg&f=1&nofb=1"
                            )
                          ),
                          SharedImage(
                            image: NetworkImage(
                              "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2F64.media.tumblr.com%2Fec84dc5628ca3d8405374b85a51c7328%2Fbb0fc871a5029726-04%2Fs1280x1920%2Ffa6d89e8a2c2f3ce17465d328c2fe0ed6c951f01.jpg&f=1&nofb=1"
                            )
                          ),
                        ]
                      )
                    )
                  )
                ]
              ),
              top: 8.0,
              bottom: null,
              left: null,
              right: null
            ),
            Positioned(
              top: 8.0,
              left: 8.0,
              child: BackButton()
            )
          ]
        )
      )
    );
  }
}

class NewConversationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton(),
            Text(
              "Start new chat",
              style: TextStyle(
                fontSize: 17
              )
            )
          ]
        )
      ),
      body: ListView(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamed(context, "/new_conversation/add_contact"),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    child: Icon(Icons.person_add),
                    radius: 35.0
                  )
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Add contact",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold
                    )
                  )
                )
              ]
            )
          ),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  child: Icon(Icons.group_add),
                  radius: 35.0
                )
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Create groupchat",
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold
                  )
                )
              )
            ]
          ),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage("https://vignette.wikia.nocookie.net/virtualyoutuber/images/4/4e/Houshou_Marine_-_Portrait.png/revision/latest?cb=20190821035347"),
                  radius: 35.0
                )
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Houshou Marine",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    Text("houshou.marine@hololive.tv")
                  ]
                )
              )
            ]
          )
        ]
      )
    );
  }
}

class LoginPage extends StatelessWidget {
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
          LinearProgressIndicator(value: null),
          Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
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
                decoration: InputDecoration(
                  labelText: "XMPP-Address",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0)
                )
              )
            )
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
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
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                  suffixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 8.0),
                    // TODO: Switch this icon depending on the state
                    child: Icon(Icons.visibility /*visibility_off*/)
                  )
                )
              )
            )
          ),

          ExpansionTile(
            title: Text("Advanced options"),
            children: [
              Column(
                children: [
                  SwitchListTile(
                    title: Text("Create account on server"),
                    value: false,
                    onChanged: (value) {}
                  )
                ]
              )
            ]
          ), 
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text("Login"),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/conversations",
                      (route) => false
                    )
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

class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton(),
            Text(
              "Register",
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
          LinearProgressIndicator(value: null),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("XMPP is a lot like e-mail: You can send e-mails to people who are not using your specific e-mail provider. As such, there are a lot of XMPP providers. To help you, we chose a random one from a curated list. You only have to pick a username.")
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
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
                decoration: InputDecoration(
                  labelText: "Username",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                  suffixText: "@polynom.me",
                  suffixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.0),
                    child: Icon(Icons.refresh)
                  )
                )
              )
            )
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text("Register"),
                    onPressed: () {}
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

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: 32.0),
            child: Text("moxxy")
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "An experiment into building a modern easy-to-use XMPP client",
              style: TextStyle(
                fontSize: 20
              )
            )
          ),
          ElevatedButton(
            child: Text("Login"),
            onPressed: () => Navigator.pushNamed(context, "/login")
          ),
          ElevatedButton(
            child: Text("Register"),
            onPressed: () => Navigator.pushNamed(context, "/register")
          )
        ]
      )
    );
  }
}

class AddContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton(),
            Text(
              "Add new contact",
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
          LinearProgressIndicator(value: null),

          Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
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
                decoration: InputDecoration(
                  labelText: "XMPP-Address",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                  suffixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.0),
                    child: Icon(Icons.qr_code)
                  )
                )
              )
            )
          ),

          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("You can add a contact either by typing in their XMPP address or by scanning their QR code")
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text("Add to contacts"),
                    // TODO: Add to roster and open a chat
                    onPressed: () {}
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
