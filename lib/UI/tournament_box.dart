import 'package:flutter/material.dart';
import 'package:gg/Components/tournament_details_page.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TournamentBox extends StatefulWidget {
  _TournamentBox createState() => new _TournamentBox();

  final Map<dynamic, dynamic> tournament;
  final String tournamentID;

  TournamentBox(
      {Key key, @required this.tournament, @required this.tournamentID})
      : super(key: key);
}

class _TournamentBox extends State<TournamentBox> {
  
  Map<dynamic, dynamic> tournament;

  @override
  void initState() {
    super.initState();
    tournament = widget.tournament;
  }

  String fetchDate(DateTime date) {
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

  String fetchRegion(String tournamentRegion) {
    if (tournamentRegion == "North America East") {
      return "NA East";
    } else if (tournamentRegion == "North America West") {
      return "NA West";
    }
    return tournamentRegion;
  }

  Widget build(BuildContext context) {
    tournament = widget.tournament;
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
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            new BoxShadow(
              blurRadius: 4.0,
              color: Color.fromRGBO(0, 0, 0, 0.5),
              offset: new Offset(0.0, 4.0),
            ),
          ],
        ),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(left: 2.0, top: 4.0),
              child: new CircleAvatar(
                backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                radius: 25.0,
                child: new CircleAvatar(
                  backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                  radius: 23.0,
                  backgroundImage: CachedNetworkImageProvider(
                    tournament["tournamentPicture"],
                  ),
                ),
              ),
            ),
            new Expanded(
              child: Container(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Expanded(
                      child: new Container(
                        margin: EdgeInsets.only(left: 5.0, top: 5.0),
                        child: new Text(
                          tournament["tournamentName"],
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
                        margin: EdgeInsets.only(left: 5.0, bottom: 10.0),
                        child: new AutoSizeText(
                          fetchDate(tournament["tournamentDate"].toDate()),
                          overflow: TextOverflow.ellipsis,
                          maxFontSize: 14.0,
                          minFontSize: 12.0,
                          maxLines: 1,
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                  ],
                ),
              ),
            ),
            new Container(
              margin: EdgeInsets.only(top: 10.0, right: 15.0, left: 10.0),
              child: new Text(
                fetchRegion(tournament["tournamentRegion"]),
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
            builder: (BuildContext context) => new TournamentDetailsPage(
                  tournamentID: widget.tournamentID,
                  tournamentInfo: tournament
                ),
          ),
        );
      },
    );
  }
}
