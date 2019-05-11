import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gg/Components/user_list_page.dart';
import 'package:gg/UI/tournament_details_placeholder.dart';
import 'package:gradient_text/gradient_text.dart';
import 'dart:math';
import 'package:gg/globals.dart' as globals;
import 'tournament_creation_page.dart';
import 'match_details_page.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:io';
import 'team_creation_page.dart';
import 'package:gg/UI/match_box.dart';

class TournamentDetailsPage extends StatefulWidget {
  _TournamentDetailsPage createState() => new _TournamentDetailsPage();

  final String tournamentID;
  final Map<dynamic, dynamic> tournamentInfo;

  TournamentDetailsPage(
      {Key key, @required this.tournamentID, @required this.tournamentInfo})
      : super(key: key);
}

class _TournamentDetailsPage extends State<TournamentDetailsPage>
    with SingleTickerProviderStateMixin {
  int _currentIndex;
  Map<String, dynamic> tournamentInfo;
  Map<dynamic, dynamic> matchTeams;
  bool tournamentImagesLoaded = true;
  bool tournamentBracketLoaded;
  bool joined;
  bool requested;
  bool admin;
  bool full;
  List tournamentPlayers;
  List tournamentAdminID;
  List userTeams;
  String _currentUser;
  dynamic tournamentPicture;
  dynamic tournamentBanner;
  List<Map<int, dynamic>> matches;
  PageController winnersPageController;
  Animation roundIndexAnimation;
  AnimationController roundIndexAnimationController;
  int winnersRoundIndex;

  @override
  void initState() {
    super.initState();

    _fetchTournamentImages(widget.tournamentID);

    tournamentBracketLoaded = false;
    tournamentImagesLoaded = false;

    _currentIndex = 0;
    _currentUser = globals.currentUser;

    winnersPageController = PageController();

    tournamentInfo = Map.from(widget.tournamentInfo);

    full = tournamentInfo["tournamentPlayers"].length ==
        tournamentInfo["tournamentBracketSize"];
    joined = tournamentInfo["tournamentPlayers"].contains(_currentUser);
    requested = tournamentInfo["tournamentRequests"].contains(_currentUser);
    admin = tournamentInfo["tournamentAdmins"].contains(_currentUser);

    winnersRoundIndex = 1;
    roundIndexAnimationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    roundIndexAnimation =
        Tween(begin: 0.0, end: 1.0).animate(roundIndexAnimationController)
          ..addListener(() {
            setState(() {});
          });
    roundIndexAnimationController.forward();
  }

  _fetchTournamentImages(String tournamentID) async {
    FirebaseStorage.instance
        .ref()
        .child("Tournaments/$tournamentID/picture/picture.png")
        .getData(1024 * 1024)
        .then((tournamentMemoryPicture) {
      if (tournamentMemoryPicture.isNotEmpty) {
        tournamentPicture = tournamentMemoryPicture;
        FirebaseStorage.instance
            .ref()
            .child("Tournaments/$tournamentID/banner/banner.png")
            .getData(1024 * 1024)
            .then((tournamentMemoryBanner) {
          if (tournamentMemoryBanner.isNotEmpty) {
            tournamentBanner = tournamentMemoryBanner;
            _fetchUserTeams();
          }
        });
      }
    });
  }

  void _fetchUserTeams() async {
    userTeams = new List();
    Firestore.instance
        .collection("Teams")
        .where("teamUsers", arrayContains: _currentUser)
        .getDocuments()
        .then((teamDocuments) {
      if (teamDocuments.documents.isNotEmpty) {
        for (DocumentSnapshot team in teamDocuments.documents) {
          userTeams.add(team.documentID);
          if (userTeams.length == teamDocuments.documents.length) {
            if (tournamentInfo["tournamentPlayers"].contains(team.documentID)) {
              setState(() {
                joined = true;
              });
            }
            if (tournamentInfo["tournamentRequests"]
                .contains(team.documentID)) {
              setState(() {
                requested = true;
              });
            }
            setState(() {
              tournamentImagesLoaded = true;
            });
          }
        }
      } else {
        setState(() {
          tournamentImagesLoaded = true;
        });
      }
    });
  }

  _handleRequest(String team, bool requested) {
    try {
      if (requested) {
        List requests = List.from(tournamentInfo["tournamentRequests"]);
        requests.remove(team);
        setState(() {
          requested = false;
          tournamentInfo["tournamentRequests"] = requests;
        });
        tournamentInfo["tournamentRequests"].remove(team);
        Firestore.instance
            .document("Tournaments/${widget.tournamentID}")
            .get()
            .then((tournamentDetails) {
          if (tournamentDetails.exists) {
            List tournamentRequests =
                List.from(tournamentDetails.data["tournamentRequests"]);
            if (tournamentRequests.contains(team)) {
              tournamentRequests.remove(team);
              Firestore.instance
                  .document("Tournaments/${widget.tournamentID}")
                  .updateData({
                "tournamentRequests": tournamentRequests,
              });
            }
          }
        });
      } else {
        List requests = List.from(tournamentInfo["tournamentRequests"]);
        requests.add(team);
        setState(() {
          requested = true;
          tournamentInfo["tournamentRequests"] = requests;
        });
        Firestore.instance
            .document("Tournaments/${widget.tournamentID}")
            .get()
            .then((tournamentDetails) {
          if (tournamentDetails.exists) {
            List tournamentRequests =
                List.from(tournamentDetails.data["tournamentRequests"]);
            if (!tournamentRequests.contains(team)) {
              tournamentRequests.add(team);
              Firestore.instance
                  .document("Tournaments/${widget.tournamentID}")
                  .updateData({
                "tournamentRequests": tournamentRequests,
              });
            }
          }
        });
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  userTournamentStatus() {
    if (joined) {
      return "Joined";
    } else if (full) {
      return "Full";
    } else {
      if (!requested) {
        return "Join";
      } else {
        if (requested) {
          return "Requested";
        } else {
          return "Request";
        }
      }
    }
  }

  List<Widget> tournamentBracket(
      List userTeams, int bracketSize) {
    List<Widget> tournamentRoundPages = [
      TournamentBracket(
        currentIndex: _currentIndex,
        round: 1,
        tournamentInfo: tournamentInfo,
        tournamentID: widget.tournamentID,
        userTeams: userTeams,
        key: PageStorageKey<String>("roundOne"),
      ),
      TournamentBracket(
        currentIndex: _currentIndex,
        round: 2,
        tournamentInfo: tournamentInfo,
        tournamentID: widget.tournamentID,
        userTeams: userTeams,
        key: PageStorageKey<String>("roundTwo"),
      ),
      TournamentBracket(
        currentIndex: _currentIndex,
        round: 3,
        tournamentInfo: tournamentInfo,
        tournamentID: widget.tournamentID,
        userTeams: userTeams,
        key: PageStorageKey<String>("roundThree"),
      ),
      TournamentBracket(
        currentIndex: _currentIndex,
        round: 4,
        tournamentInfo: tournamentInfo,
        tournamentID: widget.tournamentID,
        userTeams: userTeams,
        key: PageStorageKey<String>("roundFour"),
      ),
    ];

    if (bracketSize > 8) {
      return tournamentRoundPages;
    } else if (bracketSize > 4) {
      return tournamentRoundPages.take(3).toList();
    } else if (bracketSize > 2) {
      return tournamentRoundPages.take(2).toList();
    }
    return tournamentRoundPages.take(1).toList();
  }

  _handleMatchSetUp(String teamID) async {
    Firestore.instance
        .collection("Matches")
        .where("matchTournamentID", isEqualTo: widget.tournamentID)
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

  void _handleTournamentJoin(String teamID) async {
    setState(() {
      joined = true;
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance
                .document("Tournaments/${widget.tournamentID}"))
            .then((tournamentInfo) async {
          if (tournamentInfo.exists) {
            List tournamentPlayers =
                List.from(tournamentInfo.data["tournamentPlayers"]);
            if (!tournamentPlayers.contains(teamID)) {
              tournamentPlayers.add(teamID);
            }
            await transaction.update(
                Firestore.instance
                    .document("Tournaments/${widget.tournamentID}"),
                <String, dynamic>{
                  "tournamentPlayers": tournamentPlayers,
                }).then((_) {
              _handleMatchSetUp(teamID);
            });
          }
        });
      });
    });
  }

  leaveTournament(String currentUser) async {
    String teamID;
    setState(() {
      joined = false;
      List<dynamic> updatedPlayers =
          List.from(tournamentInfo["tournamentPlayers"]);
          if (updatedPlayers.contains(currentUser)) {
            teamID = currentUser;
          } else {
            for (String team in userTeams) {
              if (updatedPlayers.contains(team)) {
                teamID = team;
              }
            }
          }
          print(teamID);
      updatedPlayers.remove(teamID);
      tournamentInfo.update("tournamentPlayers", (_) => updatedPlayers);
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance
                .document("Tournaments/${widget.tournamentID}"))
            .then((tournamentInfo) async {
          if (tournamentInfo.exists) {
            await transaction.update(
                Firestore.instance
                    .document("Tournaments/${widget.tournamentID}"),
                <String, dynamic>{
                  "tournamentPlayers": updatedPlayers,
                });
          }
        });
      });
    });
    try {
      final QuerySnapshot matchTeamOne = await Firestore.instance
          .collection("Matches")
          .where("matchTournamentID", isEqualTo: widget.tournamentID)
          .where("matchTeamOne", isEqualTo: teamID)
          .getDocuments();
      final QuerySnapshot matchTeamTwo = await Firestore.instance
          .collection("Matches")
          .where("matchTournamentID", isEqualTo: widget.tournamentID)
          .where("matchTeamTwo", isEqualTo: teamID)
          .getDocuments();
      if (matchTeamOne.documents.length + matchTeamTwo.documents.length == 1) {
        if (matchTeamOne.documents.length == 1) {
          Firestore.instance
              .document("Matches/${matchTeamOne.documents[0].documentID}")
              .updateData({"matchTeamOne": ""});
          // _fetchTournamentBracket();
        } else if (matchTeamTwo.documents.length == 1) {
          Firestore.instance
              .document("Matches/${matchTeamTwo.documents[0].documentID}")
              .updateData({"matchTeamTwo": ""});
          // _fetchTournamentBracket();
        }
      }
    } catch (error) {
      print("Error: $error");
    }
  }

  _selectTeam(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return TeamJoinDialog(
          currentUser: globals.currentUser,
        );
      },
    ).then(
      (teamID) {
        print(teamID);

        if (teamID != null) {
          if (tournamentInfo["tournamentPrivate"] != true) {
            _handleTournamentJoin(teamID);
          } else {
            _handleRequest(
                teamID, tournamentInfo["tournamentRequests"].contains(teamID));
          }
        }
      },
    );
  }

  _handleTournamentSave(bool tournamentSaved) {
    List saves = List.from(tournamentInfo["tournamentSaves"]);
    if (tournamentSaved) {
      setState(() {
        saves.remove(_currentUser);
        tournamentInfo["tournamentSaves"] = saves;
      });
      Firestore.instance
          .document("Tournaments/${widget.tournamentID}")
          .get()
          .then((tournamentDetails) {
        if (tournamentDetails.exists) {
          List tournamentSaves =
              List.from(tournamentDetails.data["tournamentSaves"]);
          if (tournamentSaves.contains(_currentUser)) {
            tournamentSaves.remove(_currentUser);
            Firestore.instance
                .document("Tournaments/${widget.tournamentID}")
                .updateData({"tournamentSaves": tournamentSaves});
          }
        }
      });
    } else {
      setState(() {
        saves.add(_currentUser);
        tournamentInfo["tournamentSaves"] = saves;
      });
      Firestore.instance
          .document("Tournaments/${widget.tournamentID}")
          .get()
          .then((tournamentDetails) {
        if (tournamentDetails.exists) {
          List tournamentSaves =
              List.from(tournamentDetails.data["tournamentSaves"]);
          if (!tournamentSaves.contains(_currentUser)) {
            tournamentSaves.add(_currentUser);
            Firestore.instance
                .document("Tournaments/${widget.tournamentID}")
                .updateData({"tournamentSaves": tournamentSaves});
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new StreamBuilder(
        stream: Firestore.instance
            .document("Tournaments/${widget.tournamentID}")
            .snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot> tournamentSnapshot) {
          Map<String, dynamic> tournament;

          if (tournamentSnapshot.hasData) {
            tournament = tournamentSnapshot.data.data;
            tournamentInfo = Map.from(tournament);
            full = tournament["tournamentPlayers"].length ==
                tournamentInfo["tournamentBracketSize"];
            joined = tournament["tournamentPlayers"].contains(_currentUser);
            requested = tournament["tournamentRequests"].contains(_currentUser);
            admin = tournament["tournamentAdmins"].contains(_currentUser);

            if (tournamentImagesLoaded) {
              for (String team in userTeams) {
                if (tournament["tournamentPlayers"].contains(team)) {
                  joined = true;
                }
                if (tournament["tournamentRequests"].contains(team)) {
                  requested = true;
                }
              }
            }
          }

          return new Scaffold(
            backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
            resizeToAvoidBottomPadding: false,
            body: new Column(
              children: <Widget>[
                new Container(
                  color: Colors.transparent,
                  child: new Stack(
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
                                    child: tournamentImagesLoaded
                                        ? new Image.memory(
                                            tournamentBanner,
                                            fit: BoxFit.cover,
                                          )
                                        : new Container(),
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
                                            backgroundImage:
                                                tournamentImagesLoaded
                                                    ? new MemoryImage(
                                                        tournamentPicture,
                                                      )
                                                    : new NetworkImage(""),
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
                        color: Colors.transparent,
                        child: new AppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0.0,
                          leading: new BackButton(
                            color: Color.fromRGBO(0, 150, 255, 1.0),
                          ),
                          actions: <Widget>[
                            tournamentImagesLoaded && DateTime.now().isBefore(tournamentInfo["tournamentDate"].toDate())
                                ? new Container(
                                    margin: EdgeInsets.only(right: 10.0),
                                    alignment: Alignment.center,
                                    child: new GestureDetector(
                                        child: new Container(
                                          alignment: Alignment.center,
                                          child: new Text(
                                            userTournamentStatus(),
                                            style: new TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.0,
                                              fontFamily: "Century Gothic",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          decoration: BoxDecoration(
                                              color: joined || requested
                                                  ? Color.fromRGBO(
                                                      137, 145, 151, 1.0)
                                                  : Color.fromRGBO(
                                                      0, 150, 255, 1.0),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(2.0))),
                                          height: 25.0,
                                          width: 85.0,
                                        ),
                                        onTap: () {
                                          if (!full) {
                                            if (joined) {
                                              leaveTournament(_currentUser);
                                            } else if (requested) {
                                              _handleRequest(
                                                  _currentUser, requested);
                                            } else if (tournamentInfo[
                                                        "tournamentMinTeamSize"] ==
                                                    1 &&
                                                tournamentInfo[
                                                        "tournamentMaxTeamSize"] ==
                                                    1) {
                                              if (tournamentInfo[
                                                      "tournamentPrivate"] !=
                                                  true) {
                                                _handleTournamentJoin(
                                                    _currentUser);
                                              } else {
                                                _handleRequest(
                                                    _currentUser, requested);
                                              }
                                            } else {
                                              _selectTeam(context);
                                            }
                                          }
                                        }),
                                  )
                                : new Container(),
                            joined || admin
                                ? new GestureDetector(
                                    child: new Container(
                                      margin: EdgeInsets.only(right: 10.0),
                                      alignment: Alignment.center,
                                      child: new Container(
                                        height: 25.0,
                                        width: 25.0,
                                        decoration: BoxDecoration(
                                          color:
                                              Color.fromRGBO(0, 150, 255, 1.0),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2.0)),
                                        ),
                                        child: new Icon(
                                          Icons.people,
                                          size: 20.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      print("PLAYERS");
                                      if (joined || admin) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                new UserListPage(
                                                  title: "Players",
                                                  id: widget.tournamentID,
                                                  tournamentPlayers:
                                                      tournamentInfo[
                                                          "tournamentPlayers"],
                                                  tournamentAdmins:
                                                      tournamentInfo[
                                                          "tournamentAdmins"],
                                                  currentUser: _currentUser,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                : new GestureDetector(
                                    child: new Container(
                                      margin: EdgeInsets.only(right: 10.0),
                                      alignment: Alignment.center,
                                      child: new Container(
                                        height: 25.0,
                                        width: 25.0,
                                        decoration: BoxDecoration(
                                          color:
                                              tournamentInfo["tournamentSaves"]
                                                      .contains(_currentUser)
                                                  ? Color.fromRGBO(
                                                      137, 145, 151, 1.0)
                                                  : Color.fromRGBO(
                                                      0, 150, 255, 1.0),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(2.0)),
                                        ),
                                        child: new Icon(
                                          Icons.save_alt,
                                          size: 20.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      print("PLAYERS");
                                      _handleTournamentSave(
                                          tournamentInfo["tournamentSaves"]
                                              .contains(_currentUser));
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  height: 50.0,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 1.0,
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                  ),
                  child: new Stack(
                    children: <Widget>[
                      new Container(
                        margin: EdgeInsets.only(left: 20.0, right: 20.0),
                        constraints: BoxConstraints(maxWidth: 350.0),
                        alignment: Alignment.center,
                        child: new CupertinoSegmentedControl(
                          groupValue: _currentIndex,
                          pressedColor: Color.fromRGBO(0, 150, 255, 1.0),
                          selectedColor: Color.fromRGBO(0, 150, 255, 1.0),
                          unselectedColor: Colors.transparent,
                          borderColor: Color.fromRGBO(0, 150, 255, 1.0),
                          onValueChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          children: {
                            0: new Container(
                              padding: EdgeInsets.only(left: 10.0, right: 10.0),
                              child: new Text(
                                "Tournament Info",
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
                              alignment: Alignment.center,
                              padding: EdgeInsets.only(left: 10.0, right: 10.0),
                              child: Text(
                                "Bracket",
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
                      admin &&
                              !DateTime.now().isAfter(
                                  tournamentInfo["tournamentDate"].toDate())
                          ? new Align(
                              alignment: Alignment.centerRight,
                              child: new IconButton(
                                icon: Icon(
                                  Icons.settings,
                                  size: 30.0,
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                ),
                                onPressed: () {
                                  print("SETTINGS");
                                  Directory tempDir = Directory.systemTemp;
                                  String pictureFileName =
                                      "tournamentPicture.png";
                                  String bannerFileName =
                                      "tournamentBanner.png";
                                  File pictureFile =
                                      File("${tempDir.path}/$pictureFileName");
                                  File bannerFile =
                                      File("${tempDir.path}/$bannerFileName");
                                  pictureFile.writeAsBytes(tournamentPicture,
                                      mode: FileMode.write);
                                  bannerFile.writeAsBytes(tournamentBanner,
                                      mode: FileMode.write);
                                  tournamentInfo.addAll({
                                    "tournamentPicture": pictureFile,
                                    "tournamentBanner": bannerFile,
                                  });
                                  print(tournamentInfo);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          new TournamentCreationPage(
                                            pageType: "Settings",
                                            tournamentID: widget.tournamentID,
                                            tournamentInfo: tournamentInfo,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : new Container(),
                    ],
                  ),
                ),
                new Expanded(
                  child: new Container(
                      child: _currentIndex == 0
                          ? new TournamentInfo(
                              tournamentInfo: tournamentInfo,
                            )
                          : new Column(
                              children: <Widget>[
                                new Expanded(
                                  child: tournamentImagesLoaded
                                      ? new PageView(
                                          key: PageStorageKey<String>(
                                              "winnersBracket"),
                                          onPageChanged: (roundIndex) {
                                            setState(() {
                                              winnersRoundIndex =
                                                  roundIndex + 1;
                                              roundIndexAnimationController
                                                  .reset();
                                              roundIndexAnimationController
                                                  .forward();
                                            });
                                          },
                                          controller: winnersPageController,
                                          children: tournamentBracket(
                                              userTeams,
                                              tournamentInfo[
                                                  "tournamentBracketSize"]),
                                        )
                                      : new Center(
                                          child: new Text(
                                            "Loading Teams",
                                            style: TextStyle(
                                              color: Color.fromRGBO(
                                                  170, 170, 170, 1.0),
                                              fontSize: 20.0,
                                              fontFamily: "Century Gothic",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                                new SafeArea(
                                  top: false,
                                  child: new Container(
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(23, 23, 23, 1.0),
                                      border: Border(
                                        top: BorderSide(
                                          width: 1.0,
                                          color:
                                              Color.fromRGBO(40, 40, 40, 1.0),
                                        ),
                                      ),
                                    ),
                                    child: new Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        new GestureDetector(
                                          child: new Container(
                                            alignment: Alignment.center,
                                            color: Colors.transparent,
                                            child: new Icon(
                                              Icons.arrow_left,
                                              size: 40.0,
                                              color: winnersRoundIndex != 1
                                                  ? Color.fromRGBO(
                                                      0, 150, 255, 1.0)
                                                  : Color.fromRGBO(
                                                      170, 170, 170, 1.0),
                                            ),
                                          ),
                                          onTap: () {
                                            if (winnersRoundIndex != 1) {
                                              setState(() {
                                                winnersPageController
                                                    .previousPage(
                                                        duration: Duration(
                                                            milliseconds: 300),
                                                        curve: Curves.easeOut);
                                              });
                                            }
                                          },
                                        ),
                                        new Opacity(
                                          opacity: roundIndexAnimation.value,
                                          child: new Text(
                                            "Round ${winnersRoundIndex.toString()}",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20.0,
                                                fontFamily: "Century Gothic",
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        new GestureDetector(
                                          child: new Container(
                                            alignment: Alignment.center,
                                            color: Colors.transparent,
                                            child: new Icon(
                                              Icons.arrow_right,
                                              size: 40.0,
                                              color: pow(2, winnersRoundIndex) <
                                                      tournamentInfo[
                                                          "tournamentBracketSize"]
                                                  ? Color.fromRGBO(
                                                      0, 150, 255, 1.0)
                                                  : Color.fromRGBO(
                                                      170, 170, 170, 1.0),
                                            ),
                                          ),
                                          onTap: () {
                                            if (pow(2, winnersRoundIndex) <
                                                tournamentInfo[
                                                    "tournamentBracketSize"]) {
                                              setState(() {
                                                winnersPageController.nextPage(
                                                    duration: Duration(
                                                        milliseconds: 300),
                                                    curve: Curves.easeOut);
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )),
                ),
              ],
            ),
          );
        });
  }
}

class TournamentInfo extends StatefulWidget {
  _TournamentInfo createState() => new _TournamentInfo();

  final Map<String, dynamic> tournamentInfo;

  TournamentInfo({Key key, @required this.tournamentInfo}) : super(key: key);
}

class _TournamentInfo extends State<TournamentInfo> {
  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(top: 0.0),
      itemBuilder: (BuildContext context, int index) {
        tournamentDetails() {
          List tournamentPlayers =
              List.from(widget.tournamentInfo["tournamentPlayers"]);
          switch (index) {
            case 0:
              return widget.tournamentInfo["tournamentGame"];
              break;
            case 2:
              return widget.tournamentInfo["tournamentDoubleElimination"] !=
                      true
                  ? "${widget.tournamentInfo["tournamentBracketSize"]} Teams (Single Elim)"
                  : "${widget.tournamentInfo["tournamentBracketSize"]} Teams (Double Elim)";
              break;
            case 3:
              return tournamentPlayers.length.toString();
              break;
            case 4:
              return "Min ${widget.tournamentInfo["tournamentMinTeamSize"]} / Max ${widget.tournamentInfo["tournamentMaxTeamSize"]}";
              break;
            case 5:
              return widget.tournamentInfo["tournamentRegion"];
              break;
          }
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
              return "Teams Joined";
              break;
            case 4:
              return "Team Size";
              break;
            case 5:
              return "Region";
              break;
            case 6:
              return "Rules";
              break;
          }
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

        if (index == 1) {
          return new Container(
            height: 50.0,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color.fromRGBO(40, 40, 40, 1.0),
                  width: 0.0,
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new Text(
                        fetchDate(
                            widget.tournamentInfo["tournamentDate"].toDate()),
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
                        fetchTime(
                            widget.tournamentInfo["tournamentDate"].toDate()),
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
            padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 10.0),
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
                    widget.tournamentInfo["tournamentRules"].toString(),
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
            border: index == 0
                ? null
                : Border(
                    top: BorderSide(
                        width: 1.0, color: Color.fromRGBO(40, 40, 40, 1.0)),
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
      itemCount: 7,
    );
  }
}

class TournamentBracket extends StatefulWidget {
  _TournamentBracket createState() => new _TournamentBracket();

  final int currentIndex;
  final int round;
  String tournamentID;
  final Map<String, dynamic> tournamentInfo;
  final List userTeams;

  TournamentBracket(
      {Key key,
      @required this.currentIndex,
      @required this.round,
      @required this.tournamentID,
      @required this.tournamentInfo,
      @required this.userTeams})
      : super(key: key);
}

class _TournamentBracket extends State<TournamentBracket> {
  int tournamentBracketSize;
  int matchInitialIndex;
  int matchLastIndex;
  List<DocumentSnapshot> matches;
  bool matchTeamOneLoaded;
  bool matchTeamTwoLoaded;

  @override
  void initState() {
    super.initState();

    matchTeamOneLoaded = false;
    matchTeamTwoLoaded = false;

    tournamentBracketSize = widget.tournamentInfo["tournamentBracketSize"];
    if (widget.round == 1) {
      matchInitialIndex = 1;
      matchLastIndex = (tournamentBracketSize / 2).ceil();
    } else if (widget.round == 2) {
      matchInitialIndex = 1 + (tournamentBracketSize / 2).ceil();
      matchLastIndex = (tournamentBracketSize / 2).ceil() +
          (tournamentBracketSize / 4).ceil();
    } else if (widget.round == 3) {
      matchInitialIndex = 1 +
          (tournamentBracketSize / 2).ceil() +
          (tournamentBracketSize / 4).ceil();
      matchLastIndex = (tournamentBracketSize / 2).ceil() +
          (tournamentBracketSize / 4).ceil() +
          (tournamentBracketSize / 8).ceil();
    } else if (widget.round == 4) {
      matchInitialIndex = 1 +
          (tournamentBracketSize / 2).ceil() +
          (tournamentBracketSize / 4).ceil() +
          (tournamentBracketSize / 8).ceil();
      matchLastIndex = matchInitialIndex;

    }
  }

  Stream<DocumentSnapshot> _fetchStream(String matchTeamID) {
    Firestore.instance.document("Users/$matchTeamID").get().then((userInfo) {
      if (userInfo.exists) {
        return Firestore.instance.document("Users/$matchTeamID").snapshots();
      } else {
        return Firestore.instance.document("Teams/$matchTeamID").snapshots();
      }
    });
    return Stream.empty();
  }

  @override
  Widget build(BuildContext context) {
    return new StreamBuilder(
      stream: Firestore.instance
          .collection("Matches")
          .where("matchTournamentID", isEqualTo: widget.tournamentID)
          .orderBy("matchNumber")
          .snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<QuerySnapshot> matchSnapshot) {
        if (!matchSnapshot.hasData) {
          return new Center(
              child: new Text(
            "Loading Bracket...",
            style: TextStyle(
                color: Color.fromRGBO(170, 170, 170, 1.0),
                fontSize: 20.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold),
          ));
        } else {
          if (matchSnapshot.data.documents.isNotEmpty) {
            return new ListView.builder(
              padding: EdgeInsets.only(top: 0.0, bottom: 10.0),
              itemBuilder: (BuildContext context, int index) {
                Map<String, dynamic> match =
                    matchSnapshot.data.documents[index].data;
                if (match["matchNumber"] >= matchInitialIndex &&
                    match["matchNumber"] <= matchLastIndex) {
                  return MatchBox(
                    currentUser: globals.currentUser,
                    match: match,
                    matchID: matchSnapshot.data.documents[index].documentID,
                    userTeams: widget.userTeams,
                    tournamentInfo: widget.tournamentInfo,
                  );
                }
                return new Container();
              },
              itemCount: matchLastIndex,
            );
          } else {
            return new Center(
                child: new Text(
              "No Matches Yet",
              style: TextStyle(
                  color: Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold),
            ));
          }
        }
      },
    );
  }
}

class TeamJoinDialog extends StatefulWidget {
  _TeamJoinDialog createState() => new _TeamJoinDialog();

  final String currentUser;

  TeamJoinDialog({Key key, @required this.currentUser}) : super(key: key);
}

class _TeamJoinDialog extends State<TeamJoinDialog> {
  String selectedTeamID;
  int selectedTeam;
  bool _solo;

  @override
  void initState() {
    super.initState();
    _solo = false;
  }

  Widget build(BuildContext context) {
    return new Center(
      child: new Material(
        color: Color.fromRGBO(23, 23, 23, 1.0),
        type: MaterialType.transparency,
        child: new Container(
          height: 250.0,
          margin: EdgeInsets.symmetric(horizontal: 40.0),
          constraints: BoxConstraints(maxWidth: 350.0),
          decoration: BoxDecoration(
            color: Color.fromRGBO(23, 23, 23, 1.0),
            border:
                Border.all(width: 1.0, color: Color.fromRGBO(0, 150, 255, 1.0)),
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
                    "Pick a Team",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontFamily: "Century Gothic",
                        fontWeight: FontWeight.bold),
                  )),
              new Container(
                padding: EdgeInsets.only(top: 10.0, left: 5.0),
                height: 100.0,
                alignment: Alignment.center,
                child: new Row(
                  children: <Widget>[
                    new GestureDetector(
                      child: new Container(
                        margin: EdgeInsets.only(right: 10.0),
                        padding: EdgeInsets.all(5.0),
                        color: Colors.transparent,
                        child: new Column(
                          children: <Widget>[
                            new CircleAvatar(
                              radius: 30.0,
                              backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                              child: new CircleAvatar(
                                radius: 27.0,
                                backgroundColor:
                                    Color.fromRGBO(50, 50, 50, 1.0),
                                child: new Container(
                                  child: new Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 40.0,
                                  ),
                                ),
                              ),
                            ),
                            new Expanded(
                              child: new Container(
                                alignment: Alignment.center,
                                child: new AutoSizeText(
                                  "Create a Team",
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.clip,
                                  maxLines: 2,
                                  minFontSize: 10.0,
                                  maxFontSize: 12.0,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                    fontFamily: "Century Gothic",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedTeam = null;
                          selectedTeamID = null;
                          if (_solo) {
                            _solo = false;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  new TeamCreationPage(
                                    currentUser: globals.currentUser,
                                  ),
                            ),
                          );
                        });
                      },
                    ),
                    new StreamBuilder(
                      stream: Firestore.instance
                          .collection("Teams")
                          .where("teamUsers",
                              arrayContains: globals.currentUser)
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> teamSnapshot) {
                        if (!teamSnapshot.hasData) {
                          return new CircularProgressIndicator(
                            backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                          );
                        } else {
                          return new Expanded(
                            child: new ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemExtent: 100.0,
                              itemBuilder: (BuildContext context, int index) {
                                Map<dynamic, dynamic> team = teamSnapshot
                                    .data.documents.reversed
                                    .toList()[index]
                                    .data;

                                return new GestureDetector(
                                  child: new Container(
                                    margin: EdgeInsets.only(right: 10.0),
                                    padding: EdgeInsets.all(5.0),
                                    color: index == selectedTeam
                                        ? Color.fromRGBO(50, 50, 50, 0.3)
                                        : Colors.transparent,
                                    child: new Column(
                                      children: <Widget>[
                                        new CircleAvatar(
                                          radius: 30.0,
                                          backgroundColor:
                                              Color.fromRGBO(0, 150, 255, 1.0),
                                          child: new CircleAvatar(
                                            radius: 27.0,
                                            backgroundColor:
                                                Color.fromRGBO(50, 50, 50, 1.0),
                                            backgroundImage:
                                                CachedNetworkImageProvider(
                                              team["teamPicture"],
                                            ),
                                          ),
                                        ),
                                        new Expanded(
                                          child: new Container(
                                            alignment: Alignment.center,
                                            child: new AutoSizeText(
                                              team["teamName"],
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.clip,
                                              maxLines: 2,
                                              minFontSize: 10.0,
                                              maxFontSize: 12.0,
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                    170, 170, 170, 1.0),
                                                fontSize: 12.0,
                                                fontFamily: "Century Gothic",
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      if (selectedTeam != index) {
                                        selectedTeam = index;
                                        selectedTeamID = teamSnapshot
                                            .data.documents.reversed
                                            .toList()[index]
                                            .documentID;
                                      }
                                      if (_solo) {
                                        _solo = false;
                                      }
                                    });
                                  },
                                );
                              },
                              itemCount: teamSnapshot.data.documents.length,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              new Container(
                height: 50.0,
                alignment: Alignment.bottomLeft,
                padding: EdgeInsets.only(left: 10.0),
                child: new Row(
                  children: <Widget>[
                    new Text(
                      "Join Solo",
                      style: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 20.0,
                        fontFamily: "Century Gothic",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    new Container(
                      margin: EdgeInsets.only(left: 10.0),
                      child: new CupertinoSwitch(
                        value: _solo,
                        activeColor: Color.fromRGBO(0, 150, 255, 1.0),
                        onChanged: (value) {
                          setState(() {
                            _solo = value;
                            if (selectedTeam != null) {
                              selectedTeam = null;
                              selectedTeamID = null;
                            }
                          });
                        },
                      ),
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
                              "JOIN",
                              style: TextStyle(
                                color: _solo || selectedTeam != null
                                    ? Color.fromRGBO(0, 150, 255, 1.0)
                                    : Color.fromRGBO(170, 170, 170, 1.0),
                                fontSize: 15.0,
                                fontFamily: "Avenir Next",
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                        onTap: () {
                          if (_solo) {
                            Navigator.of(context, rootNavigator: true)
                                .pop(widget.currentUser);
                          } else if (selectedTeam != null) {
                            Navigator.of(context).pop(selectedTeamID);
                          }
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
