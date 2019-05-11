import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gg/Components/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:gg/UI/user_box.dart';

class UserListPage extends StatefulWidget {
  _UserListPage createState() => new _UserListPage();

  final String title;
  final String id;
  final tournamentPlayers;
  final tournamentAdmins;
  final String currentUser;

  UserListPage(
      {Key key,
      @required this.title,
      @required this.id,
      this.tournamentPlayers,
      this.tournamentAdmins,
      @required this.currentUser})
      : super(key: key);
}

class _UserListPage extends State<UserListPage> {
  List<Map<String, dynamic>> users;
  List<Map<String, dynamic>> players;
  List<Map<String, dynamic>> admins;
  String title;
  bool usersLoaded;
  List<dynamic> userData;
  int _currentIndex;
  String userBoxType;

  @override
  void initState() {
    super.initState();
    users = [];
    players = [];
    admins = [];
    usersLoaded = false;
    _currentIndex = 0;
    title = widget.title;
    if (title == "Players" || title == "Admins") {
      userBoxType = "Tournament";
    } else {
      userBoxType = "";
    }
    fetchUsers(widget.id);
  }

  fetchUsers(String id) async {
    if (widget.title == "Followers") {
      Firestore.instance.document("Users/$id").get().then((userInfo) {
        if (userInfo.exists) {
        for (String followerID in userInfo.data["userFollowers"]) {
          Firestore.instance.document("Users/$followerID").get().then((followerInfo) {
            if (followerInfo.exists) {
              users.add({
                "userID": followerID,
                "userPicture": followerInfo.data["userPicture"],
                "userUsername": followerInfo.data["userUsername"],
                "userFirstName": followerInfo.data["userFirstName"],
                "userLastName": followerInfo.data["userLastName"],
              });
              if (users.length == userInfo.data["userFollowers"].length) {
                setState(() {
                    usersLoaded = true;
                  });
              }
            } else {
                  setState(() {
                    usersLoaded = true;
                  });
                }
          },);
        }
      }
      });
        
    } else if (widget.title == "Following") {
      Firestore.instance.collection("Users").where("userFollowers", arrayContains: id).getDocuments().then((followingDocuments) {
        if (followingDocuments.documents.isNotEmpty) {
          for (DocumentSnapshot followingInfo in followingDocuments.documents) {
            users.add({
              "userID": followingInfo.documentID,
                "userPicture": followingInfo.data["userPicture"],
                "userUsername": followingInfo.data["userUsername"],
                "userFirstName": followingInfo.data["userFirstName"],
                "userLastName": followingInfo.data["userLastName"],
            });
          }
          if (users.length == followingDocuments.documents.length) {
                setState(() {
                    usersLoaded = true;
                  });
              }
        } else {
                  setState(() {
                    usersLoaded = true;
                  });
                }
      },);
    } else {
      List<dynamic> tournamentPlayers = widget.tournamentPlayers;
      List<dynamic> tournamentAdmins = widget.tournamentAdmins;
      if (tournamentPlayers.isNotEmpty) {
        for (String player in tournamentPlayers) {
          Firestore.instance.document("Users/$player").get().then((playerInfo) {
            if (playerInfo.exists) {
              players.add({
                "userID": player,
                "userPicture": playerInfo.data["userPicture"],
                "userUsername": playerInfo.data["userUsername"],
                "userFirstName": playerInfo.data["userFirstName"],
                "userLastName": playerInfo.data["userLastName"]
              });
              users = players;
              if (players.length == tournamentPlayers.length) {
                if (tournamentAdmins.isNotEmpty) {
                  for (String admin in tournamentAdmins) {
                    Firestore.instance.document("Users/$admin").get().then(
                      (adminInfo) {
                        if (adminInfo.exists) {
                          admins.add({
                            "userID": admin,
                            "userPicture": adminInfo.data["userPicture"],
                            "userUsername": adminInfo.data["userUsername"],
                            "userFirstName": playerInfo.data["userFirstName"],
                "userLastName": playerInfo.data["userLastName"]
                          });
                          if (admins.length == tournamentAdmins.length) {
                            setState(() {
                              usersLoaded = true;
                            });
                          }
                        }
                      },
                    );
                  }
                } else {
                  setState(() {
                    usersLoaded = true;
                  });
                }
              }
            }
          });
        }
      } else {
        if (tournamentAdmins.isNotEmpty) {
          for (String admin in tournamentAdmins) {
            Firestore.instance.document("Users/$admin").get().then(
              (adminInfo) {
                if (adminInfo.exists) {
                  admins.add({
                    "userID": admin,
                    "userPicture": adminInfo.data["userPicture"],
                    "userUsername": adminInfo.data["userUsername"],
                    "userFirstName": adminInfo.data["userFirstName"],
                "userLastName": adminInfo.data["userLastName"]
                  });
                  if (admins.length == tournamentAdmins.length) {
                    setState(() {
                      usersLoaded = true;
                    });
                  }
                }
              },
            );
          }
        } else {
          setState(() {
            usersLoaded = true;
          });
        }
      }

      {
        setState(() {
          usersLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: new BackButton(
          color: Color.fromRGBO(0, 150, 255, 1.0),
        ),
        elevation: 0.0,
      ),
      body: new Column(
        children: <Widget>[
          widget.title == "Players"
              ? new Container(
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
                  child: new Container(
                    constraints: BoxConstraints(
                      maxWidth: 350.0,
                    ),
                    child: new CupertinoSegmentedControl(
                      groupValue: _currentIndex,
                      pressedColor: Color.fromRGBO(0, 150, 255, 1.0),
                      selectedColor: Color.fromRGBO(0, 150, 255, 1.0),
                      unselectedColor: Colors.transparent,
                      borderColor: Color.fromRGBO(0, 150, 255, 1.0),
                      onValueChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                          if (_currentIndex == 0) {
                            title = "Players";
                            users = players;
                          } else {
                            title = "Admins";
                            users = admins;
                          }
                        });
                      },
                      children: {
                        0: new Container(
                          padding: EdgeInsets.only(left: 40.0, right: 40.0),
                          child: new Text(
                            "Players",
                            style: new TextStyle(
                                color: _currentIndex == 0
                                    ? Colors.white
                                    : Color.fromRGBO(0, 150, 255, 1.0),
                                fontSize: 14.0,
                                fontFamily: "Century Gothic",
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        1: new Container(
                          padding: EdgeInsets.only(left: 40.0, right: 40.0),
                          child: new Text(
                            "Admins",
                            style: new TextStyle(
                                color: _currentIndex == 1
                                    ? Colors.white
                                    : Color.fromRGBO(0, 150, 255, 1.0),
                                fontSize: 14.0,
                                fontFamily: "Century Gothic",
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      },
                    ),
                  ),
                )
              : new Container(),
          new Expanded(
            child: users.isEmpty
                ? new Center(
                    child: usersLoaded == false
                        ? new CircularProgressIndicator(
                            backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
                          )
                        : new Center(
                            child: new Text(
                              "No Users",
                              style: TextStyle(
                                color: Color.fromRGBO(170, 170, 170, 1.0),
                                fontSize: 20.0,
                                fontFamily: "Century Gothic",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  )
                : ListView.builder(
                   padding: EdgeInsets.only(top: 0.0, bottom: 10.0, left: 15.0, right: 15.0),
                    itemBuilder: (BuildContext context, int index) {
                      Map<dynamic, dynamic> user = users[index];
                      return new UserBox(
                        user: user,
                        currentUser: widget.currentUser,
                        userBoxType: widget.title,
                        tournamentID: widget.id,
                      );
                    },
                    itemCount: users.length,
                  ),
          ),
        ],
      ),
    );
  }
}
