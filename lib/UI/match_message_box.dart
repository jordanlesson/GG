import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchMessageBox extends StatefulWidget {
  _MatchMessageBox createState() => new _MatchMessageBox();

  final Map<dynamic, dynamic> matchMessage;

  MatchMessageBox({Key key, @required this.matchMessage}) : super(key: key);
}

class _MatchMessageBox extends State<MatchMessageBox> {
  Map<dynamic, dynamic> matchMessage;

  void initState() {
    super.initState();
    matchMessage = Map.from(widget.matchMessage);
  }

  Widget build(BuildContext context) {
    matchMessage = Map.from(widget.matchMessage);
    return new Container(
      padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
      decoration: BoxDecoration(
        color: Color.fromRGBO(15, 15, 15, 1.0),
        border: Border(
          top: BorderSide(
            width: 1.0,
            color: Color.fromRGBO(40, 40, 40, 1.0),
          ),
        ),
      ),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: EdgeInsets.only(top: 5.0),
            child: new StreamBuilder(
              stream: Firestore.instance
                  .document("Users/${matchMessage["messageUserID"]}")
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                if (!userSnapshot.hasData) {
                  return new CircleAvatar(
                    backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                    radius: 22.0,
                    child: new CircleAvatar(
                      backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                      radius: 20.0,
                    ),
                  );
                } else {
                  return new CircleAvatar(
                    backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                    radius: 22.0,
                    child: new CircleAvatar(
                      backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                      radius: 20.0,
                      backgroundImage:
                          NetworkImage(userSnapshot.data.data["userPicture"]),
                    ),
                  );
                }
              },
            ),
          ),
          new Expanded(
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Container(
                    alignment: Alignment.topLeft,
                    margin: EdgeInsets.only(left: 5.0, top: 3.0),
                    child: new StreamBuilder(
                      stream: Firestore.instance
                          .document("Users/${matchMessage["messageUserID"]}")
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> userSnaphot) {
                        if (!userSnaphot.hasData) {
                          return new Container(
                            height: 10.0,
                            width: 50.0,
                            color: Color.fromRGBO(50, 50, 50, 1.0),
                          );
                        } else {
                          return new Text(
                            userSnaphot.data.data["userUsername"],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontFamily: "Century Gothic",
                                fontWeight: FontWeight.bold),
                          );
                        }
                      },
                    )),
                new Container(
                  margin: EdgeInsets.only(left: 10.0),
                  child: new Text(
                    matchMessage["messageBody"],
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 14.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
