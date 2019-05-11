import 'package:flutter/material.dart';
import 'package:gg/Components/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBox extends StatefulWidget {
  _UserBox createState() => new _UserBox();

  final Map<dynamic, dynamic> user;
  final String userBoxType;
  final String currentUser;
  final String tournamentID;

  UserBox({Key key, @required this.user, this.userBoxType, @required this.currentUser, this.tournamentID}) : super(key: key);
}

class _UserBox extends State<UserBox> {
  Map<dynamic, dynamic> user;
  String _currentUser;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  _currentUser = widget.currentUser;
  }

  _handleKick(String userID, String tournamentID, String kickType) async {
    print(tournamentID);
    try {
      if (kickType == "Players") {
      await Firestore.instance.document("Tournaments/$tournamentID").get().then((tournamentInfo) {
        if (tournamentInfo.exists) {
          List tournamentPlayers = List.from(tournamentInfo.data["tournamentPlayers"]);
          print(tournamentPlayers);
          if (tournamentPlayers.contains(userID)) {
            tournamentPlayers.remove(userID);
            Firestore.instance.document("Tournaments/$tournamentID").updateData({
              "tournamentPlayers": tournamentPlayers,
            });
              Navigator.of(context).pop(); 
          }
        }
      });
      } else {
        await Firestore.instance.document("Tournaments/$tournamentID").get().then((tournamentInfo) {
        if (tournamentInfo.exists) {
          List tournamentAdmins = List.from(tournamentInfo.data["tournamentAdmins"]);
          print(tournamentAdmins);
          if (tournamentAdmins.contains(userID)) {
            tournamentAdmins.remove(userID);
            Firestore.instance.document("Tournaments/$tournamentID").updateData({
              "tournamentAdmins": tournamentAdmins,
            });
              Navigator.of(context).pop(); 
          }
        }
      });
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  _showMessageBox(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new Center(
            child: new Material(
              type: MaterialType.transparency,
              child: new Container(
                height: 150.0,
                margin: EdgeInsets.symmetric(horizontal: 40.0),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  border: Border.all(
                    width: 1.0,
                    color: Color.fromRGBO(0, 150, 255, 1.0),
                  ),
                ),
                child: new Column(
                  children: <Widget>[
                    new Container(
                      height: 50.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1.0,
                            color: Color.fromRGBO(40, 40, 40, 1.0),
                          ),
                        ),
                      ),
                      child: new Text(
                        "Kick ${user["userUsername"]}?",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    new Expanded(
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new GestureDetector(
                              child: new Container(
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Text(
                                      "YES",
                                      style: TextStyle(
                                        color:
                                            Color.fromRGBO(170, 170, 170, 1.0),
                                        fontSize: 20.0,
                                        fontFamily: "Century Gothic",
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                _handleKick(user["userID"], widget.tournamentID, widget.userBoxType);
                              },
                            ),
                          ),
                          new Container(
                            width: 1.0,
                            color: Color.fromRGBO(40, 40, 40, 1.0),
                          ),
                          new Expanded(
                            child: new Row(
                              children: <Widget>[
                                new Expanded(
                                  child: new GestureDetector(
                                    child: new Container(
                                      color: Colors.transparent,
                                      alignment: Alignment.center,
                                      child: new Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          new Text(
                                            "NO",
                                            style: TextStyle(
                                              color: Color.fromRGBO(
                                                  170, 170, 170, 1.0),
                                              fontSize: 20.0,
                                              fontFamily: "Century Gothic",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    },
                                  ),
                                ),
                              ],
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
        });
  }

  Widget build(BuildContext context) {
    user = widget.user;
    return new GestureDetector(
      child: new Container(
        height: 60.0,
        margin: EdgeInsets.only(top: 10.0),
        decoration: BoxDecoration(
          color: Color.fromRGBO(23, 23, 23, 1.0),
          boxShadow: [
            BoxShadow(
              blurRadius: 4.0,
              color: Colors.black,
              offset: Offset(0.0, 4.0),
            ),
          ],
          borderRadius: BorderRadius.all(Radius.circular(20.0)),
          border: Border.all(
            width: 1.0,
            color: Color.fromRGBO(40, 40, 40, 1.0),
          ),
        ),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(left: 2.0, top: 4.0),
              child: new CircleAvatar(
                backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                radius: 25.0,
                child: new CircleAvatar(
                    backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                    radius: 23.0,
                    backgroundImage: CachedNetworkImageProvider(
                      user["userPicture"].toString(),
                    )),
              ),
            ),
            new Expanded(
              child: new Container(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Expanded(
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Container(
                              margin: EdgeInsets.only(left: 5.0, top: 5.0),
                              child: new Text(
                                user["userUsername"],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    new Container(
                      margin: EdgeInsets.only(left: 5.0, bottom: 10.0),
                      child: new Text(
                        "${user["userFirstName"]} ${user["userLastName"]}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 14.0,
                          fontFamily: "Avenir",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            user["userID"] != _currentUser && (widget.userBoxType == "Players" || widget.userBoxType == "Admins") ? new Container(
              padding: EdgeInsets.only(right: 10.0),
              alignment: Alignment.center,
              child: new GestureDetector(
                child: new Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 2.0),
                  child: new Text(
                    "KICK",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 15.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () {
                  _showMessageBox(context);
                },
              ),
            ) : new Container(),
          ],
        ),
      ),
      onTap: widget.userBoxType != "Conversation"
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new ProfilePage(
                        userID: user["userID"],
                        visitor: true,
                      ),
                ),
              );
            }
          : null,
    );
  }
}
