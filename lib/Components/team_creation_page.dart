import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/Utilities/formatters.dart';
import 'package:gg/UI/user_box.dart';
import 'team_name_page.dart';

class TeamCreationPage extends StatefulWidget {
  final String currentUser;

  TeamCreationPage({Key key, @required this.currentUser}) : super(key: key);

  _TeamCreationPage createState() => _TeamCreationPage();
}

class _TeamCreationPage extends State<TeamCreationPage> {
  String _currentUser;

  List teamUsers;
  List teamUsernames;

  TextEditingController searchTextController;

  bool checkInProgress;
  bool teamExists;

  @override
  void initState() {
    super.initState();

    _currentUser = widget.currentUser;

    checkInProgress = false;
    teamExists = false;

    teamUsers = new List();
    teamUsernames = new List();

    searchTextController = TextEditingController()
      ..addListener(() {
        setState(() {
          if (teamExists) {
            teamExists = false;
          }
        });
      });
  }

  _fetchStream(String searchQuery) {
    if (searchQuery != "") {
      var strSearch = searchQuery;
      var strlength = strSearch.length;
      var strFrontCode = strSearch.substring(0, strlength - 1);
      var strEndCode = strSearch.substring(strlength - 1, strSearch.length);

      var startcode = strSearch;
      var endcode =
          strFrontCode + String.fromCharCode(strEndCode.codeUnitAt(0) + 1);

      return Firestore.instance
          .collection("Users")
          // .where("userFollowers", arrayContains: _currentUser)
          .where("userUsername", isGreaterThanOrEqualTo: startcode)
          .where("userUsername", isLessThan: endcode)
          .snapshots();
    }
    return new Stream<QuerySnapshot>.empty();
  }

  _handleTeamCreation(String currentUser, List teamUserIDS) {
    List team = List.from(teamUserIDS);
    team.add(currentUser);
    setState(() {
      checkInProgress = true;
    });
    try {
      Firestore.instance
          .collection("Teams")
          .where("teamUsers", arrayContains: currentUser)
          .getDocuments()
          .then((teamDocuments) {
        if (teamDocuments.documents.isNotEmpty) {
          int number = 0;
          for (DocumentSnapshot teamInfo in teamDocuments.documents) {
            number = number + 1;
            Set teamUsers = Set.from(teamInfo.data["teamUsers"]);
            if (teamUsers.containsAll(team) &&
                teamUsers.length == team.length) {
              setState(() {
                checkInProgress = false;
                teamExists = true;
              });
            }
            if (number == teamDocuments.documents.length && !teamExists) {
              setState(() {
                checkInProgress = false;
              });
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new TeamNamePage(team: team),
                ),
              );
            }
          }
        } else {
          setState(() {
                checkInProgress = false;
              });
          Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new TeamNamePage(team: team),
                ),
              );
        }
      });
    } catch (error) {
      print("Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Create a Team",
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
        actions: <Widget>[
          new GestureDetector(
            child: new Container(
              padding: EdgeInsets.only(right: 10.0),
              color: Colors.transparent,
              alignment: Alignment.center,
              child: new Text(
                "Next",
                style: TextStyle(
                  color: !teamExists &&
                          teamUsers.length > 0 &&
                          teamUsers.length <= 10
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              if (!teamExists &&
                  teamUsers.length > 0 &&
                  teamUsers.length <= 10 &&
                  !checkInProgress) {
                _handleTeamCreation(_currentUser, teamUsers);
              }
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new Column(
            children: <Widget>[
              teamUsers.isNotEmpty
                  ? new Container(
                      height: 50.0,
                      child: new ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        itemBuilder: (BuildContext context, int index) {
                          return new Container(
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(right: 5.0),
                            child: new Container(
                              padding: EdgeInsets.only(
                                  left: 10.0,
                                  right: 10.0,
                                  top: 2.0,
                                  bottom: 2.0),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(0, 150, 255, 1.0),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  new Container(
                                      child: new Text(
                                    teamUsernames[index],
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        fontFamily: "Avenir",
                                        fontWeight: FontWeight.bold),
                                  )),
                                  new GestureDetector(
                                    child: new Icon(
                                      Icons.clear,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        teamUsers.removeAt(index);
                                        teamUsernames.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: teamUsers.length,
                      ),
                    )
                  : new Container(),
              new Container(
                constraints: BoxConstraints(
                  minHeight: 50.0,
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1.0,
                      color: Color.fromRGBO(40, 40, 40, 1.0),
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: new TextField(
                  maxLines: 1,
                  autocorrect: false,
                  autofocus: true,
                  inputFormatters: [LowerCaseTextFormatter()],
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontFamily: "Avenir",
                      fontWeight: FontWeight.bold),
                  controller: searchTextController,
                  decoration: InputDecoration.collapsed(
                    hintText: "Add people to your team...",
                    hintStyle: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 18.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              teamUsers.isNotEmpty
                  ? new Container(
                      alignment: Alignment.topRight,
                      padding: EdgeInsets.only(top: 5.0, right: 10.0),
                      child: new Text(
                        "${teamUsers.length.toString()}/10 Teammates",
                        style: TextStyle(
                            color: teamUsers.length > 10
                                ? Colors.red
                                : Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 12.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold),
                      ))
                  : new Container(),
              teamExists
                  ? new Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(top: 10.0),
                      child: new Text(
                        "Team already exists",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 15.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold),
                      ))
                  : new Container(),
              new Expanded(
                child: new StreamBuilder(
                  stream: _fetchStream(searchTextController.text),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return new Center(
                        child: new Text(
                          "No Users Found",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    } else if (userSnapshot.data.documents.isEmpty) {
                      return new Center(
                        child: new Text(
                          "No Users Found",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    } else {
                      print(userSnapshot.data.documents.length);
                      return new ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        itemBuilder: (BuildContext context, int index) {
                          Map<dynamic, dynamic> user =
                              Map.from(userSnapshot.data.documents[index].data);
                          if (user["userID"] != _currentUser &&
                              !teamUsers.contains(user["userID"])) {
                            return new GestureDetector(
                              child: new UserBox(
                                user: user,
                                userBoxType: "Conversation",
                                currentUser: _currentUser,
                              ),
                              onTap: () {
                                setState(() {
                                  searchTextController.text = "";
                                  teamUsers.add(user["userID"]);
                                  teamUsernames.add(user["userUsername"]);
                                });
                              },
                            );
                          } else {
                            return new Container();
                          }
                        },
                        itemCount: userSnapshot.data.documents.length,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          checkInProgress
              ? new Center(
                  child: new CircularProgressIndicator(
                    backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                  ),
                )
              : new Container(),
        ],
      ),
    );
  }
}
