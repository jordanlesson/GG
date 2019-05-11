import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'tournament_creation_page.dart';
import 'tournament_details_page.dart';
import 'package:gg/UI/tournament_box.dart';
import 'package:gg/UI/team_box.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'team_creation_page.dart';

class TournamentsPage extends StatefulWidget {
  _TournamentsPage createState() => new _TournamentsPage();

  final String currentUser;

  TournamentsPage({Key key, @required this.currentUser}) : super(key: key);
}

class _TournamentsPage extends State<TournamentsPage>
    with SingleTickerProviderStateMixin {
  String _currentUser;
  Animation sortMenuAnimation;
  AnimationController sortMenuAnimationController;
  bool sortMenuVisible;
  String sortMenuIndex;
  Stream<QuerySnapshot> tournamentPlayerStream;
  Stream<QuerySnapshot> tournamentSavedStream;
  Stream<QuerySnapshot> tournamentAdminStream;
  Stream<QuerySnapshot> teamStream;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    sortMenuAnimationController = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    final CurvedAnimation curve = CurvedAnimation(
        parent: sortMenuAnimationController, curve: Curves.easeIn);
    sortMenuAnimation = Tween(begin: 0.0, end: 225.0).animate(curve)
      ..addListener(() {
        setState(() {});
      });
    sortMenuVisible = false;
    sortMenuIndex = "My Tournaments";
    tournamentPlayerStream = Firestore.instance
        .collection("Tournaments")
        .where("tournamentPlayers", arrayContains: _currentUser)
        .orderBy("tournamentDate", descending: true)
        .snapshots();
    tournamentSavedStream = Firestore.instance
        .collection("Tournaments")
        .where("tournamentSaves", arrayContains: _currentUser)
        .orderBy("tournamentDate", descending: true)
        .snapshots();
    tournamentAdminStream = Firestore.instance
        .collection("Tournaments")
        .where("tournamentAdmins", arrayContains: _currentUser)
        .orderBy("tournamentDate", descending: true)
        .snapshots();
    teamStream = Firestore.instance
        .collection("Teams")
        .where("teamUsers", arrayContains: _currentUser)
        .snapshots();
  }

  fetchStreams() {
    if (sortMenuIndex == "My Tournaments") {
      return tournamentPlayerStream;
    } else if (sortMenuIndex == "Saved Tournaments") {
      return tournamentSavedStream;
    } else if (sortMenuIndex == "Admin Tournaments") {
      return tournamentAdminStream;
    } else {
      return teamStream;
    }
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          sortMenuIndex,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: new IconButton(
          icon: Icon(
            Icons.sort,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              if (sortMenuVisible) {
                sortMenuVisible = false;
                sortMenuAnimationController.reset();
              } else {
                sortMenuVisible = true;
                sortMenuAnimationController.forward();
              }
            });
          },
        ),
        actions: <Widget>[
          new IconButton(
            icon: Icon(
              Icons.group_add,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new TeamCreationPage(currentUser: _currentUser,)
                ),
              );
            },
          ),
          new IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.white,
            ),
            onPressed: () {
              showSearch(context: context, delegate: GameSearch());
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new GestureDetector(
              child: new Container(
                child: new StreamBuilder(
                  stream: fetchStreams(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> tournamentSnapshot) {
                    if (!tournamentSnapshot.hasData) {
                      return new Center(
                        child: new CircularProgressIndicator(
                          backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                        ),
                      );
                    } else {
                      return tournamentSnapshot.data.documents.isNotEmpty
                          ? new ListView.builder(
                              padding:
                                  EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 10.0),
                              itemBuilder: (BuildContext context, int index) {
                                Map<dynamic, dynamic> tournament =
                                    tournamentSnapshot
                                        .data.documents[index].data;
                                String tournamentID = tournamentSnapshot
                                    .data.documents[index].documentID;
                                return tournament["tournamentPicture"] != null ? new TournamentBox(
                                  tournament: tournament,
                                  tournamentID: tournamentID
                                ) : new TeamBox(
                                  team: tournament,
                                  teamID: tournamentID,
                                );
                              },
                              itemCount:
                                  tournamentSnapshot.data.documents.length,
                            )
                          : new Center(
                              child: new Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  new Container(
                                    margin: EdgeInsets.only(bottom: 10.0),
                                    child: new Text(
                                      sortMenuIndex != "My Teams" ? "No Tournaments Yet" : "No Teams Yet",
                                      style: TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontSize: 20.0,
                                          fontFamily: "Century Gothic",
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  new GestureDetector(
                                    child: new Text(
                                      sortMenuIndex != "My Teams" ? "Create your first tournament" : "Create a team",
                                      style: TextStyle(
                                          color:
                                              Color.fromRGBO(0, 150, 255, 1.0),
                                          fontSize: 18.0,
                                          fontFamily: "Century Gothic",
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onTap: () {
                                      if (sortMenuIndex != "My Teams") {
                                      showSearch(
                                          context: context,
                                          delegate: GameSearch());
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (BuildContext context) => new TeamCreationPage(
                                              currentUser: _currentUser,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                    }
                  },
                ),
              ),
              onTap: () {
                if (sortMenuVisible) {
                  setState(() {
                    sortMenuVisible = false;
                    sortMenuAnimationController.reset();
                  });
                }
              }),
          new Visibility(
            visible: sortMenuVisible,
            child: new Container(
              height: sortMenuAnimation.value,
              width: 220.0,
              margin: EdgeInsets.only(left: 15.0, top: 10.0),
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
                        padding: EdgeInsets.only(left: 10.0),
                        alignment: Alignment.centerLeft,
                        child: new AutoSizeText(
                          "My Tournaments",
                          maxFontSize: 20.0,
                          minFontSize: 18.0,
                          style: TextStyle(
                              color: sortMenuIndex == "My Tournaments"
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (sortMenuIndex != "My Tournaments") {
                            sortMenuIndex = "My Tournaments";
                          }
                          sortMenuVisible = false;
                          sortMenuAnimationController.reset();
                        });
                      },
                    ),
                  ),
                  new Expanded(
                    child: new GestureDetector(
                      child: new Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.only(left: 10.0),
                        alignment: Alignment.centerLeft,
                        child: new AutoSizeText(
                          "Saved Tournaments",
                          maxFontSize: 20.0,
                          minFontSize: 18.0,
                          style: TextStyle(
                              color: sortMenuIndex == "Saved Tournaments"
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (sortMenuIndex != "Saved Tournaments") {
                            sortMenuIndex = "Saved Tournaments";
                          }
                          sortMenuVisible = false;
                          sortMenuAnimationController.reset();
                        });
                      },
                    ),
                  ),
                  new Expanded(
                    child: new GestureDetector(
                      child: new Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.only(left: 10.0),
                        alignment: Alignment.centerLeft,
                        child: new AutoSizeText(
                          "Admin Tournaments",
                          maxFontSize: 20.0,
                          minFontSize: 18.0,
                          style: TextStyle(
                              color: sortMenuIndex == "Admin Tournaments"
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (sortMenuIndex != "Admin Tournaments") {
                            sortMenuIndex = "Admin Tournaments";
                          }
                          sortMenuVisible = false;
                          sortMenuAnimationController.reset();
                        });
                      },
                    ),
                  ),
                  new Expanded(
                    child: new GestureDetector(
                      child: new Container(
                        color: Colors.transparent,
                        padding: EdgeInsets.only(left: 10.0),
                        alignment: Alignment.centerLeft,
                        child: new AutoSizeText(
                          "My Teams",
                          maxFontSize: 20.0,
                          minFontSize: 18.0,
                          style: TextStyle(
                              color: sortMenuIndex == "My Teams"
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if (sortMenuIndex != "My Teams") {
                            sortMenuIndex = "My Teams";
                          }
                          sortMenuVisible = false;
                          sortMenuAnimationController.reset();
                        });
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

class GameSearch extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      primaryColor: Color.fromRGBO(40, 40, 40, 1.0),
      textTheme: TextTheme(
        title: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontFamily: "Avenir",
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(
          Icons.clear,
          color: Colors.blue,
          size: 25.0,
        ),
        onPressed: () {
          print("CLEAR");
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return new IconButton(
      icon: new Icon(
        Icons.arrow_back_ios,
        color: Color.fromRGBO(0, 150, 255, 1.0),
        size: 25.0,
      ),
      onPressed: () {
        print("EXIT SEARCH");
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return new Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return new GameList(
      query: query,
    );
  }
}

class GameList extends StatefulWidget {
  _GameList createState() => new _GameList();

  final String query;

  GameList({Key key, @required this.query}) : super(key: key);
}

class _GameList extends State<GameList> {
  int platformIndex;
  int count;
  int searchCount;
  String query;
  bool loading;
  List<Map<String, dynamic>> gamesAll;
  List<Map<String, dynamic>> gamesPlaystation;
  List<Map<String, dynamic>> gamesXbox;
  List<Map<String, dynamic>> gamesPC;
  List<Map<String, dynamic>> gamesSwitch;

  @override
  void initState() {
    super.initState();
    platformIndex = 0;
    count = 0;
    searchCount = 0;
    query = "";
    loading = false;
    gamesAll = [];
    gamesPlaystation = [];
    gamesXbox = [];
    gamesPC = [];
    gamesSwitch = [];
  }

  Widget build(BuildContext context) {
    if (widget.query != "" && widget.query != query) {
      int search = searchCount;
      searchCount = searchCount + 1;
      List<Map<String, dynamic>> gamesA = [];
      List<Map<String, dynamic>> gamesP = [];
      List<Map<String, dynamic>> gamesX = [];
      List<Map<String, dynamic>> gamesC = [];
      List<Map<String, dynamic>> gamesS = [];
      gamesAll = [];
      gamesPlaystation = [];
      gamesXbox = [];
      gamesPC = [];
      gamesSwitch = [];
      loading = true;
      var url =
          "https://api-endpoint.igdb.com/games/?search=$query&fields=name,platforms,cover";

      http.get(url, headers: {
        "user-key": "a201b12d66273061067ca59fab6cacac",
        "Accept": "application/json"
      }).then((gameInfo) {
        final List<Map<String, dynamic>> parsed =
            json.decode(gameInfo.body).cast<Map<String, dynamic>>();
        for (Map<String, dynamic> game in parsed) {
          print(game["name"]);
          if (game["cover"] != null && game["platforms"] != null) {
            query = widget.query;
            String gameName = game["name"];
            String gamePicture = game["cover"]["url"]
                .toString()
                .replaceAll("t_thumb", "t_cover_big");
            List<dynamic> gamePlatforms = game["platforms"];
            Map<String, dynamic> gameDetails = {
              "gameName": gameName,
              "gamePicture": "https:$gamePicture",
              "gamePlatforms": gamePlatforms
            };

            gamesA.add(gameDetails);

            if (gamePlatforms.contains(48) || gamePlatforms.contains(45)) {
              gamesP.add(gameDetails);
            }
            if (gamePlatforms.contains(49) || gamePlatforms.contains(12)) {
              gamesX.add(gameDetails);
            }
            if (gamePlatforms.contains(6) ||
                gamePlatforms.contains(14) ||
                gamePlatforms.contains(92)) {
              gamesC.add(gameDetails);
            }
            if (gamePlatforms.contains(130)) {
              gamesS.add(gameDetails);
            }
          }
        }
      }).whenComplete(() {
        setState(() {
          gamesAll = [];
          gamesPlaystation = [];
          gamesXbox = [];
          gamesPC = [];
          gamesSwitch = [];
          gamesAll = gamesA.toSet().toList();
          gamesPlaystation = gamesP.toSet().toList();
          gamesXbox = gamesX.toSet().toList();
          gamesPC = gamesC.toSet().toList();
          gamesSwitch = gamesS.toSet().toList();
          gamesAll.forEach((element) => print(element));
          loading = false;
        });
      });
    } else {
      setState(() {
        loading = false;
      });
    }

    gameCount() {
      if (widget.query == "") {
        count = 0;
        return 0;
      } else if (loading == true) {
        count = 1;
        return 1;
      } else if (platformIndex == 0) {
        if (gamesAll.isEmpty) {
          count = 0;
          return 0;
        }
        count = gamesAll.length;
        return gamesAll.length;
      } else if (platformIndex == 1) {
        if (gamesPlaystation.isEmpty) {
          count = 0;
          return 0;
        }
        count = gamesPlaystation.length;
        return gamesPlaystation.length;
      } else if (platformIndex == 2) {
        if (gamesXbox.isEmpty) {
          count = 0;
          return 0;
        }
        count = gamesXbox.length;
        return gamesXbox.length;
      } else if (platformIndex == 3) {
        if (gamesPC.isEmpty) {
          count = 0;
          return 0;
        }
        count = gamesPC.length;
        return gamesPC.length;
      } else if (platformIndex == 4) {
        if (gamesSwitch.isEmpty) {
          count = 0;
          return 0;
        }
        count = gamesSwitch.length;
        return gamesSwitch.length;
      } else {
        count = 0;
        return 0;
      }
    }

    return new Column(
      children: <Widget>[
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
          child: new ListView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemExtent: 100.0,
            children: <Widget>[
              new GestureDetector(
                child: new Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 3.0,
                        color: platformIndex == 0
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                  margin: EdgeInsets.only(right: 5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        margin: EdgeInsets.only(right: 3.0),
                        child: new Image.asset(
                          "assets/allIcon.png",
                          width: 25.0,
                          height: 25.0,
                        ),
                      ),
                      new Text(
                        "All",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
                onTap: () {
                  print("ALL");
                  if (platformIndex != 0) {
                    setState(() {
                      platformIndex = 0;
                    });
                  }
                },
              ),
              new GestureDetector(
                child: new Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 3.0,
                        color: platformIndex == 1
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                  margin: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        margin: EdgeInsets.only(right: 3.0),
                        child: new Image.asset(
                          "assets/playstationIcon.png",
                          width: 25.0,
                          height: 25.0,
                        ),
                      ),
                      new Text(
                        "PS4",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
                onTap: () {
                  print("PS4");
                  if (platformIndex != 1) {
                    setState(() {
                      platformIndex = 1;
                    });
                  }
                },
              ),
              new GestureDetector(
                child: new Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 3.0,
                        color: platformIndex == 2
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                  margin: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        margin: EdgeInsets.only(right: 3.0),
                        child: new Image.asset(
                          "assets/xboxIcon.png",
                          width: 25.0,
                          height: 25.0,
                        ),
                      ),
                      new Text(
                        "Xbox",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
                onTap: () {
                  print("XBOX");
                  if (platformIndex != 2) {
                    setState(() {
                      platformIndex = 2;
                    });
                  }
                },
              ),
              new GestureDetector(
                child: new Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 3.0,
                        color: platformIndex == 3
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                  margin: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        margin: EdgeInsets.only(right: 3.0),
                        height: 25.0,
                        width: 25.0,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(170, 170, 170, 1.0),
                          borderRadius: BorderRadius.circular(12.5),
                        ),
                        child: new Icon(
                          Icons.desktop_windows,
                          color: Colors.white,
                          size: 16.0,
                        ),
                      ),
                      new Text(
                        "PC",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
                onTap: () {
                  print("PC");
                  if (platformIndex != 3) {
                    setState(() {
                      platformIndex = 3;
                    });
                  }
                },
              ),
              new GestureDetector(
                child: new Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 3.0,
                        color: platformIndex == 4
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
                  margin: EdgeInsets.only(left: 5.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        margin: EdgeInsets.only(right: 3.0),
                        child: new Image.asset(
                          "assets/switchIcon.png",
                          width: 25.0,
                          height: 25.0,
                        ),
                      ),
                      new Text(
                        "Switch",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
                onTap: () {
                  print("SWITCH");
                  if (platformIndex != 4) {
                    setState(() {
                      platformIndex = 4;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        loading
            ? new Expanded(
                child: new Container(
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  alignment: Alignment.center,
                  child: new Text(
                    "Searching for ${widget.query}...",
                    style: TextStyle(
                      color: Color.fromRGBO(170, 170, 170, 1.0),
                      fontSize: 17.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : new Container(
                height: 210.0,
                child: new ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    return new GestureDetector(
                      child: new Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(
                            top: 10.0,
                            left: index != 0 ? 15.0 : 10.0,
                            right: index != count - 1 ? 0.0 : 15.0,
                            bottom: 10.0),
                        height: 200.0,
                        width: 150.0,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(23, 23, 23, 1.0),
                          boxShadow: [
                            new BoxShadow(
                              blurRadius: 4.0,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                              offset: new Offset(0.0, 4.0),
                            )
                          ],
                          border: Border.all(
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                              width: 1.0),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: new Container(
                          height: 170.0,
                          width: 125.0,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(50, 50, 50, 1.0),
                            border: Border.all(
                              color: Color.fromRGBO(40, 40, 40, 40),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            image: DecorationImage(
                              image: NetworkImage(platformIndex == 0
                                  ? gamesAll[index]["gamePicture"]
                                  : platformIndex == 1
                                      ? gamesPlaystation[index]["gamePicture"]
                                      : platformIndex == 2
                                          ? gamesXbox[index]["gamePicture"]
                                          : platformIndex == 3
                                              ? gamesPC[index]["gamePicture"]
                                              : platformIndex == 4
                                                  ? gamesSwitch[index]
                                                      ["gamePicture"]
                                                  : ""),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        String game;
                        if (platformIndex == 0) {
                          game = gamesAll[index]["gameName"];
                        } else if (platformIndex == 1) {
                          game = gamesPlaystation[index]["gameName"];
                        }
                        if (platformIndex == 2) {
                          game = gamesXbox[index]["gameName"];
                        } else if (platformIndex == 3) {
                          game = gamesPC[index]["gameName"];
                        } else if (platformIndex == 4) {
                          game = gamesSwitch[index]["gameName"];
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                new TournamentCreationPage(
                                  pageType: "Creation",
                                  tournamentInfo: {
                                    "tournamentName": "",
                                    "tournamentDate": null,
                                    "tournamentGame": game,
                                    "tournamentRegion": "",
                                    "tournamentBracketSize": null,
                                    "tournamentMinTeamSize": null,
                                    "tournamentMaxTeamSize": null,
                                    "tournamentPicture": null,
                                    "tournamentBanner": null,
                                    "tournamentPrivate": false,
                                    "tournamentDoubleElimination": false,
                                    "tournamentRules": "",
                                  },
                                ),
                          ),
                        );
                      },
                    );
                  },
                  itemCount: gameCount(),
                ),
              ),
      ],
    );
  }
}
