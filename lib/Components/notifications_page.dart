import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'tournament_details_page.dart';

class NotificationsPage extends StatefulWidget {
  _NotificationsPage createState() => new _NotificationsPage();

  final String currentUser;

  NotificationsPage({Key key, @required this.currentUser}) : super(key: key);
}

class _NotificationsPage extends State<NotificationsPage> {
  String _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
  }

  Stream<DocumentSnapshot> _fetchStream(Map<dynamic, dynamic> notification) {
    switch (notification["notificationType"]) {
      case "user":
        return Firestore.instance
            .document("Users/${notification["notificationUserID"]}")
            .snapshots();
        break;
      case "tournament":
        return Firestore.instance
            .document("Tournaments/${notification["notificationTypeID"]}")
            .snapshots();
        break;
      case "match":
        return Firestore.instance
            .document("Tournaments/${notification["notificationUserID"]}")
            .snapshots();
        break;
      case "post":
        return Firestore.instance
            .document("Users/${notification["notificationUserID"]}")
            .snapshots();
    }
    return Firestore.instance
        .document("Users/${notification["notificationUserID"]}")
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        leading: new Container(),
        elevation: 0.0,
        title: new Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: new Container(
        child: new StreamBuilder(
          stream: Firestore.instance
              .collection("Notifications")
              .where("notificationAlertUserID", isEqualTo: _currentUser)
              .orderBy("notificationDate", descending: true)
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> notificationSnapshot) {
            if (!notificationSnapshot.hasData) {
              return new Center(
                child: new CircularProgressIndicator(
                  backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                ),
              );
            } else {
              //print(notificationSnapshot.data.documents.length);
              return notificationSnapshot.data.documents.isNotEmpty
                  ? new ListView.builder(
                      padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 10.0),
                      itemBuilder: (BuildContext context, int index) {
                        Map<dynamic, dynamic> notification =
                            notificationSnapshot.data.documents[index].data;
                        return new StreamBuilder(
                          stream: _fetchStream(notification),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot>
                                  notificationUser) {
                            if (!notificationUser.hasData) {
                              return new NotificationPlaceholder();
                            } else {
                              Map<dynamic, dynamic> notificationUserInfo =
                                  notificationUser.data.data;
                              return new NotificationBox(
                                notification: notification,
                                notificationID: notificationSnapshot
                                    .data.documents[index].documentID,
                                user: notificationUserInfo,
                              );
                            }
                          },
                        );
                      },
                      itemCount: notificationSnapshot.data.documents.length,
                    )
                  : new Center(
                      child: new Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new Container(
                            margin: EdgeInsets.only(bottom: 10.0),
                            child: new Text(
                              "No Notifications Yet",
                              style: TextStyle(
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 20.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
            }
          },
        ),
      ),
    );
  }
}

class NotificationBox extends StatefulWidget {
  _NotificationBox createState() => new _NotificationBox();

  final Map<dynamic, dynamic> notification;
  final String notificationID;
  final Map<dynamic, dynamic> user;

  NotificationBox(
      {Key key,
      @required this.notification,
      @required this.notificationID,
      @required this.user})
      : super(key: key);
}

class _NotificationBox extends State<NotificationBox> {
  Map<dynamic, dynamic> notification;
  Map<dynamic, dynamic> user;

  @override
  void initState() {
    super.initState();
    notification = widget.notification;
    user = widget.user;
  }

  fetchTimeStamp(DateTime notificationDate) {
    var timeDifference = notificationDate.difference(DateTime.now()).abs();
    if (timeDifference.inSeconds < 60) {
      // BETWEEN 0 SECONDS AND 1 MINUTE
      return "${timeDifference.inSeconds.toString()}s";
    } else if (timeDifference.inSeconds >= 60 &&
        timeDifference.inSeconds < 3600) {
      // BETWEEN 1 MINUTE AND 1 HOUR
      return "${timeDifference.inMinutes.toString()}m";
    } else if (timeDifference.inSeconds >= 3600 &&
        timeDifference.inSeconds <= 43200) {
      // BETWEEN 1 HOUR AND 12 HOURS
      return "${timeDifference.inHours.toString()}h";
    } else if (timeDifference.inSeconds > 43200 &&
        timeDifference.inSeconds <= 86400) {
      // BETWEEN 12 HOURS AND 1 DAY
      return "Today";
    } else if (timeDifference.inSeconds > 86400 &&
        timeDifference.inSeconds <= 172800) {
      // BETWEEN 1 DAY AND 2 DAYS
      return "Yesterday";
    } else if (timeDifference.inSeconds > 172800) {
      // GREATER THAN 2 DAYS
      return "${notificationDate.month.toString()}/${notificationDate.day.toString()}/${notificationDate.year.toString()}";
    }
  }

  void _handleMatchSetUp(String teamID, Map<dynamic, dynamic> notification) async {
    Firestore.instance
        .collection("Matches")
        .where("matchTournamentID", isEqualTo: notification["notificationTypeID"])
        .orderBy("matchNumber")
        .getDocuments()
        .then((matchDocuments) {
      bool teamPlaced = false;
      for (DocumentSnapshot matchInfo in matchDocuments.documents) {
        if (!teamPlaced) {
          if (matchInfo.data["matchTeamOne"] == "") {
            teamPlaced = true;
            Firestore.instance
                .document("Matches/${matchInfo.documentID}")
                .updateData({"matchTeamOne": teamID});
          } else if (matchInfo.data["matchTeamTwo"] == "") {
            teamPlaced = true;
            Firestore.instance
                .document("Matches/${matchInfo.documentID}")
                .updateData({"matchTeamTwo": teamID});
          }
        }
      }
    });
  }

  void _handleTournamentJoin(String teamID, Map<dynamic, dynamic> notification) async {
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance
                .document("Tournaments/${notification["notificationTypeID"]}"))
            .then((tournamentInfo) async {
          if (tournamentInfo.exists) {
            List tournamentPlayers =
                List.from(tournamentInfo.data["tournamentPlayers"]);
            if (!tournamentPlayers.contains(teamID)) {
              tournamentPlayers.add(teamID);
            }
            await transaction.update(
                Firestore.instance
                    .document("Tournaments/${notification["notificationTypeID"]}"),
                <String, dynamic>{
                  "tournamentPlayers": tournamentPlayers,
                }).then((_) {
              _handleMatchSetUp(teamID, notification);
            });
          }
        });
      });
  }

  void _handleTournamentRequest(String action, Map<dynamic, dynamic> notification) {
    if (action == "confirm") {
      Firestore.instance
          .document("Notifications/${widget.notificationID}")
          .delete()
          .then((_) {
            print(notification);
        Firestore.instance
            .document("Tournaments/${notification["notificationTypeID"]}")
            .get()
            .then((tournamentInfo) {
          if (tournamentInfo.exists) {
            print("Good bye");
            List tournamentRequests =
                List.from(tournamentInfo.data["tournamentRequests"]);
            List tournamentPlayers =
                List.from(tournamentInfo.data["tournamentPlayers"]);
            int tournamentBracketSize =
                tournamentInfo.data["tournamentBracketSize"];
            if (!tournamentPlayers
                    .contains(notification["notificationUserID"]) &&
                tournamentPlayers.length != tournamentBracketSize) {
                  print("Hello");
              tournamentRequests.remove(notification["notificationUserID"]);
              Firestore.instance
                  .document("Tournaments/${notification["notificationTypeID"]}")
                  .updateData({
                "tournamentRequests": tournamentRequests,
              }).then((_) {
                _handleTournamentJoin(notification["notificationUserID"], notification);
              });
            }
          }
        });
      });
    } else {
      Firestore.instance
          .document("Notifications/${widget.notificationID}")
          .delete()
          .then((_) {
        Firestore.instance
            .document("Tournaments/${notification["notificationTypeID"]}")
            .get()
            .then((tournamentInfo) {
          if (tournamentInfo.exists) {
            List tournamentRequests =
                List.from(tournamentInfo.data["tournamentRequests"]);
            if (tournamentRequests
                .contains(notification["notificationUserID"])) {
              tournamentRequests.remove(notification["notificationUserID"]);
              Firestore.instance
                  .document("Tournaments/${notification["notificationTypeID"]}")
                  .updateData({"tournamentRequests": tournamentRequests});
            }
          }
        });
      });
    }
  }

  _fetchNotificationBody1() {
    switch (notification["notificationType"]) {
      case "user":
        return user["userUsername"];
        break;
      case "tournament":
        return user["userUsername"];
        break;
      case "match":
        return notification["notificationBody"];
        break;
      case "post":
        return user["userUsername"];
        break;
    }
  }

  _fetchNotificationBody2() {
    switch (notification["notificationType"]) {
      case "user":
        return notification["notificationBody"];
        break;
      case "tournament":
        return notification["notificationBody"];
        break;
      case "match":
        return user["tournamentName"];
        break;
      case "post":
        return notification["notificationBody"];
        break;
    }
  }

  Widget build(BuildContext context) {
    notification = widget.notification;
    user = widget.user;
    return new GestureDetector(
        child: new Container(
          height: 60.0,
          margin: EdgeInsets.only(top: 10.0),
          decoration: BoxDecoration(
            color: Color.fromRGBO(23, 23, 23, 1.0),
            border: Border.all(
              width: 1.0,
              color: Color.fromRGBO(40, 40, 40, 1.0),
            ),
            borderRadius: BorderRadius.all(Radius.circular(20.0)),
            boxShadow: [
              BoxShadow(
                blurRadius: 4.0,
                color: Color.fromRGBO(0, 0, 0, 0.5),
                offset: new Offset(0.0, 4.0),
              ),
            ],
          ),
          child: new Row(
            children: <Widget>[
              new Container(
                margin: EdgeInsets.only(left: 2.0),
                child: new CircleAvatar(
                  radius: 25.0,
                  backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                  child: new CircleAvatar(
                    radius: 23.0,
                    backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                    backgroundImage: NetworkImage(
                      user["userPicture"] != null
                          ? user["userPicture"]
                          : user["tournamentPicture"],
                    ),
                  ),
                ),
              ),
              new Expanded(
                child: new Container(
                  margin: EdgeInsets.fromLTRB(5.0, 5.0, 0.0, 5.0),
                  child: new RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        new TextSpan(
                          text: _fetchNotificationBody1(),
                          style: new TextStyle(
                          color: Colors.white,
                          fontSize: 17.0,
                          fontFamily: "Avenir",
                          fontWeight: notification["notificationType"] != "match" ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        new TextSpan(
                          text: " ",
                        ),
                        new TextSpan(
                          text: _fetchNotificationBody2(),
                          style: new TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontFamily: "Avenir",
                          fontWeight: notification["notificationType"] != "match" ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // new Text(
                  //   notification["notificationBody"],
                  //   maxLines: 2,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: new TextStyle(
                  //     color: Colors.white,
                  //     fontSize: 17.0,
                  //     fontFamily: "Avenir",
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                ),
              ),
              new Container(
                alignment: Alignment.topRight,
                padding: EdgeInsets.only(top: 5.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    new Container(
                      padding: EdgeInsets.only(right: 15.0),
                      child: new Text(
                        fetchTimeStamp(notification["notificationDate"].toDate()),
                        style: TextStyle(
                          color: Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 13.0,
                          fontFamily: "Avenir",
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    notification["notificationType"] == "tournament"
                        ? new Container(
                            child: new Row(
                              children: <Widget>[
                                new GestureDetector(
                                  child: new Container(
                                    color: Colors.transparent,
                                    child: new Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                  ),
                                  onTap: () {

                                    _handleTournamentRequest("confirm", notification);
                                  },
                                ),
                                new Container(width: 10.0),
                                new GestureDetector(
                                  child: new Container(
                                    margin: EdgeInsets.only(right: 10.0),
                                    color: Colors.transparent,
                                    child: new Icon(
                                      Icons.clear,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onTap: () async {
                                    _handleTournamentRequest("delete", notification);
                                  },
                                ),
                              ],
                            ),
                          )
                        : new Container(),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          String notificationType = notification["notificationType"];
          if (notificationType == "like" || notificationType == "repost") {
          } else if (notification["notificationType"] == "follow") {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => new ProfilePage(
                      userID: notification["notificationUserID"],
                      visitor: true,
                    ),
              ),
            );
          }
          // else if (notification["notificationType"] == "matchWin" || notification["notificationType"] == "matchLose" || notification["notificationType"] == "matchConflict") {
          //   Navigator.of(context).push(
          //     MaterialPageRoute(
          //       builder: (BuildContext context) => new TournamentDetailsPage(
          //             tournamentID: notification["notificationUserID"],
          //             tournamentInfo: ,
          //           ),
          //     ),
          //   );
          // }
        });
  }
}

class NotificationPlaceholder extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Container(
      height: 60.0,
      margin: EdgeInsets.only(top: 10.0),
      decoration: BoxDecoration(
        color: Color.fromRGBO(23, 23, 23, 1.0),
        border: Border.all(
          width: 1.0,
          color: Color.fromRGBO(40, 40, 40, 1.0),
        ),
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            blurRadius: 4.0,
            color: Color.fromRGBO(0, 0, 0, 0.5),
            offset: new Offset(0.0, 4.0),
          ),
        ],
      ),
      child: new Row(
        children: <Widget>[
          new Container(
            margin: EdgeInsets.only(left: 2.0),
            child: new CircleAvatar(
              radius: 25.0,
              backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
              child: new CircleAvatar(
                radius: 23.0,
                backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
              ),
            ),
          ),
          new Expanded(
            child: new Container(
              margin: EdgeInsets.fromLTRB(5.0, 30.0, 0.0, 5.0),
              color: Color.fromRGBO(40, 40, 40, 1.0),
              height: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}
