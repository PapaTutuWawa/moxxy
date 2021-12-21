import 'package:flutter/material.dart';

class ConversationsListRow extends StatelessWidget {
  String avatarUrl;
  String name;

  ConversationsListRow(this.avatarUrl, this.name);

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
