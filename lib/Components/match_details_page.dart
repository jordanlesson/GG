import 'package:flutter/material.dart';
import 'package:gg/globals.dart' as globals;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gg/UI/match_message_box.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

class MatchDetailsPage extends StatefulWidget {
  _MatchDetailsPage createState() => new _MatchDetailsPage();

  final Map<dynamic, dynamic> match;
  final String matchID;
  final List userTeams;
  final Map<dynamic, dynamic> tournamentInfo;

  MatchDetailsPage(
      {Key key,
      @required this.match,
      @required this.matchID,
      @required this.userTeams,
      @required this.tournamentInfo})
      : super(key: key);
}

class _MatchDetailsPage extends State<MatchDetailsPage>
    with SingleTickerProviderStateMixin {
  Map<dynamic, dynamic> match;
  String matchID;
  Map<dynamic, dynamic> tournamentInfo;
  String currentUserTeam;
  String otherTeam;
  bool userMatch;

  String matchResult;
  bool matchResultConflict;
  bool matchConfirmation;
  bool typing;
  bool readyToSend;

  double matchConflictOpacity;

  Animation matchConflictAnimation;
  AnimationController matchConflictAnimationController;

  TextEditingController matchMessageTextController;

  @override
  void initState() {
    super.initState();

    match = widget.match;
    matchID = widget.matchID;
    tournamentInfo = widget.tournamentInfo;

    userMatch = false;

    for (String team in widget.userTeams) {
      userMatch = match["matchTeamOne"] == team ||
          match["matchTeamOne"] == globals.currentUser;

      if (match["matchTeamOne"] == globals.currentUser ||
          match["matchTeamOne"] == team) {
        setState(() {
          currentUserTeam = "matchTeamOne";
          otherTeam = "matchTeamTwo";
        });
      }
      if (match["matchTeamTwo"] == globals.currentUser ||
          match["matchTeamTwo"] == team) {
        setState(() {
          currentUserTeam = "matchTeamTwo";
          otherTeam = "matchTeamOne";
        });
      }
    }

    matchResultConflict = false;
    matchConfirmation = false;
    typing = false;
    readyToSend = false;

    matchMessageTextController = new TextEditingController()
      ..addListener(matchMessage);

    matchConflictOpacity = 0.0;

    matchConflictAnimationController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    final CurvedAnimation curve = CurvedAnimation(
        parent: matchConflictAnimationController, curve: Curves.linear);
    matchConflictAnimation = Tween(begin: 1.0, end: 0.0).animate(curve)
      ..addListener(() {
        setState(() {
          matchConflictOpacity = matchConflictAnimation.value;
        });
      });
  }

  matchMessage() {
    if (matchMessageTextController.text.isNotEmpty) {
      setState(() {
        readyToSend = true;
      });
    } else {
      setState(() {
        readyToSend = false;
      });
    }
  }

  _handleMatchMessage(String matchMessageBody) {
    setState(() {
      matchMessageTextController.clear();
      readyToSend = false;
    });

    Map<String, dynamic> matchMessage = {
      "messageBody": matchMessageBody,
      "messageDate": DateTime.now(),
      "messageConversationID": matchID,
      "messageUserID": globals.currentUser,
    };

    try {
      Firestore.instance.collection("Messages").add(matchMessage);
    } catch (error) {
      print(error);
    }
  }

  _handleMatchResult(String currentUser, String matchResult) {
    print(matchResult);
    setState(() {
      matchConfirmation = false;
    });
    String matchTeamWinner = "";
    String matchWinner = "";
    if (matchResult == "Win") {
      matchWinner = match[currentUserTeam];
      if (match[currentUserTeam] == match["matchTeamOne"]) {
        matchTeamWinner = "matchTeamOneWinner";
      } else {
        matchTeamWinner = "matchTeamTwoWinner";
      }
      Firestore.instance.document("Matches/$matchID").updateData({
        matchTeamWinner: matchWinner,
      });
    } else {
      if (match[currentUserTeam] == match["matchTeamOne"]) {
        matchWinner = match["matchTeamTwo"];
      } else {
        matchWinner = match["matchTeamOne"];
      }
      Firestore.instance.document("Matches/$matchID").updateData({
        "matchTeamOneWinner": matchWinner,
        "matchTeamTwoWinner": matchWinner,
      });
    }
  }

  Widget matchButtons(AsyncSnapshot<DocumentSnapshot> matchSnapshot) {
    if (!matchSnapshot.hasData) {
      return new Center(
        child: new AutoSizeText(
          "Loading Match...",
          minFontSize: 15.0,
          maxFontSize: 18.0,
          style: TextStyle(
            color: Color.fromRGBO(170, 170, 170, 1.0),
            fontFamily: "Avenir",
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      Map<String, dynamic> match = matchSnapshot.data.data;
      if (match["matchTeamOneWinner"] != "" &&
          match["matchTeamTwoWinner"] != "" &&
          match["matchTeamOneWinner"] != match["matchTeamTwoWinner"]) {
        return new Center(
          child: new AutoSizeText(
            "There has been a conflict, admin contacted",
            minFontSize: 15.0,
            maxFontSize: 18.0,
            style: TextStyle(
              color: Color.fromRGBO(170, 170, 170, 1.0),
              fontFamily: "Avenir",
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (userMatch) {
        if (match["${currentUserTeam}Winner"] != "") {
          if (match["${currentUserTeam}Winner"] == match[currentUserTeam]) {
            matchResult = "Win";
          } else {
            matchResult = "Loss";
          }
          return new Center(
            child: new AutoSizeText(
              "You Submitted a $matchResult",
              minFontSize: 15.0,
              maxFontSize: 18.0,
              style: TextStyle(
                color: Color.fromRGBO(170, 170, 170, 1.0),
                fontFamily: "Avenir",
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else if (matchResult == null) {
          return new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new GestureDetector(
                child: new Container(
                  height: 40.0,
                  width: 100.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 150, 255, 1.0),
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: [
                      new BoxShadow(
                        blurRadius: 4.0,
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        offset: new Offset(0.0, 4.0),
                      ),
                    ],
                  ),
                  child: new Text(
                    "WIN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  setState(() {
                    matchResult = "Win";
                  });
                },
              ),
              new GestureDetector(
                child: new Container(
                  height: 40.0,
                  width: 100.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: [
                      new BoxShadow(
                        blurRadius: 4.0,
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        offset: new Offset(0.0, 4.0),
                      ),
                    ],
                  ),
                  child: new Text(
                    "LOSS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  setState(() {
                    matchResult = "Loss";
                  });
                },
              ),
            ],
          );
        } else {
          return new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              new AutoSizeText(
                "Submit $matchResult?",
                minFontSize: 15.0,
                maxFontSize: 18.0,
                style: TextStyle(
                    color: Color.fromRGBO(170, 170, 170, 1.0),
                    fontSize: 18.0,
                    fontFamily: "Avenir",
                    fontWeight: FontWeight.bold),
              ),
              new GestureDetector(
                child: new Container(
                  height: 40.0,
                  width: 75.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 150, 255, 1.0),
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: [
                      new BoxShadow(
                        blurRadius: 4.0,
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        offset: new Offset(0.0, 4.0),
                      ),
                    ],
                  ),
                  child: new Text(
                    "YES",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  _handleMatchResult(globals.currentUser, matchResult);
                },
              ),
              new GestureDetector(
                child: new Container(
                  height: 40.0,
                  width: 75.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: [
                      new BoxShadow(
                        blurRadius: 4.0,
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        offset: new Offset(0.0, 4.0),
                      ),
                    ],
                  ),
                  child: new Text(
                    "NO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  setState(() {
                    matchResult = null;
                  });
                },
              ),
            ],
          );
        }
      }
    }
  }

  List<Widget> confirmation(String result, Map<dynamic, dynamic> matchInfo) {
    bool matchConflict = false;
    String matchTeamOneWinner = matchInfo["matchTeamOneWinner"];
    String matchTeamTwoWinner = matchInfo["matchTeamTwoWinner"];
    if (matchTeamOneWinner != matchTeamTwoWinner &&
        (matchTeamOneWinner != "" && matchTeamTwoWinner != "")) {
      matchConflict = true;
    }

    if (matchConfirmation) {
      return <Widget>[];
    } else if (matchConflict) {
      return <Widget>[
        new AutoSizeText(
          "There has been a conflict, admin contacted",
          minFontSize: 12.0,
          maxFontSize: 15.0,
          style: TextStyle(
            color: Color.fromRGBO(170, 170, 170, 1.0),
            fontFamily: "Avenir",
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } else if (matchTeamOneWinner == matchTeamTwoWinner) {
      return <Widget>[
        new AutoSizeText(
          matchTeamOneWinner == globals.currentUser
              ? "You Won This Match!"
              : "You Lost This Match",
          minFontSize: 15.0,
          maxFontSize: 18.0,
          style: TextStyle(
            color: Color.fromRGBO(170, 170, 170, 1.0),
            fontFamily: "Avenir",
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    } else {
      if (matchInfo["${currentUserTeam}Winner"] == globals.currentUser) {
        result = "Win";
      } else if (matchInfo["${currentUserTeam}Winner"] != "") {
        result = "Loss";
      }
      return <Widget>[
        new AutoSizeText(
          "You Submitted a $result",
          minFontSize: 15.0,
          maxFontSize: 18.0,
          style: TextStyle(
            color: Color.fromRGBO(170, 170, 170, 1.0),
            fontFamily: "Avenir",
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }
  }

  _showAdminMenu(BuildContext context, Map<dynamic, dynamic> matchInfo) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AdminMenu(
            matchConflict: matchInfo["matchConflict"],
            matchID: matchID,
          );
        });
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Match ${match["matchNumber"].toString()}",
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
          new StreamBuilder(
            stream: Firestore.instance.document("Matches/$matchID").snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> matchSnapshot) {
              return new IconButton(
                icon: Icon(
                  matchSnapshot.hasData &&
                          matchSnapshot.data.data["matchConflict"]
                      ? Icons.new_releases
                      : Icons.report,
                  color: matchSnapshot.hasData &&
                          matchSnapshot.data.data["matchConflict"]
                      ? Colors.yellow
                      : Colors.white,
                ),
                onPressed: () {
                  if (matchSnapshot.data.data["matchTeamOneWinner"] ==
                          matchSnapshot.data.data["matchTeamTwoWinner"] &&
                      matchSnapshot.data.data["matchTeamOneWinner"] != "") {
                  } else {
                    if (tournamentInfo["tournamentAdmins"]
                        .contains(globals.currentUser)) {
                      _showAdminMenu(context, matchSnapshot.data.data);
                    } else if (matchSnapshot.hasData &&
                        !matchSnapshot.data.data["matchConflict"]) {
                      setState(() {
                        matchConflictOpacity = 1.0;
                        new Timer(Duration(milliseconds: 1000), () {
                          setState(() {
                            matchConflictAnimationController.reset();
                            matchConflictAnimationController.forward();
                          });
                        });

                        try {
                          Firestore.instance
                              .document("Matches/${widget.matchID}")
                              .updateData({"matchConflict": true});
                        } catch (error) {
                          print(error);
                        }
                      });
                    }
                  }
                },
              );
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new Column(
            children: <Widget>[
              typing != true
                  ? new StreamBuilder(
                      stream: Firestore.instance
                          .document("Matches/$matchID")
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> matchSnapshot) {
                        return new Container(
                          child: new Column(
                            children: <Widget>[
                              new Container(
                                height: 160.0,
                                constraints: BoxConstraints(maxWidth: 350.0),
                                padding:
                                    EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                                margin:
                                    EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(23, 23, 23, 1.0),
                                  border: Border.all(
                                    width: 1.0,
                                    color: Color.fromRGBO(40, 40, 40, 1.0),
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                  boxShadow: [
                                    new BoxShadow(
                                      blurRadius: 4.0,
                                      color: Color.fromRGBO(0, 0, 0, 0.5),
                                      offset: new Offset(0.0, 4.0),
                                    )
                                  ],
                                ),
                                child: new Column(
                                  children: <Widget>[
                                    new Expanded(
                                      child:
                                          match["matchTeamOne"] != null &&
                                                  match["matchTeamOne"] != ""
                                              ? new StreamBuilder(
                                                  stream: Firestore.instance
                                                      .document(
                                                          "Users/${match["matchTeamOne"]}")
                                                      .snapshots(),
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot<
                                                              DocumentSnapshot>
                                                          userSnapshot) {
                                                    return new StreamBuilder(
                                                      stream: Firestore.instance
                                                          .document(
                                                              "Teams/${match["matchTeamOne"]}")
                                                          .snapshots(),
                                                      builder: (BuildContext
                                                              context,
                                                          AsyncSnapshot<
                                                                  DocumentSnapshot>
                                                              teamSnapshot) {
                                                        if (userSnapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .active) {
                                                          return new Container(
                                                            alignment: Alignment
                                                                .bottomCenter,
                                                            child: new Row(
                                                              children: <
                                                                  Widget>[
                                                                new CircleAvatar(
                                                                  backgroundColor:
                                                                      Color.fromRGBO(
                                                                          0,
                                                                          150,
                                                                          255,
                                                                          1.0),
                                                                  radius: 25.0,
                                                                  child:
                                                                      new CircleAvatar(
                                                                    backgroundColor:
                                                                        Color.fromRGBO(
                                                                            50,
                                                                            50,
                                                                            50,
                                                                            1.0),
                                                                    radius:
                                                                        23.0,
                                                                    backgroundImage:
                                                                        NetworkImage(
                                                                      userSnapshot.data.data !=
                                                                              null
                                                                          ? userSnapshot.data.data[
                                                                              "userPicture"]
                                                                          : teamSnapshot
                                                                              .data
                                                                              .data["teamPicture"],
                                                                    ),
                                                                  ),
                                                                ),
                                                                new Expanded(
                                                                  child:
                                                                      new Container(
                                                                    margin: EdgeInsets.only(
                                                                        left:
                                                                            5.0,
                                                                        right:
                                                                            5.0),
                                                                    child:
                                                                        new Text(
                                                                      userSnapshot.data.data !=
                                                                              null
                                                                          ? userSnapshot.data.data[
                                                                              "userUsername"]
                                                                          : teamSnapshot
                                                                              .data
                                                                              .data["teamName"],
                                                                      overflow:
                                                                          TextOverflow
                                                                              .fade,
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            18.0,
                                                                        fontFamily:
                                                                            "Century Gothic",
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                new Container(
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              5.0),
                                                                  child:
                                                                      new Text(
                                                                    match["matchTeamOneWinner"] == match["matchTeamTwoWinner"] &&
                                                                            match["matchTeamOneWinner"] ==
                                                                                match["matchTeamOne"]
                                                                        ? "W"
                                                                        : "",
                                                                    style: TextStyle(
                                                                        color: Color.fromRGBO(
                                                                            0,
                                                                            150,
                                                                            255,
                                                                            1.0),
                                                                        fontSize:
                                                                            20.0,
                                                                        fontFamily:
                                                                            "Century Gothic",
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        } else {
                                                          return new Container(
                                                            alignment: Alignment
                                                                .topCenter,
                                                            child:
                                                                new CircleAvatar(
                                                              backgroundColor:
                                                                  Color
                                                                      .fromRGBO(
                                                                          23,
                                                                          23,
                                                                          23,
                                                                          1.0),
                                                              radius: 25.0,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    );
                                                  },
                                                )
                                              : new Container(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  child: new CircleAvatar(
                                                    backgroundColor:
                                                        Color.fromRGBO(
                                                            23, 23, 23, 1.0),
                                                    radius: 12.5,
                                                  ),
                                                ),
                                    ),
                                    new Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        new Expanded(
                                          child: new Container(
                                            height: 1.0,
                                            color:
                                                Color.fromRGBO(40, 40, 40, 1.0),
                                          ),
                                        ),
                                        new Container(
                                          margin: EdgeInsets.only(
                                              left: 10.0, right: 10.0),
                                          alignment: Alignment.center,
                                          child: new Text(
                                            "vs",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color.fromRGBO(
                                                  0, 150, 255, 1.0),
                                              fontSize: 20.0,
                                              fontFamily: "Century Gothic",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        new Expanded(
                                          child: new Container(
                                            height: 1.0,
                                            color:
                                                Color.fromRGBO(40, 40, 40, 1.0),
                                          ),
                                        ),
                                      ],
                                    ),
                                    new Expanded(
                                      child:
                                          match["matchTeamTwo"] != null &&
                                                  match["matchTeamTwo"] != ""
                                              ? new StreamBuilder(
                                                  stream: Firestore.instance
                                                      .document(
                                                          "Users/${match["matchTeamTwo"]}")
                                                      .snapshots(),
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot<
                                                              DocumentSnapshot>
                                                          userSnapshot) {
                                                    return new StreamBuilder(
                                                        stream: Firestore
                                                            .instance
                                                            .document(
                                                                "Teams/${match["matchTeamTwo"]}")
                                                            .snapshots(),
                                                        builder: (BuildContext
                                                                context,
                                                            AsyncSnapshot<
                                                                    DocumentSnapshot>
                                                                teamSnapshot) {
                                                          if (userSnapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .active) {
                                                            return new Container(
                                                              alignment:
                                                                  Alignment
                                                                      .topCenter,
                                                              child: new Row(
                                                                children: <
                                                                    Widget>[
                                                                  new CircleAvatar(
                                                                    backgroundColor:
                                                                        Color.fromRGBO(
                                                                            0,
                                                                            150,
                                                                            255,
                                                                            1.0),
                                                                    radius:
                                                                        25.0,
                                                                    child:
                                                                        new CircleAvatar(
                                                                      backgroundColor:
                                                                          Color.fromRGBO(
                                                                              50,
                                                                              50,
                                                                              50,
                                                                              1.0),
                                                                      radius:
                                                                          23.0,
                                                                      backgroundImage:
                                                                          NetworkImage(
                                                                        userSnapshot.data.data !=
                                                                                null
                                                                            ? userSnapshot.data.data["userPicture"]
                                                                            : teamSnapshot.data.data["teamPicture"],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  new Expanded(
                                                                    child:
                                                                        new Container(
                                                                      margin: EdgeInsets.only(
                                                                          left:
                                                                              5.0,
                                                                          right:
                                                                              5.0),
                                                                      child:
                                                                          new Text(
                                                                        userSnapshot.data.data !=
                                                                                null
                                                                            ? userSnapshot.data.data["userUsername"]
                                                                            : teamSnapshot.data.data["teamName"],
                                                                        overflow:
                                                                            TextOverflow.fade,
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.white,
                                                                          fontSize:
                                                                              18.0,
                                                                          fontFamily:
                                                                              "Century Gothic",
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  new Container(
                                                                    margin: EdgeInsets.only(
                                                                        right:
                                                                            5.0),
                                                                    child:
                                                                        new Text(
                                                                      match["matchTeamOneWinner"] == match["matchTeamTwoWinner"] &&
                                                                              match["matchTeamOneWinner"] == match["matchTeamTwo"]
                                                                          ? "W"
                                                                          : "",
                                                                      style: TextStyle(
                                                                          color: Color.fromRGBO(
                                                                              0,
                                                                              150,
                                                                              255,
                                                                              1.0),
                                                                          fontSize:
                                                                              20.0,
                                                                          fontFamily:
                                                                              "Century Gothic",
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          } else {
                                                            return new Container(
                                                              alignment:
                                                                  Alignment
                                                                      .topCenter,
                                                              child:
                                                                  new CircleAvatar(
                                                                backgroundColor:
                                                                    Color.fromRGBO(
                                                                        23,
                                                                        23,
                                                                        23,
                                                                        1.0),
                                                                radius: 25.0,
                                                              ),
                                                            );
                                                          }
                                                        });
                                                  },
                                                )
                                              : new Container(
                                                  alignment:
                                                      Alignment.topCenter,
                                                  child: new CircleAvatar(
                                                    backgroundColor:
                                                        Color.fromRGBO(
                                                            23, 23, 23, 1.0),
                                                    radius: 25.0,
                                                  ),
                                                ),
                                    ),
                                  ],
                                ),
                              ),
                              userMatch
                                  ? new Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              width: 1.0,
                                              color: Color.fromRGBO(
                                                  40, 40, 40, 1.0)),
                                        ),
                                      ),
                                      child: new Container(
                                        margin: EdgeInsets.only(
                                            left: 15.0,
                                            right: 15.0,
                                            bottom: 10.0),
                                        constraints: BoxConstraints(
                                          maxWidth: 350.0,
                                        ),
                                        child: matchButtons(matchSnapshot),
                                      ),
                                    )
                                  : new Container()
                            ],
                          ),
                        );
                      },
                    )
                  : new Container(),
              new Flexible(
                fit: FlexFit.tight,
                child: new GestureDetector(
                  child: new Container(
                    color: Color.fromRGBO(5, 5, 10, 1.0),
                    child: new StreamBuilder(
                      stream: Firestore.instance
                          .collection("Messages")
                          .where("messageConversationID",
                              isEqualTo: widget.matchID)
                          .orderBy("messageDate", descending: true)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> matchMessageSnapshot) {
                        if (!matchMessageSnapshot.hasData) {
                          return new Container(
                            alignment: Alignment.center,
                            color: Colors.transparent,
                            child: new CircularProgressIndicator(
                              backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                            ),
                          );
                        } else if (matchMessageSnapshot
                            .data.documents.isEmpty) {
                          return new Container(
                            alignment: Alignment.center,
                            color: Colors.transparent,
                            child: new Text(
                              "No Messages Yet",
                              style: TextStyle(
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 20.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        } else {
                          return new ListView.builder(
                            padding: EdgeInsets.only(top: 0.0),
                            reverse: true,
                            itemBuilder: (BuildContext context, int index) {
                              Map<dynamic, dynamic> matchMessage = Map.from(
                                  matchMessageSnapshot
                                      .data.documents[index].data);
                              return MatchMessageBox(
                                matchMessage: matchMessage,
                              );
                            },
                            itemCount:
                                matchMessageSnapshot.data.documents.length,
                          );
                        }
                      },
                    ),
                  ),
                  onPanDown: (scrollDown) {
                    setState(() {
                      if (typing) {
                        typing = false;
                        FocusScope.of(context).requestFocus(FocusNode());
                      }
                    });
                  },
                ),
              ),
              new SafeArea(
                top: false,
                child: new Container(
                  constraints: BoxConstraints(maxHeight: 150.0),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          width: 1.0, color: Color.fromRGBO(40, 40, 40, 1.0)),
                    ),
                  ),
                  child: new Row(
                    children: <Widget>[
                      new Flexible(
                        child: Container(
                          margin: EdgeInsets.only(left: 10.0),
                          child: TextField(
                            maxLines: null,
                            onTap: () {
                              setState(() {
                                typing = true;
                              });
                            },
                            controller: matchMessageTextController,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontFamily: "Avenir",
                                fontWeight: FontWeight.bold),
                            decoration: InputDecoration.collapsed(
                              hintText: "Match chat",
                              hintStyle: TextStyle(
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 18.0,
                                  fontFamily: "Avenir",
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),

                      // Button send message
                      new Material(
                        child: new Container(
                          margin: new EdgeInsets.symmetric(horizontal: 8.0),
                          child: new IconButton(
                            icon: new Icon(
                              Icons.send,
                              color: readyToSend
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(170, 170, 170, 1.0),
                            ),
                            onPressed: () {
                              _handleMatchMessage(
                                  matchMessageTextController.text.trim());
                            },
                          ),
                        ),
                        color: Color.fromRGBO(23, 23, 23, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          new Opacity(
            opacity: matchConflictOpacity,
            child: new Center(
              child: new Container(
                height: 100.0,
                width: 250.0,
                margin: EdgeInsets.symmetric(horizontal: 40.0),
                constraints: BoxConstraints(maxWidth: 350.0),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  border: Border.all(
                    width: 1.0,
                    color: Color.fromRGBO(0, 150, 255, 1.0),
                  ),
                ),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Container(
                      margin: EdgeInsets.only(right: 5.0),
                      child: new Icon(
                        Icons.check_circle,
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                      ),
                    ),
                    new Text(
                      "Admin Contacted",
                      style: TextStyle(
                          color: Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 20.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMenu extends StatefulWidget {
  _AdminMenu createState() => new _AdminMenu();

  final bool matchConflict;
  final String matchID;

  AdminMenu({Key key, @required this.matchConflict, @required this.matchID})
      : super(key: key);
}

class _AdminMenu extends State<AdminMenu> {
  bool matchConflict;
  bool pushMatchTeamOne;
  bool pushMatchTeamTwo;

  void initState() {
    super.initState();
    matchConflict = widget.matchConflict;
    pushMatchTeamOne = false;
    pushMatchTeamTwo = false;
  }

  _handleMatchAdminUpdate(bool conflict, bool pushTeamOne, bool pushTeamTwo) {
    String matchWinner;
    Firestore.instance
        .document("Matches/${widget.matchID}")
        .get()
        .then((matchInfo) {
      if (matchInfo.exists) {
        if (pushTeamOne) {
          matchWinner = matchInfo["matchTeamOne"];
          Firestore.instance.document("Matches/${widget.matchID}").updateData({
            "matchConflict": conflict,
            "matchTeamOneWinner": matchWinner,
            "matchTeamTwoWinner": matchWinner,
          });
        } else if (pushTeamTwo) {
          matchWinner = matchInfo["matchTeamTwo"];
          Firestore.instance.document("Matches/${widget.matchID}").updateData({
            "matchConflict": conflict,
            "matchTeamOneWinner": matchWinner,
            "matchTeamTwoWinner": matchWinner,
          });
        } else {
          Firestore.instance.document("Matches/${widget.matchID}").updateData({
            "matchConflict": conflict,
          });
        }
      }
    });
  }

  Widget build(BuildContext context) {
    return new Center(
      child: new Material(
        type: MaterialType.transparency,
        child: new Container(
          height: 250.0,
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
                  "Admin Menu",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold),
                ),
              ),
              new Container(
                height: 50.0,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Expanded(
                      child: new Container(
                        child: new Text(
                          "Match Conflict",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 16.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    new CupertinoSwitch(
                      value: matchConflict,
                      activeColor: Color.fromRGBO(0, 150, 255, 1.0),
                      onChanged: (conflict) {
                        setState(() {
                          matchConflict = conflict;
                        });
                      },
                    ),
                  ],
                ),
              ),
              new Container(
                height: 50.0,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Expanded(
                      child: new Container(
                        child: new Text(
                          "Push Team 1 Foward",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 16.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    new CupertinoSwitch(
                      value: pushMatchTeamOne,
                      activeColor: Color.fromRGBO(0, 150, 255, 1.0),
                      onChanged: (push) {
                        setState(() {
                          pushMatchTeamOne = push;
                          if (pushMatchTeamTwo) {
                            pushMatchTeamTwo = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              new Container(
                height: 50.0,
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Expanded(
                      child: new Container(
                        child: new Text(
                          "Push Team 2 Forward",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 16.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    new CupertinoSwitch(
                      value: pushMatchTeamTwo,
                      activeColor: Color.fromRGBO(0, 150, 255, 1.0),
                      onChanged: (push) {
                        setState(() {
                          pushMatchTeamTwo = push;
                          if (pushMatchTeamOne) {
                            pushMatchTeamOne = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              new Expanded(
                child: new Container(
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      new GestureDetector(
                        child: new Container(
                            padding:
                                EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                            margin: EdgeInsets.only(bottom: 0.0, right: 5.0),
                            child: new Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Color.fromRGBO(0, 150, 255, 1.0),
                                fontSize: 15.0,
                                fontFamily: "Avenir Next",
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                      new GestureDetector(
                        child: new Container(
                            padding:
                                EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                            margin: EdgeInsets.only(bottom: 0.0, right: 20.0),
                            child: new Text(
                              "DONE",
                              style: TextStyle(
                                color: Color.fromRGBO(0, 150, 255, 1.0),
                                fontSize: 15.0,
                                fontFamily: "Avenir Next",
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          _handleMatchAdminUpdate(matchConflict,
                              pushMatchTeamOne, pushMatchTeamTwo);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
