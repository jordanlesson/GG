import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/globals.dart' as globals;
import 'package:cached_network_image/cached_network_image.dart';
import 'tournament_details_page.dart';
import 'profile_page.dart';
import 'package:async/async.dart';
import 'package:gg/UI/user_box.dart';
import 'package:gg/UI/tournament_box.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';
import 'dart:async';

class SearchPage extends SearchDelegate<String> {
  bool dataLoaded;

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
    dataLoaded = true;

    return SearchList(
      query: query,
      loadData: dataLoaded,
    );
  }
}

class SearchList extends StatefulWidget {
  _SearchList createState() => new _SearchList();

  final String query;
  final bool loadData;

  SearchList({Key key, @required this.query, @required this.loadData})
      : super(key: key);
}

class _SearchList extends State<SearchList> {
  String searchType;
  Stream<QuerySnapshot> allStream;
  Stream<QuerySnapshot> peopleStream;
  Stream<QuerySnapshot> tournamentsStream;
  Stream<QuerySnapshot> gamesStream;

  @override
  initState() {
    super.initState();
    searchType = "People";
  }

  _fetchStream(String searchType) {
    if (searchType == "All") {
      return allStream;
    } else if (searchType == "People") {
      return peopleStream;
    } else if (searchType == "Tournaments") {
      return tournamentsStream;
    }
    return gamesStream;
  }

  Widget _fetchSearch(
      String searchType, Map<dynamic, dynamic> searchInfo, String searchID) {
    if (searchType == "All") {
      return searchInfo["userUsername"] != null
          ? UserBox(
              user: searchInfo,
              currentUser: "",
            )
          : TournamentBox(
              tournament: searchInfo,
              tournamentID: searchID
            );
    } else if (searchType == "People") {
      return searchInfo["userUsername"] != null
          ? UserBox(
              user: searchInfo,
              currentUser: "",
            )
          : new Container();
    } else if (searchType == "Tournaments") {
      return searchInfo["tournamentName"] != null
          ? TournamentBox(
              tournament: searchInfo,
              tournamentID: searchID
            )
          : new Container();
    }
    return UserBox(
      user: searchInfo,
      currentUser: "",
    );
  }

  Widget build(BuildContext context) {
    if (widget.query != "") {
      var strSearch = widget.query;
      var strlength = strSearch.length;
      var strFrontCode = strSearch.substring(0, strlength - 1);
      var strEndCode = strSearch.substring(strlength - 1, strSearch.length);

      var startcode = strSearch;
      var endcode =
          strFrontCode + String.fromCharCode(strEndCode.codeUnitAt(0) + 1);

      peopleStream = Firestore.instance
          .collection("Users")
          .where("userUsername", isGreaterThanOrEqualTo: startcode)
          .where("userUsername", isLessThan: endcode)
          // .orderBy("userUsername", descending: true)
          // .orderBy("userFollowers", descending: true)
          .snapshots();
      tournamentsStream = Firestore.instance
          .collection("Tournaments")
          .where("tournamentName", isGreaterThanOrEqualTo: startcode)
          .where("tournamentName", isLessThan: endcode)
          // .orderBy("tournamentName", descending: true)
          // .orderBy("tournamentDate", descending: true)
          .snapshots();
      gamesStream = Firestore.instance
          .collection("Users")
          .where("userUsername", isGreaterThanOrEqualTo: startcode)
          .where("userUsername", isLessThan: endcode)
          // .orderBy("userUsername", descending: true)
          // .orderBy("userFollowers", descending: true)
          .snapshots();
      allStream = Stream.fromFutures([
        Firestore.instance
            .collection("Users")
            .where("userUsername", isGreaterThanOrEqualTo: startcode)
            .where("userUsername", isLessThan: endcode)
            .getDocuments(),
        Firestore.instance
            .collection("Tournaments")
            .where("tournamentName", isGreaterThanOrEqualTo: startcode)
            .where("tournamentName", isLessThan: endcode)
            .getDocuments()
      ]);
    }

    return new Column(
      children: <Widget>[
        new Container(
          height: 50.0,
          decoration: BoxDecoration(
            color: Color.fromRGBO(23, 23, 23, 1.0),
            border: Border(
              bottom: BorderSide(
                width: 1.0,
                color: Color.fromRGBO(40, 40, 40, 1.0),
              ),
            ),
          ),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // new GestureDetector(
              //     child: new Container(
              //       height: 35.0,
              //       alignment: Alignment.center,
              //       color: Colors.transparent,
              //       child: new Container(
              //         padding: EdgeInsets.only(
              //             left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
              //         decoration: BoxDecoration(
              //           color: searchType == "All"
              //               ? Color.fromRGBO(0, 150, 255, 1.0)
              //               : Colors.transparent,
              //           borderRadius: BorderRadius.all(Radius.circular(10.0)),
              //         ),
              //         child: new Text(
              //           "All",
              //           style: TextStyle(
              //               color: searchType == "All"
              //                   ? Colors.white
              //                   : Color.fromRGBO(170, 170, 170, 1.0),
              //               fontSize: 15.0,
              //               fontFamily: "Century Gothic",
              //               fontWeight: FontWeight.bold),
              //         ),
              //       ),
              //     ),
              //     onTap: () {
              //       if (searchType != "All") {
              //         setState(() {
              //           searchType = "All";
              //         });
              //       }
              //     }),
              new GestureDetector(
                child: new Container(
                  height: 35.0,
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: new Container(
                    padding: EdgeInsets.only(
                        left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
                    decoration: BoxDecoration(
                      color: searchType == "People"
                          ? Color.fromRGBO(0, 150, 255, 1.0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    child: new Text(
                      "People",
                      style: TextStyle(
                          color: searchType == "People"
                              ? Colors.white
                              : Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 15.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                onTap: () {
                  if (searchType != "People") {
                    setState(() {
                      searchType = "People";
                    });
                  }
                },
              ),
              new GestureDetector(
                child: new Container(
                  height: 35.0,
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: new Container(
                    padding: EdgeInsets.only(
                        left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
                    decoration: BoxDecoration(
                      color: searchType == "Tournaments"
                          ? Color.fromRGBO(0, 150, 255, 1.0)
                          : Colors.transparent,
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    child: new Text(
                      "Tournaments",
                      style: TextStyle(
                          color: searchType == "Tournaments"
                              ? Colors.white
                              : Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 15.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                onTap: () {
                  if (searchType != "Tournaments") {
                    setState(() {
                      searchType = "Tournaments";
                    });
                  }
                },
              ),
              // new GestureDetector(
              //   child: new Container(
              //     alignment: Alignment.center,
              //     height: 35.0,
              //     color: Colors.transparent,
              //     child: new Container(
              //       padding: EdgeInsets.only(
              //           left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
              //       decoration: BoxDecoration(
              //         color: searchType == "Games"
              //             ? Color.fromRGBO(0, 150, 255, 1.0)
              //             : Colors.transparent,
              //         borderRadius: BorderRadius.all(Radius.circular(10.0)),
              //       ),
              //       child: new Text(
              //         "Games",
              //         style: TextStyle(
              //             color: searchType == "Games"
              //                 ? Colors.white
              //                 : Color.fromRGBO(170, 170, 170, 1.0),
              //             fontSize: 15.0,
              //             fontFamily: "Century Gothic",
              //             fontWeight: FontWeight.bold),
              //       ),
              //     ),
              //   ),
              //   onTap: () {
              //     if (searchType != "Games") {
              //       setState(() {
              //         searchType = "Games";
              //       });
              //     }
              //   },
              // ),
            ],
          ),
        ),
        new Expanded(
          child: new StreamBuilder(
            stream: _fetchStream(searchType),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot> searchSnapshot) {
              if (!searchSnapshot.hasData) {
                return new Center(
                  child: new Text(
                    "Searching for ${widget.query}...",
                    style: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 16.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                );
              } else if (searchSnapshot.hasError) {
                return new Center(
                  child: new Text(
                    "No Results",
                    style: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 16.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                );
              } else {
                return new ListView.builder(
                  padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 10.0),
                  itemBuilder: (BuildContext context, int index) {
                    Map<dynamic, dynamic> search =
                        searchSnapshot.data.documents[index].data;
                    String searchID =
                        searchSnapshot.data.documents[index].documentID;
                    return _fetchSearch(searchType, search, searchID);
                  },
                  itemCount: searchSnapshot.data.documents.length,
                );
              }
            },
          ),
        ),
        // loading
        //     ? new Expanded(
        //         child: new Container(
        //           color: Color.fromRGBO(23, 23, 23, 1.0),
        //           alignment: Alignment.center,
        //           child: new Text(
        //             "Searching for ${widget.query}...",
        //             style: TextStyle(
        //               color: Color.fromRGBO(170, 170, 170, 1.0),
        //               fontSize: 17.0,
        //               fontFamily: "Century Gothic",
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //         ),
        //       )
        //     : new Expanded(
        //         child: new Container(
        //           color: Color.fromRGBO(23, 23, 23, 1.0),
        //           child: new ListView.builder(
        //             itemBuilder: (BuildContext context, int index) {
        //               picture() {
        //                 if (all == true) {
        //                   return allList[index]["picture"];
        //                 } else if (people == true) {
        //                   return userList[index]["picture"];
        //                 } else if (tournaments == true) {
        //                   return tournamentList[index]["picture"];
        //                 } else {
        //                   return "";
        //                 }
        //               }

        //               fetchTimeStamp(DateTime date) {
        //                 String month;
        //                 String weekday;
        //                 String hour;
        //                 String minute;
        //                 String suffix;
        //                 switch (date.month) {
        //                   case 1:
        //                     month = "Jan";
        //                     break;
        //                   case 2:
        //                     month = "Feb";
        //                     break;
        //                   case 3:
        //                     month = "Mar";
        //                     break;
        //                   case 4:
        //                     month = "Apr";
        //                     break;
        //                   case 5:
        //                     month = "May";
        //                     break;
        //                   case 6:
        //                     month = "Jun";
        //                     break;
        //                   case 7:
        //                     month = "Jul";
        //                     break;
        //                   case 8:
        //                     month = "Aug";
        //                     break;
        //                   case 9:
        //                     month = "Sep";
        //                     break;
        //                   case 10:
        //                     month = "Oct";
        //                     break;
        //                   case 11:
        //                     month = "Nov";
        //                     break;
        //                   case 12:
        //                     month = "Dec";
        //                     break;
        //                 }
        //                 switch (date.weekday) {
        //                   case 1:
        //                     weekday = "Mon";
        //                     break;
        //                   case 2:
        //                     weekday = "Tues";
        //                     break;
        //                   case 3:
        //                     weekday = "Wed";
        //                     break;
        //                   case 4:
        //                     weekday = "Thur";
        //                     break;
        //                   case 5:
        //                     weekday = "Fri";
        //                     break;
        //                   case 6:
        //                     weekday = "Sat";
        //                     break;
        //                   case 7:
        //                     weekday = "Sun";
        //                     break;
        //                 }
        //                 if (date.hour > 12) {
        //                   hour = (date.hour - 12).toString();
        //                   suffix = "pm";
        //                 } else if (date.hour == 12) {
        //                   hour = date.hour.toString();
        //                   suffix = "pm";
        //                 } else if (date.hour == 0) {
        //                   hour = "12";
        //                   suffix = "am";
        //                 } else {
        //                   hour = date.hour.toString();
        //                   suffix = "am";
        //                 }

        //                 if (date.minute <= 10) {
        //                   minute = "0${date.minute}";
        //                 } else {
        //                   minute = date.minute.toString();
        //                 }

        //                 return "$weekday, $month ${date.day}, ${date.year} at $hour:$minute$suffix ${date.timeZoneName}";
        //               }

        //               region(String region) {
        //                 if (region == "North America East") {
        //                   return "NA East";
        //                 } else if (region == "North America West") {
        //                   return "NA West";
        //                 } else {
        //                   return region;
        //                 }
        //               }

        //               description() {
        //                 if (allList[index]["description"].runtimeType !=
        //                     String) {
        //                   return fetchTimeStamp(allList[index]["description"]);
        //                 } else {
        //                   return allList[index]["description"];
        //                 }
        //               }

        //               return new GestureDetector(
        //                 child: new Container(
        //                   height: 60.0,
        //                   margin: EdgeInsets.only(
        //                       left: 15.0, right: 15.0, bottom: 10.0),
        //                   decoration: BoxDecoration(
        //                     color: Color.fromRGBO(23, 23, 23, 1.0),
        //                     boxShadow: [
        //                       BoxShadow(
        //                         blurRadius: 4.0,
        //                         color: Colors.black,
        //                         offset: Offset(0.0, 4.0),
        //                       ),
        //                     ],
        //                     borderRadius:
        //                         BorderRadius.all(Radius.circular(20.0)),
        //                     border: Border.all(
        //                       width: 1.0,
        //                       color: Color.fromRGBO(40, 40, 40, 1.0),
        //                     ),
        //                   ),
        //                   child: new Row(
        //                     crossAxisAlignment: CrossAxisAlignment.start,
        //                     children: <Widget>[
        //                       new Container(
        //                         margin: EdgeInsets.only(left: 2.0, top: 4.0),
        //                         child: new CircleAvatar(
        //                           backgroundColor:
        //                               Color.fromRGBO(0, 150, 255, 1.0),
        //                           radius: 25.0,
        //                           child: new CircleAvatar(
        //                             backgroundColor:
        //                                 Color.fromRGBO(50, 50, 50, 1.0),
        //                             radius: 23.0,
        //                             backgroundImage: CachedNetworkImageProvider(
        //                               picture(),
        //                             ),
        //                           ),
        //                         ),
        //                       ),
        //                       new Expanded(
        //                         child: new Container(
        //                           child: new Column(
        //                             crossAxisAlignment:
        //                                 CrossAxisAlignment.start,
        //                             children: <Widget>[
        //                               new Expanded(
        //                                 child: new Row(
        //                                   children: <Widget>[
        //                                     new Expanded(
        //                                       child: new Container(
        //                                         margin: EdgeInsets.only(
        //                                             left: 5.0, top: 5.0),
        //                                         child: new Text(
        //                                           all
        //                                               ? allList[index]["title"]
        //                                               : people
        //                                                   ? userList[index]
        //                                                       ["title"]
        //                                                   : tournaments
        //                                                       ? tournamentList[
        //                                                               index]
        //                                                           ["title"]
        //                                                       : "Title",
        //                                           overflow:
        //                                               TextOverflow.ellipsis,
        //                                           maxLines: 1,
        //                                           style: TextStyle(
        //                                             color: Colors.white,
        //                                             fontSize: 17.0,
        //                                             fontFamily:
        //                                                 "Century Gothic",
        //                                             fontWeight: FontWeight.bold,
        //                                           ),
        //                                         ),
        //                                       ),
        //                                     ),
        //                                     new Align(
        //                                       alignment: Alignment.topRight,
        //                                       child: new Container(
        //                                         margin: EdgeInsets.only(
        //                                             top: 10.0, right: 15.0),
        //                                         child: new Text(
        //                                           all
        //                                               ? region(allList[index]
        //                                                   ["region"])
        //                                               : people
        //                                                   ? ""
        //                                                   : tournaments
        //                                                       ? region(
        //                                                           tournamentList[
        //                                                                   index]
        //                                                               [
        //                                                               "region"])
        //                                                       : "Region",
        //                                           style: new TextStyle(
        //                                             color: Color.fromRGBO(
        //                                                 170, 170, 170, 1.0),
        //                                             fontSize: 13.0,
        //                                             fontFamily: "Avenir",
        //                                             fontWeight: FontWeight.w500,
        //                                           ),
        //                                         ),
        //                                       ),
        //                                     ),
        //                                   ],
        //                                 ),
        //                               ),
        //                               new Container(
        //                                 margin: EdgeInsets.only(
        //                                     left: 5.0, bottom: 10.0),
        //                                 child: new Text(
        //                                   all
        //                                       ? description()
        //                                       : people
        //                                           ? userList[index]
        //                                               ["description"]
        //                                           : tournaments
        //                                               ? fetchTimeStamp(
        //                                                   tournamentList[index]
        //                                                       ["description"])
        //                                               : "Description",
        //                                   overflow: TextOverflow.ellipsis,
        //                                   maxLines: 1,
        //                                   style: TextStyle(
        //                                     color: Color.fromRGBO(
        //                                         170, 170, 170, 1.0),
        //                                     fontSize: 14.0,
        //                                     fontFamily: "Avenir",
        //                                     fontWeight: FontWeight.bold,
        //                                   ),
        //                                 ),
        //                               ),
        //                             ],
        //                           ),
        //                         ),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   if (all == true) {
        //                     print(allList[index]["id"]);
        //                     if (allList[index]["region"] == "") {
        //                       Navigator.of(context).push(
        //                         MaterialPageRoute(
        //                           builder: (BuildContext context) =>
        //                               new ProfilePage(
        //                                 userID: allList[index]["id"],
        //                                 visitor: true,
        //                               ),
        //                         ),
        //                       );
        //                     } else {
        //                       Navigator.of(context).push(
        //                         MaterialPageRoute(
        //                           builder: (BuildContext context) =>
        //                               new TournamentDetailsPage(
        //                                 tournamentID: tournamentList[index]
        //                                     ["id"],
        //                                 tournamentInfo: tournamentList[index],
        //                               ),
        //                         ),
        //                       );
        //                     }
        //                   } else if (people == true) {
        //                     print(userList[index]["id"]);
        //                     Navigator.of(context).push(
        //                       MaterialPageRoute(
        //                         builder: (BuildContext context) =>
        //                             new ProfilePage(
        //                               userID: userList[index]["id"],
        //                               visitor: true,
        //                             ),
        //                       ),
        //                     );
        //                   } else if (tournaments == true) {
        //                     print(tournamentList[index]["id"]);
        //                     Navigator.of(context).push(
        //                       MaterialPageRoute(
        //                         builder: (BuildContext context) =>
        //                             new TournamentDetailsPage(
        //                               tournamentID: tournamentList[index]["id"],
        //                               tournamentInfo: tournamentList[index],
        //                             ),
        //                       ),
        //                     );
        //                   }
        //                 },
        //               );
        //             },
        //             itemCount: count(),
        //           ),
        //         ),
        //       ),
      ],
    );
  }
}
