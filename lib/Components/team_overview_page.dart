import 'package:flutter/material.dart';
import 'package:gg/UI/user_box.dart';
import 'package:gg/globals.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'master_page.dart';

class TeamOverviewPage extends StatefulWidget {
  final Map<String, dynamic> team;

  TeamOverviewPage({Key key, @required this.team}) : super(key: key);

  _TeamOverviewPage createState() => _TeamOverviewPage();
}

class _TeamOverviewPage extends State<TeamOverviewPage> {
  List<Map<dynamic, dynamic>> teamUsers;
  bool teamUsersLoaded;
  bool teamCreationInProgress;

  @override
  void initState() {
    super.initState();
    _fetchTeamMembers();
    teamUsersLoaded = false;
    teamCreationInProgress = false;
  }

  void _fetchTeamMembers() {
    teamUsers = new List();
    for (String teamUser in widget.team["teamUsers"]) {
      Firestore.instance.document("Users/$teamUser").get().then((userInfo) {
        if (userInfo.exists) {
          teamUsers.add({
            "userUsername": userInfo.data["userUsername"],
            "userPicture": userInfo.data["userPicture"],
            "userFirstName": userInfo.data["userFirstName"],
            "userLastName": userInfo.data["userLastName"],
          });
          if (teamUsers.length == widget.team["teamUsers"].length) {
            setState(() {
              teamUsersLoaded = true;
            });
          }
        }
      });
    }
  }

  void _handleTeam() async {
    setState(() {
      teamCreationInProgress = true;
    });
    Firestore.instance.collection("Teams").add({
      "teamName": widget.team["teamName"],
      "teamUsers": widget.team["teamUsers"]
    }).then((teamInfo) async {
      StorageReference firebaseRef = FirebaseStorage.instance
          .ref()
          .child("Teams/${teamInfo.documentID}/picture/picture.png");

      firebaseRef
          .putFile(widget.team["teamPicture"])
          .onComplete
          .then((teamPicture) async {
        String teamPictureURL = await firebaseRef.getDownloadURL();

        Firestore.instance
            .document("Teams/${teamInfo.documentID}")
            .setData({"teamPicture": teamPictureURL}, merge: true).then((_) {
          setState(() {
            teamCreationInProgress = false;
          });
          Navigator.of(context).pop([
            Navigator.of(context).pop([Navigator.of(context).pop([Navigator.of(context).pop()])])
          ]);
        });
      });
    }).catchError((error) {
      print("Error: $error");
      setState(() {
        teamCreationInProgress = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Overview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: !teamCreationInProgress
            ? new BackButton(
                color: Color.fromRGBO(0, 155, 255, 1.0),
              )
            : new BackButton(
                color: Color.fromRGBO(170, 170, 170, 1.0),
              ),
        actions: <Widget>[
          new GestureDetector(
            child: new Container(
              padding: EdgeInsets.only(right: 10.0),
              color: Colors.transparent,
              alignment: Alignment.center,
              child: new Text(
                "Create",
                style: TextStyle(
                  color: !teamCreationInProgress
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              if (!teamCreationInProgress) {
                _handleTeam();
              }
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new CustomScrollView(
            slivers: <Widget>[
              new SliverToBoxAdapter(
                child: new Container(
                  padding: EdgeInsets.only(top: 10.0),
                  child: new CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                    child: new CircleAvatar(
                      radius: 46.0,
                      backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                      backgroundImage:
                          new FileImage(widget.team["teamPicture"]),
                    ),
                  ),
                ),
              ),
              new SliverToBoxAdapter(
                child: new Container(
                  margin: EdgeInsets.only(top: 5.0),
                  alignment: Alignment.center,
                  child: new Text(
                    widget.team["teamName"],
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              new SliverToBoxAdapter(
                  child: new Container(
                      height: 50.0,
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.only(left: 15.0),
                      child: new Text(
                        "Teammates",
                        style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 18.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold),
                      ))),
              teamUsersLoaded
                  ? new SliverList(
                      delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                        return new Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: new UserBox(
                            user: teamUsers[index],
                            currentUser: globals.currentUser,
                            userBoxType: "Conversation",
                          ),
                        );
                      }, childCount: teamUsers.length),
                    )
                  : new SliverFillRemaining(
                      child: new Container(
                        child: new CircularProgressIndicator(
                          backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                        ),
                      ),
                    ),
            ],
          ),
          teamCreationInProgress
              ? new Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                  ),
                )
              : new Container(),
        ],
      ),
    );
  }
}
