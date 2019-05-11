import 'package:flutter/material.dart';
import 'package:gg/Components/match_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchBox extends StatefulWidget {
  final Map<dynamic, dynamic> match;
  final String matchID;
  final String currentUser;
  final List userTeams;
  final Map<dynamic, dynamic> tournamentInfo;

  MatchBox(
      {Key key,
      @required this.match,
      @required this.matchID,
      @required this.currentUser,
      @required this.userTeams,
      @required this.tournamentInfo})
      : super(key: key);

  _MatchBox createState() => _MatchBox();
}

class _MatchBox extends State<MatchBox> {
  Map<dynamic, dynamic> match;
  bool userMatch;

  @override
  void initState() {
    super.initState();
    match = Map.from(widget.match);

    userMatch = match["matchTeamOne"] == widget.currentUser ||
        match["matchTeamTwo"] == widget.currentUser;

    for (String team in widget.userTeams) {
      if (match["matchTeamOne"] == team || match["matchTeamTwo"] == team) {
        userMatch = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Container(
        height: 80.0,
        margin: EdgeInsets.only(top: 15.0, left: 15.0, right: 15.0),
        child: new Row(
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(right: 15.0),
              child: new Text(
                "${match["matchNumber"]}",
                style: TextStyle(
                    color: Color.fromRGBO(50, 50, 50, 1.0),
                    fontSize: 12.0,
                    fontFamily: "Century Gothic",
                    fontWeight: FontWeight.bold),
              ),
            ),
            new Expanded(
              child: new Container(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  border: Border.all(
                    width: 1.0,
                    color: userMatch
                        ? Color.fromRGBO(0, 150, 255, 1.0)
                        : Color.fromRGBO(40, 40, 40, 1.0),
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    new BoxShadow(
                      blurRadius: 4.0,
                      color: userMatch
                          ? Color.fromRGBO(0, 150, 255, 0.3)
                          : Color.fromRGBO(0, 0, 0, 0.5),
                      offset: new Offset(0.0, 4.0),
                    )
                  ],
                ),
                child: new Container(
                  padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                  child: new Column(
                    children: <Widget>[
                      new Expanded(
                        child: match["matchTeamOne"] != null &&
                                match["matchTeamOne"] != ""
                            ? new StreamBuilder(
                                stream: Firestore.instance
                                    .document("Users/${match["matchTeamOne"]}")
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot>
                                        userSnapshot) {
                                  return new StreamBuilder(
                                    stream: Firestore.instance
                                        .document(
                                            "Teams/${match["matchTeamOne"]}")
                                        .snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            teamSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.active) {
                                        return new Container(
                                          alignment: Alignment.bottomCenter,
                                          child: new Row(
                                            children: <Widget>[
                                              new CircleAvatar(
                                                backgroundColor: Color.fromRGBO(
                                                    0, 150, 255, 1.0),
                                                radius: 12.5,
                                                child: new CircleAvatar(
                                                  backgroundColor:
                                                      Color.fromRGBO(
                                                          50, 50, 50, 1.0),
                                                  radius: 11.5,
                                                  backgroundImage: NetworkImage(
                                                    userSnapshot.data.data !=
                                                            null
                                                        ? userSnapshot.data
                                                            .data["userPicture"]
                                                        : teamSnapshot
                                                                .data.data[
                                                            "teamPicture"],
                                                  ),
                                                ),
                                              ),
                                              new Expanded(
                                                child: new Container(
                                                  margin: EdgeInsets.only(
                                                      left: 5.0, right: 5.0),
                                                  child: new Text(
                                                    userSnapshot.data.data !=
                                                            null
                                                        ? userSnapshot
                                                                .data.data[
                                                            "userUsername"]
                                                        : teamSnapshot.data
                                                            .data["teamName"],
                                                    overflow: TextOverflow.fade,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13.0,
                                                      fontFamily:
                                                          "Century Gothic",
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              new Container(
                                                margin:
                                                    EdgeInsets.only(right: 5.0),
                                                child: new Text(
                                                  match["matchTeamOneWinner"] ==
                                                              match[
                                                                  "matchTeamTwoWinner"] &&
                                                          match["matchTeamOneWinner"] ==
                                                              match[
                                                                  "matchTeamOne"]
                                                      ? "W"
                                                      : "",
                                                  style: TextStyle(
                                                      color: Color.fromRGBO(
                                                          0, 150, 255, 1.0),
                                                      fontSize: 15.0,
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
                                          alignment: Alignment.topCenter,
                                          child: new CircleAvatar(
                                            backgroundColor:
                                                Color.fromRGBO(23, 23, 23, 1.0),
                                            radius: 12.5,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              )
                            : new Container(
                                alignment: Alignment.topCenter,
                                child: new CircleAvatar(
                                  backgroundColor:
                                      Color.fromRGBO(23, 23, 23, 1.0),
                                  radius: 12.5,
                                ),
                              ),
                      ),
                      new Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new Expanded(
                            child: new Container(
                              height: 1.0,
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                          ),
                          new Container(
                            margin: EdgeInsets.only(left: 10.0, right: 10.0),
                            child: new Text(
                              "vs",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color.fromRGBO(0, 150, 255, 1.0),
                                fontSize: 13.0,
                                fontFamily: "Century Gothic",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          new Expanded(
                            child: new Container(
                              height: 1.0,
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                          ),
                        ],
                      ),
                      new Expanded(
                        child: match["matchTeamTwo"] != null &&
                                match["matchTeamTwo"] != ""
                            ? new StreamBuilder(
                                stream: Firestore.instance
                                    .document("Users/${match["matchTeamTwo"]}")
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot>
                                        userSnapshot) {
                                  return new StreamBuilder(
                                      stream: Firestore.instance
                                          .document(
                                              "Teams/${match["matchTeamTwo"]}")
                                          .snapshots(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot>
                                              teamSnapshot) {
                                        if (userSnapshot.connectionState ==
                                            ConnectionState.active) {
                                          return new Container(
                                            alignment: Alignment.topCenter,
                                            child: new Row(
                                              children: <Widget>[
                                                new CircleAvatar(
                                                  backgroundColor:
                                                      Color.fromRGBO(
                                                          0, 150, 255, 1.0),
                                                  radius: 12.5,
                                                  child: new CircleAvatar(
                                                    backgroundColor:
                                                        Color.fromRGBO(
                                                            50, 50, 50, 1.0),
                                                    radius: 11.5,
                                                    backgroundImage:
                                                        NetworkImage(
                                                      userSnapshot.data.data !=
                                                              null
                                                          ? userSnapshot
                                                                  .data.data[
                                                              "userPicture"]
                                                          : teamSnapshot
                                                                  .data.data[
                                                              "teamPicture"],
                                                    ),
                                                  ),
                                                ),
                                                new Expanded(
                                                  child: new Container(
                                                    margin: EdgeInsets.only(
                                                        left: 5.0, right: 5.0),
                                                    child: new Text(
                                                      userSnapshot.data.data !=
                                                              null
                                                          ? userSnapshot
                                                                  .data.data[
                                                              "userUsername"]
                                                          : teamSnapshot.data
                                                              .data["teamName"],
                                                      overflow:
                                                          TextOverflow.fade,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13.0,
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
                                                      right: 5.0),
                                                  child: new Text(
                                                    match["matchTeamOneWinner"] ==
                                                                match[
                                                                    "matchTeamTwoWinner"] &&
                                                            match["matchTeamOneWinner"] ==
                                                                match[
                                                                    "matchTeamTwo"]
                                                        ? "W"
                                                        : "",
                                                    style: TextStyle(
                                                        color: Color.fromRGBO(
                                                            0, 150, 255, 1.0),
                                                        fontSize: 15.0,
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
                                            alignment: Alignment.topCenter,
                                            child: new CircleAvatar(
                                              backgroundColor: Color.fromRGBO(
                                                  23, 23, 23, 1.0),
                                              radius: 12.5,
                                            ),
                                          );
                                        }
                                      });
                                },
                              )
                            : new Container(
                                alignment: Alignment.topCenter,
                                child: new CircleAvatar(
                                  backgroundColor:
                                      Color.fromRGBO(23, 23, 23, 1.0),
                                  radius: 12.5,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        if (match["matchTeamOne"] != "" || match["matchTeamTwo"] != "") {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => new MatchDetailsPage(
                    match: match,
                    matchID: widget.matchID,
                    tournamentInfo: widget.tournamentInfo,
                    userTeams: widget.userTeams,
                  ),
            ),
          );
        }
      },
    );
  }
}
