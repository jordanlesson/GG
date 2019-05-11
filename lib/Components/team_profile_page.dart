import 'package:flutter/material.dart';
import 'package:gg/globals.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/UI/user_box.dart';

class TeamProfilePage extends StatefulWidget {

  final String teamID;
  final Map<dynamic, dynamic> team;

  TeamProfilePage({Key key, @required this.teamID, @required this.team}) : super(key: key);

  _TeamProfilePage createState() => _TeamProfilePage();
}

class _TeamProfilePage extends State<TeamProfilePage> {

  bool teamUsersLoaded;
  List<Map<dynamic, dynamic>> teamUsers;

  void initState() { 
    super.initState();
    _fetchTeamMembers();
    teamUsersLoaded = false;
    teamUsers = List();
  }

  _fetchTeamMembers() async {
    for (String teamMember in widget.team["teamUsers"]) {
        Firestore.instance.document("Users/$teamMember").get().then((userInfo) {
          if (userInfo.exists) {
            teamUsers.add(userInfo.data);
            if (teamUsers.length == widget.team["teamUsers"].length) {
              setState(() {
                              teamUsersLoaded = true;
                            });
            }
          }
        });
      }
    }
  

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          widget.team["teamName"],
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold
          ),
        ),
        leading: new BackButton(
          color: Color.fromRGBO(0, 150, 255, 1.0),
        ),
        elevation: 0.0,
      ),
      body: new CustomScrollView(
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
                          new NetworkImage(widget.team["teamPicture"]),
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
    );
  }
}