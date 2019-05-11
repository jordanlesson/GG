import 'package:flutter/material.dart';
import 'package:gg/globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gg/Components/tournament_details_page.dart';
import 'package:gg/Components/tournament_creation_page.dart';

class TournamentsPage extends StatefulWidget {
  _TournamentsPage createState() => new _TournamentsPage();
}

String _currentUser;

class _TournamentsPage extends State<TournamentsPage>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;
  bool sortMenuVisible;
  bool myTournamentsVisible;
  bool myTournamentsLoaded;
  bool savedTournamentsLoaded;
  List<String> myTournamentID;
  List<String> savedTournamentID;
  Map<dynamic, dynamic> sortedMyTournaments;
  Map<dynamic, dynamic> sortedSavedTournaments;
  List<Map<dynamic, dynamic>> myTournaments;
  List<Map<dynamic, dynamic>> savedTournaments;
  int myTournamentCount;
  int savedTournamentCount;

  initState() {
    super.initState();
    myTournamentsLoaded = false;
    savedTournamentsLoaded = false;
    if (globals.currentUser == null) {
      _fetchCurrentUser();
    } else {
      _currentUser = globals.currentUser;
      _fetchMyTournamentID();
      _fetchSavedTournamentID();
    }

    sortMenuVisible = false;
    myTournamentsVisible = true;
    controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    final CurvedAnimation curve =
        CurvedAnimation(parent: controller, curve: Curves.easeIn);
    animation = Tween(begin: 0.0, end: 100.0).animate(curve)
      ..addListener(() {
        setState(() {});
      });
  }

  _fetchCurrentUser() async {
    await FirebaseAuth.instance.currentUser().then((user) {
      if (user != null) {
        _currentUser = user.uid;
        _fetchMyTournamentID();
        _fetchSavedTournamentID();
      } else {
        print("error");
      }
    });
  }

  _fetchMyTournamentID() async {
    myTournamentID = [];
    sortedMyTournaments = {};
    int count = 0;
    await Firestore.instance.document("Users/$_currentUser").get().then(
      (tournament) {
        if (tournament.exists) {
          sortedMyTournaments = tournament.data["tournaments"];
          if (sortedMyTournaments != null) {
            sortedMyTournaments.forEach(
              (id, time) {
                sortedMyTournaments.update(
                    id, (epoch) => time.millisecondsSinceEpoch);
                count = count + 1;
                if (count == sortedMyTournaments.length) {
                  var sortedKeys = sortedMyTournaments.keys.toList(
                      growable: false) // SORTS POST IN CHRONOLOGICAL ORDER
                    ..sort((k1, k2) => sortedMyTournaments[k1]
                        .compareTo(sortedMyTournaments[k2]));
                  sortedMyTournaments = new Map.fromIterable(
                      sortedKeys.reversed,
                      key: (k) => k,
                      value: (k) => sortedMyTournaments[k]);
                  for (var id in sortedMyTournaments.keys) {
                    myTournamentID.add(id);
                    if (myTournamentID.length == sortedMyTournaments.length) {
                      myTournamentCount = myTournamentID.length;
                      _fetchMyTournaments();
                    }
                  }
                }
              },
            );
          }
        }
      },
    );
  }

  _fetchSavedTournamentID() async {
    savedTournamentID = [];
    sortedSavedTournaments = {};
    int count = 0;
    await Firestore.instance.document("Users/$_currentUser").get().then(
      (tournament) {
        if (tournament.exists) {
          sortedSavedTournaments = tournament.data["savedTournaments"];
          if (sortedSavedTournaments != null) {
            sortedSavedTournaments.forEach(
              (id, time) {
                sortedSavedTournaments.update(
                    id, (epoch) => time.millisecondsSinceEpoch);
                count = count + 1;
                if (count == sortedSavedTournaments.length) {
                  var sortedKeys = sortedSavedTournaments.keys.toList(
                      growable: false) // SORTS POST IN CHRONOLOGICAL ORDER
                    ..sort((k1, k2) => sortedSavedTournaments[k1]
                        .compareTo(sortedSavedTournaments[k2]));
                  sortedSavedTournaments = new Map.fromIterable(
                      sortedKeys.reversed,
                      key: (k) => k,
                      value: (k) => sortedSavedTournaments[k]);
                  for (var id in sortedSavedTournaments.keys) {
                    savedTournamentID.add(id);
                    if (savedTournamentID.length ==
                        sortedSavedTournaments.length) {
                      savedTournamentCount = savedTournamentID.length;
                      _fetchSavedTournaments();
                    }
                  }
                }
              },
            );
          }
        }
      },
    );
  }

  _fetchSavedTournaments() async {
    savedTournaments = [];
    for (String tournament in sortedSavedTournaments.keys) {
      var tournamentPicture;
      var tournamentBanner;
      bool tournamentPictureLoaded = false;
      bool tournamentBannerLoaded = false;
      Firestore.instance.document("Tournaments/$tournament").get().then(
        (tournamentInfo) {
          if (tournamentInfo.exists) {
            FirebaseStorage.instance
                .ref()
                .child("Tournaments/$tournament/picture/picture.png")
                .getData(1024 * 1024)
                .then(
              (_tournamentPicture) {
                if (_tournamentPicture != null) {
                  tournamentPicture = _tournamentPicture;
                  tournamentPictureLoaded = true;
                  if (tournamentPictureLoaded && tournamentBannerLoaded) {
                    List<dynamic> tournamentPlayers = new List<dynamic>.from(
                        tournamentInfo.data["tournamentPlayers"]);
                    List<dynamic> tournamentAdmins = new List<dynamic>.from(
                        tournamentInfo.data["tournamentAdmins"]);
                    savedTournaments.add({
                      tournamentInfo.documentID: {
                        "tournamentName": tournamentInfo.data["tournamentName"],
                        "tournamentAdmins": tournamentAdmins,
                        "tournamentGame": tournamentInfo.data["tournamentGame"],
                        "tournamentDate": tournamentInfo.data["tournamentDate"],
                        "tournamentBracketSize":
                            tournamentInfo.data["tournamentBracketSize"],
                        "tournamentPlayers": tournamentPlayers,
                        "tournamentMinTeamSize":
                            tournamentInfo.data["tournamentMinTeamSize"],
                        "tournamentMaxTeamSize":
                            tournamentInfo.data["tournamentMaxTeamSize"],
                        "tournamentRegion":
                            tournamentInfo.data["tournamentRegion"],
                        "tournamentRules":
                            tournamentInfo.data["tournamentRules"],
                        "tournamentPrivate":
                            tournamentInfo.data["tournamentPrivate"],
                        "tournamentDoubleElimination":
                            tournamentInfo.data["tournamentDoubleElimination"],
                        "tournamentPicture":
                            tournamentInfo.data["tournamentPicture"],
                        "tournamentPictureMemory": tournamentPicture,
                        "tournamentBanner":
                            tournamentInfo.data["tournamentBanner"],
                        "tournamentBannerMemory": tournamentBanner,
                      }
                    });
                    if (savedTournaments.length ==
                        sortedSavedTournaments.length) {
                      setState(() {
                        savedTournaments.insert(0, {"": ""});
                        savedTournamentID.insert(0, "element");
                        savedTournamentsLoaded = true;
                      });
                    }
                  }
                }
              },
            );
            FirebaseStorage.instance
                .ref()
                .child("Tournaments/$tournament/banner/banner.png")
                .getData(1024 * 1024)
                .then(
              (_tournamentBanner) {
                if (_tournamentBanner != null) {
                  tournamentBanner = _tournamentBanner;
                  tournamentBannerLoaded = true;
                  if (tournamentPictureLoaded && tournamentBannerLoaded) {
                    List<dynamic> tournamentPlayers = new List<dynamic>.from(
                        tournamentInfo.data["tournamentPlayers"]);
                    List<dynamic> tournamentAdmins = new List<dynamic>.from(
                        tournamentInfo.data["tournamentAdmins"]);
                    savedTournaments.add({
                      tournamentInfo.documentID: {
                        "tournamentName": tournamentInfo.data["tournamentName"],
                        "tournamentAdmins": tournamentAdmins,
                        "tournamentGame": tournamentInfo.data["tournamentGame"],
                        "tournamentDate": tournamentInfo.data["tournamentDate"],
                        "tournamentBracketSize":
                            tournamentInfo.data["tournamentBracketSize"],
                        "tournamentPlayers": tournamentPlayers,
                        "tournamentMinTeamSize":
                            tournamentInfo.data["tournamentMinTeamSize"],
                        "tournamentMaxTeamSize":
                            tournamentInfo.data["tournamentMaxTeamSize"],
                        "tournamentRegion":
                            tournamentInfo.data["tournamentRegion"],
                        "tournamentRules":
                            tournamentInfo.data["tournamentRules"],
                        "tournamentPrivate":
                            tournamentInfo.data["tournamentPrivate"],
                        "tournamentDoubleElimination":
                            tournamentInfo.data["tournamentDoubleElimination"],
                        "tournamentPicture":
                            tournamentInfo.data["tournamentPicture"],
                        "tournamentPictureMemory": tournamentPicture,
                        "tournamentBanner":
                            tournamentInfo.data["tournamentBanner"],
                        "tournamentBannerMemory": tournamentBanner,
                      }
                    });
                    if (savedTournaments.length ==
                        sortedSavedTournaments.length) {
                      setState(() {
                        savedTournaments.insert(0, {"": ""});
                        savedTournamentID.insert(0, "element");
                        savedTournamentsLoaded = true;
                      });
                    }
                  }
                }
              },
            );
          }
        },
      );
    }
  }

  _fetchMyTournaments() async {
    myTournaments = [];
    for (String tournament in sortedMyTournaments.keys) {
      var tournamentPicture;
      var tournamentBanner;
      bool tournamentPictureLoaded = false;
      bool tournamentBannerLoaded = false;
      Firestore.instance.document("Tournaments/$tournament").get().then(
        (tournamentInfo) {
          if (tournamentInfo.exists) {
            FirebaseStorage.instance
                .ref()
                .child("Tournaments/$tournament/picture/picture.png")
                .getData(1024 * 1024)
                .then(
              (_tournamentPicture) {
                if (_tournamentPicture != null) {
                  print("hello");
                  tournamentPicture = _tournamentPicture;
                  tournamentPictureLoaded = true;
                  if (tournamentPictureLoaded && tournamentBannerLoaded) {
                    List<dynamic> tournamentPlayers = new List<dynamic>.from(
                        tournamentInfo.data["tournamentPlayers"]);
                    List<dynamic> tournamentAdmins = new List<dynamic>.from(
                        tournamentInfo.data["tournamentAdmins"]);
                    myTournaments.add({
                      tournamentInfo.documentID: {
                        "tournamentName": tournamentInfo.data["tournamentName"],
                        "tournamentAdmins": tournamentAdmins,
                        "tournamentGame": tournamentInfo.data["tournamentGame"],
                        "tournamentDate": tournamentInfo.data["tournamentDate"],
                        "tournamentBracketSize":
                            tournamentInfo.data["tournamentBracketSize"],
                        "tournamentPlayers": tournamentPlayers,
                        "tournamentMinTeamSize":
                            tournamentInfo.data["tournamentMinTeamSize"],
                        "tournamentMaxTeamSize":
                            tournamentInfo.data["tournamentMaxTeamSize"],
                        "tournamentRegion":
                            tournamentInfo.data["tournamentRegion"],
                        "tournamentRules":
                            tournamentInfo.data["tournamentRules"],
                        "tournamentPrivate":
                            tournamentInfo.data["tournamentPrivate"],
                        "tournamentDoubleElimination":
                            tournamentInfo.data["tournamentDoubleElimination"],
                        "tournamentPicture":
                            tournamentInfo.data["tournamentPicture"],
                        "tournamentPictureMemory": tournamentPicture,
                        "tournamentBanner":
                            tournamentInfo.data["tournamentBanner"],
                        "tournamentBannerMemory": tournamentBanner,
                      }
                    });
                    if (myTournaments.length == sortedMyTournaments.length) {
                      print("gutentag");
                      setState(() {
                        myTournaments.insert(0, {"": ""});
                        myTournamentID.insert(0, "element");
                        myTournamentsLoaded = true;
                      });
                    }
                  }
                }
              },
            );
            FirebaseStorage.instance
                .ref()
                .child("Tournaments/$tournament/banner/banner.png")
                .getData(1024 * 1024)
                .then(
              (_tournamentBanner) {
                if (_tournamentBanner != null) {
                  tournamentBanner = _tournamentBanner;
                  tournamentBannerLoaded = true;
                  if (tournamentPictureLoaded && tournamentBannerLoaded) {
                    List<dynamic> tournamentPlayers = new List<dynamic>.from(
                        tournamentInfo.data["tournamentPlayers"]);
                    List<dynamic> tournamentAdmins = new List<dynamic>.from(
                        tournamentInfo.data["tournamentAdmins"]);
                    myTournaments.add({
                      tournamentInfo.documentID: {
                        "tournamentName": tournamentInfo.data["tournamentName"],
                        "tournamentAdmins": tournamentAdmins,
                        "tournamentGame": tournamentInfo.data["tournamentGame"],
                        "tournamentDate": tournamentInfo.data["tournamentDate"],
                        "tournamentBracketSize":
                            tournamentInfo.data["tournamentBracketSize"],
                        "tournamentPlayers": tournamentPlayers,
                        "tournamentMinTeamSize":
                            tournamentInfo.data["tournamentMinTeamSize"],
                        "tournamentMaxTeamSize":
                            tournamentInfo.data["tournamentMaxTeamSize"],
                        "tournamentRegion":
                            tournamentInfo.data["tournamentRegion"],
                        "tournamentRules":
                            tournamentInfo.data["tournamentRules"],
                        "tournamentPrivate":
                            tournamentInfo.data["tournamentPrivate"],
                        "tournamentDoubleElimination":
                            tournamentInfo.data["tournamentDoubleElimination"],
                        "tournamentPicture":
                            tournamentInfo.data["tournamentPicture"],
                        "tournamentPictureMemory": tournamentPicture,
                        "tournamentBanner":
                            tournamentInfo.data["tournamentBanner"],
                        "tournamentBannerMemory": tournamentBanner,
                      }
                    });
                    if (myTournaments.length == sortedMyTournaments.length) {
                      setState(() {
                        myTournaments.insert(0, {"": ""});
                        myTournamentID.insert(0, "element");
                        myTournamentsLoaded = true;
                      });
                    }
                  }
                }
              },
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Tournaments",
          style: new TextStyle(
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: new IconButton(
          icon: new Icon(
            Icons.sort,
            color: Colors.white,
            size: 25.0,
          ),
          onPressed: () {
            print("SORT");
            if (sortMenuVisible == true && controller.isCompleted) {
              setState(() {
                sortMenuVisible = false;
              });
            } else {
              controller.reset();
              controller.forward();
              sortMenuVisible = true;
            }
          },
        ),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(
              Icons.add_circle_outline,
              size: 25.0,
              color: Colors.white,
            ),
            onPressed: () {
              print("ADD TOURNAMENT");
              // showSearch(context: context, delegate: GameSearch());
            },
          )
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          new Container(
            child: myTournamentsLoaded != true || savedTournamentsLoaded != true
                ? new Center(
                    child: new CircularProgressIndicator(
                      backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                    ),
                  )
                : new ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      var myTournament =
                          myTournaments[index][myTournamentID[index]];
                      var savedTournament =
                          savedTournaments[index][savedTournamentID[index]];

                      fetchTime(DateTime date) {
                        String month;
                        String weekday;
                        String hour;
                        String minute;
                        String suffix;
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
                        if (date.hour > 12) {
                          hour = (date.hour - 12).toString();
                          suffix = "pm";
                        } else if (date.hour == 12) {
                          hour = date.hour.toString();
                          suffix = "pm";
                        } else if (date.hour == 0) {
                          hour = "12";
                          suffix = "am";
                        } else {
                          hour = date.hour.toString();
                          suffix = "am";
                        }

                        if (date.minute <= 10) {
                          minute = "0${date.minute}";
                        } else {
                          minute = date.minute.toString();
                        }

                        return "$weekday, $month ${date.day}, $hour:$minute$suffix ${date.timeZoneName}";
                      }

                      if (index == 0) {
                        return new Container(
                          height: 60.0,
                          color: Color.fromRGBO(23, 23, 23, 1.0),
                          alignment: Alignment.bottomLeft,
                          child: new Container(
                            margin: EdgeInsets.only(left: 10.0, bottom: 10.0),
                            child: new Text(
                              myTournamentsVisible
                                  ? "My Tournaments"
                                  : "Saved Tournaments",
                              style: new TextStyle(
                                color: Color.fromRGBO(170, 170, 170, 1.0),
                                fontSize: 17.0,
                                fontFamily: "Avenir",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return new GestureDetector(
                          child: Container(
                            height: 60.0,
                            margin: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 10.0),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(23, 23, 23, 1.0),
                              boxShadow: [
                                new BoxShadow(
                                  blurRadius: 4.0,
                                  color: Color.fromRGBO(0, 0, 0, 0.5),
                                  offset: new Offset(0.0, 4.0),
                                ),
                              ],
                              border: Border.all(
                                color: Color.fromRGBO(40, 40, 40, 1.0),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                            ),
                            child: new Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                new Container(
                                  margin: EdgeInsets.only(left: 2.0, top: 4.0),
                                  child: new CircleAvatar(
                                    backgroundColor:
                                        Color.fromRGBO(0, 150, 255, 1.0),
                                    radius: 25.0,
                                    child: new CircleAvatar(
                                      backgroundColor:
                                          Color.fromRGBO(50, 50, 50, 1.0),
                                      radius: 23.0,
                                      backgroundImage: CachedNetworkImageProvider(
                                        myTournamentsVisible
                                            ? myTournament["tournamentPicture"]
                                            : savedTournament[
                                                "tournamentPicture"],
                                      ),
                                    ),
                                  ),
                                ),
                                new Expanded(
                                  child: Container(
                                    child: new Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        new Expanded(
                                          child: new Container(
                                            margin: EdgeInsets.only(
                                                left: 5.0, top: 5.0),
                                            child: new Text(
                                              myTournamentsVisible
                                                  ? myTournament[
                                                      "tournamentName"]
                                                  : savedTournament[
                                                      "tournamentName"],
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
                                        new Container(
                                            margin: EdgeInsets.only(
                                                left: 5.0, bottom: 10.0),
                                            child: new Text(
                                              myTournamentsVisible
                                                  ? fetchTime(myTournament[
                                                      "tournamentDate"])
                                                  : fetchTime(savedTournament[
                                                      "tournamentDate"]),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                    170, 170, 170, 1.0),
                                                fontSize: 14.0,
                                                fontFamily: "Avenir",
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),),
                                      ],
                                    ),
                                  ),
                                ),
                                new Container(
                                  margin: EdgeInsets.only(
                                      top: 10.0, right: 15.0, left: 10.0),
                                  child: new Text(
                                    myTournamentsVisible
                                        ? myTournament["tournamentRegion"]
                                        : savedTournament["tournamentRegion"],
                                    style: new TextStyle(
                                      color: Color.fromRGBO(170, 170, 170, 1.0),
                                      fontSize: 13.0,
                                      fontFamily: "Avenir",
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    new TournamentDetailsPage(
                                      tournamentID: myTournamentsVisible
                                          ? myTournamentID[index]
                                          : savedTournamentID[index],
                                      tournamentInfo: myTournamentsVisible
                                          ? myTournament
                                          : savedTournament,
                                    ),
                              ),
                            );
                            print(myTournamentID[index]);
                            print(savedTournamentID[index]);
                          },
                        );
                      }
                    },
                    itemCount: myTournamentsVisible
                        ? myTournamentCount + 1
                        : savedTournamentCount + 1,
                  ),
          ),
          new Offstage(
            offstage: sortMenuVisible ? false : true,
            child: new Container(
              height: animation.value,
              width: 220.0,
              padding: EdgeInsets.only(left: 15.0, right: 15.0),
              margin: EdgeInsets.only(left: 20.0, top: 10.0),
              decoration: BoxDecoration(
                color: Color.fromRGBO(40, 40, 40, 1.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4.0,
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    offset: new Offset(0.0, 4.0),
                  ),
                ],
              ),
              child: new Column(
                children: <Widget>[
                  new Expanded(
                    child: new GestureDetector(
                      child: new Container(
                        //margin: EdgeInsets.only(left: 15.0),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(),
                        child: new Text(
                          "My Tournaments",
                          textScaleFactor: 1.0,
                          style: new TextStyle(
                              color: myTournamentsVisible
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        if (controller.isCompleted) {
                          setState(() {
                            sortMenuVisible = false;
                            if (myTournamentsVisible != true) {
                              myTournamentsVisible = !myTournamentsVisible;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  new Expanded(
                    child: new GestureDetector(
                      child: new Container(
                        //margin: EdgeInsets.only(left: 15.0),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(),
                        child: new Text(
                          "Saved Tournaments",
                          textScaleFactor: 1.0,
                          style: new TextStyle(
                            color: myTournamentsVisible != true
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 20.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        if (controller.isCompleted) {
                          setState(
                            () {
                              sortMenuVisible = false;
                              if (myTournamentsVisible == true) {
                                myTournamentsVisible = !myTournamentsVisible;
                              }
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
