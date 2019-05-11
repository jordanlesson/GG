import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gg/globals.dart' as globals;
import 'dart:io';
import 'package:gg/Components/master_page.dart';
import 'package:auto_size_text/auto_size_text.dart';

class TournamentOverviewPage extends StatefulWidget {
  _TournamentOverviewPage createState() => new _TournamentOverviewPage();

  final Map<dynamic, dynamic> tournamentInfo;

  TournamentOverviewPage({
    Key key,
    @required this.tournamentInfo,
  }) : super(key: key);
}

class _TournamentOverviewPage extends State<TournamentOverviewPage> {
  bool publishInProgress;
  Map<dynamic, dynamic> tournamentInfo;

  @override
  void initState() {
    super.initState();
    publishInProgress = false;
    tournamentInfo = Map.from(widget.tournamentInfo);
  }

  _publishTournament() async {
    tournamentInfo.addAll({
      "tournamentAdmins": [globals.currentUser],
      "tournamentPlayers": [globals.currentUser],
    });
    await Firestore.instance.collection("Tournaments").add({
      "tournamentAdmins": [globals.currentUser],
      "tournamentName": tournamentInfo["tournamentName"],
      "tournamentDate": tournamentInfo["tournamentDate"],
      "tournamentGame": tournamentInfo["tournamentGame"],
      "tournamentRegion": tournamentInfo["tournamentRegion"],
      "tournamentBracketSize": tournamentInfo["tournamentBracketSize"],
      "tournamentMinTeamSize": tournamentInfo["tournamentMinTeamSize"],
      "tournamentMaxTeamSize": tournamentInfo["tournamentMaxTeamSize"],
      "tournamentPlayers": [globals.currentUser],
      "tournamentPrivate": tournamentInfo["tournamentPrivate"],
      "tournamentDoubleElimination":
          tournamentInfo["tournamentDoubleElimination"],
      "tournamentRules": tournamentInfo["tournamentRules"],
      "tournamentRequests": [],
      "tournamentSaves": [],
    }).then((tournament) async {
      String pictureDownloadUrl;
      String bannerDownloadUrl;
      StorageReference pictureRef = FirebaseStorage.instance
          .ref()
          .child("Tournaments/${tournament.documentID}/picture/picture.png");
      pictureRef
          .putFile(tournamentInfo["tournamentPicture"])
          .onComplete
          .then((_) async {
        pictureDownloadUrl = await pictureRef.getDownloadURL();
        StorageReference bannerRef = FirebaseStorage.instance
            .ref()
            .child("Tournaments/${tournament.documentID}/banner/banner.png");
        bannerRef
            .putFile(tournamentInfo["tournamentBanner"])
            .onComplete
            .then((_) async {
          bannerDownloadUrl = await bannerRef.getDownloadURL();
          print(bannerDownloadUrl);
          Firestore.instance
              .document("Tournaments/${tournament.documentID}")
              .setData({
            "tournamentPicture": pictureDownloadUrl.toString(),
            "tournamentBanner": bannerDownloadUrl.toString()
          }, merge: true).then((_) {
            for (int i = 0;
                i < tournamentInfo["tournamentBracketSize"];
                i++) {
              int matchNumber = i + 1;
              Firestore.instance.collection("Matches").add({
                "matchNumber": matchNumber,
                "matchTournamentID": tournament.documentID,
                "matchTeamOne": "",
                "matchTeamTwo": "",
                "matchTeamOneWinner": "",
                "matchTeamTwoWinner": "",
                "matchConflict": false,
                "matchInProgress": false,
              }).then((_) {
                if (matchNumber == tournamentInfo["tournamentBracketSize"]) {
                  setState(() {
                    publishInProgress = false;
                    Navigator.of(context).popUntil(ModalRoute.withName("/TournamentsPage")); 
              });
            }
          });
                }
        });
      });
    });
    });
  }

  Widget build(BuildContext context) {
    return new Stack(
      children: <Widget>[
        new Scaffold(
          backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
          appBar: new AppBar(
            backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
            leading: publishInProgress
            ? new Icon(
                Icons.arrow_back_ios,
                color: Color.fromRGBO(170, 170, 170, 1.0),
              )
            : new BackButton(
                color: Color.fromRGBO(0, 150, 255, 1.0),
              ),
            title: new Text(
              "Overview",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: <Widget>[
              new GestureDetector(
                child: new Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(right: 10.0),
                  color: Colors.transparent,
                  child: new Text(
                    "Publish",
                    style: TextStyle(
                      color: Color.fromRGBO(0, 150, 255, 1.0),
                      fontSize: 20.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  if (publishInProgress != true) {
                    setState(() {
                      publishInProgress = true;
                      _publishTournament();
                    });
                  }
                },
              ),
            ],
            elevation: 0.0,
          ),
          body: new CustomScrollView(
            slivers: <Widget>[
              new SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: new Container(),
                flexibleSpace: new FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: new Stack(
                    children: <Widget>[
                      new Container(
                        child: new Column(
                          children: <Widget>[
                            new Container(
                              height: 160.0,
                              color: Color.fromRGBO(50, 50, 50, 1.0),
                              child: new Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  new Container(
                                    child: new Image(
                                      fit: BoxFit.cover,
                                      image: FileImage(
                                          tournamentInfo["tournamentBanner"]),
                                    ),
                                  ),
                                  new Align(
                                    alignment: Alignment.bottomCenter,
                                    child: new Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        new CircleAvatar(
                                          radius: 50.0,
                                          backgroundColor:
                                              Color.fromRGBO(0, 150, 255, 1.0),
                                          child: new CircleAvatar(
                                            radius: 46.0,
                                            backgroundColor:
                                                Color.fromRGBO(50, 50, 50, 1.0),
                                            backgroundImage: FileImage(
                                                tournamentInfo[
                                                    "tournamentPicture"]),
                                          ),
                                        ),
                                        new Container(
                                          margin: EdgeInsets.only(
                                              top: 2.0, bottom: 3.0),
                                          child: new Text(
                                            tournamentInfo["tournamentName"],
                                            style: new TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Century Gothic",
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                      new Container(
                        height: 160.0,
                      ),
                    ],
                  ),
                ),
                expandedHeight: 160.0,
              ),
              new SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    fetchDate(DateTime date) {
                      String month;
                      String weekday;
                      switch (date.month) {
                        case 1:
                          month = "Jan";
                          break;
                        case 2:
                          month = "Feb";
                          break;
                        case 3:
                          month = "Mar";
                          break;
                        case 4:
                          month = "Apr";
                          break;
                        case 5:
                          month = "May";
                          break;
                        case 6:
                          month = "Jun";
                          break;
                        case 7:
                          month = "Jul";
                          break;
                        case 8:
                          month = "Aug";
                          break;
                        case 9:
                          month = "Sep";
                          break;
                        case 10:
                          month = "Oct";
                          break;
                        case 11:
                          month = "Nov";
                          break;
                        case 12:
                          month = "Dec";
                          break;
                      }
                      switch (date.weekday) {
                        case 1:
                          weekday = "Mon";
                          break;
                        case 2:
                          weekday = "Tues";
                          break;
                        case 3:
                          weekday = "Wed";
                          break;
                        case 4:
                          weekday = "Thur";
                          break;
                        case 5:
                          weekday = "Fri";
                          break;
                        case 6:
                          weekday = "Sat";
                          break;
                        case 7:
                          weekday = "Sun";
                          break;
                      }

                      return "$weekday $month ${date.day}";
                    }

                    fetchTime(DateTime time) {
                      String hour;
                      String minute;
                      String suffix;

                      if (time.hour > 12) {
                        hour = (time.hour - 12).toString();
                        suffix = "pm";
                      } else if (time.hour == 12) {
                        hour = time.hour.toString();
                        suffix = "pm";
                      } else if (time.hour == 0) {
                        hour = "12";
                        suffix = "am";
                      } else {
                        hour = time.hour.toString();
                        suffix = "am";
                      }

                      if (time.minute <= 10) {
                        minute = "0${time.minute}";
                      } else {
                        minute = time.minute.toString();
                      }

                      return "$hour:$minute$suffix ${time.timeZoneName}";
                    }

                    tournamentDetail() {
                      switch (index) {
                        case 0:
                          return "Game";
                          break;
                        case 1:
                          return "Tournament Begins";
                          break;
                        case 2:
                          return "Bracket Size";
                          break;
                        case 3:
                          return "Team Size";
                          break;
                        case 4:
                          return "Region";
                          break;
                        case 5:
                          return "Status";
                          break;
                        case 6:
                          return "Rules";
                          break;
                      }
                    }

                    tournamentDetails() {
                      switch (index) {
                        case 0:
                          return tournamentInfo["tournamentGame"];
                          break;
                        case 2:
                          return tournamentInfo["tournamentDoubleElimination"]
                              ? "${tournamentInfo["tournamentBracketSize"]} Teams (Double Elim)"
                              : "${tournamentInfo["tournamentBracketSize"]} Teams (Single Elim)";
                          break;
                        case 3:
                          return "Min ${tournamentInfo["tournamentMinTeamSize"]} / Max ${tournamentInfo["tournamentMaxTeamSize"]}";
                          break;
                        case 4:
                          return tournamentInfo["tournamentRegion"];
                          break;
                        case 5:
                          return tournamentInfo["tournamentPrivate"]
                              ? "Private"
                              : "Public";
                          break;
                      }
                    }

                    if (index == 1) {
                      return new Container(
                        height: 50.0,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: new Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            new Expanded(
                              child: new Container(
                                margin: EdgeInsets.only(left: 15.0),
                                child: new AutoSizeText(
                                  tournamentDetail(),
                                  textAlign: TextAlign.start,
                                  style: new TextStyle(
                                    color: Color.fromRGBO(170, 170, 170, 1.0),
                                    fontSize: 17.0,
                                    fontFamily: "Century Gothic",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            new Container(
                              margin: EdgeInsets.only(right: 15.0),
                              child: new Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  new Text(
                                    fetchDate(tournamentInfo["tournamentDate"]),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    style: new TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontFamily: "Century Gothic",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  new Text(
                                    fetchTime(tournamentInfo["tournamentDate"]),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    style: new TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.0,
                                      fontFamily: "Century Gothic",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (index == 6) {
                      return new Container(
                        margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                        padding:
                            EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Container(
                              child: new Text(
                                tournamentDetail(),
                                textAlign: TextAlign.start,
                                style: new TextStyle(
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 17.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            new Container(
                              margin: EdgeInsets.only(top: 5.0),
                              child: new Text(
                                tournamentInfo["tournamentRules"],
                                textAlign: TextAlign.left,
                                style: new TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return new Container(
                      height: 50.0,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Color.fromRGBO(40, 40, 40, 1.0),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: new Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          new Expanded(
                            child: new Container(
                              margin: EdgeInsets.only(left: 15.0),
                              child: new Text(
                                tournamentDetail(),
                                textAlign: TextAlign.left,
                                maxLines: 1,
                                style: new TextStyle(
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 17.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          new Container(
                            margin: EdgeInsets.only(right: 15.0),
                            child: new AutoSizeText(
                              tournamentDetails(),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              minFontSize: 18.0,
                              maxFontSize: 20.0,
                              style: new TextStyle(
                                color: Colors.white,
                                fontFamily: "Century Gothic",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: 7,
                ),
              ),
            ],
          ),
        ),
        publishInProgress
            ? new Center(
                child: new CircularProgressIndicator(
                  backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                ),
              )
            : new Container(),
      ],
    );
  }
}
