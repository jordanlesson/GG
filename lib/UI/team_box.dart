import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gg/Components/team_profile_page.dart';


class TeamBox extends StatefulWidget {
  final String teamID;
  final Map<String, dynamic> team;

  TeamBox({Key key, @required this.teamID, @required this.team}) : super(key: key);

  _TeamBox createState() => _TeamBox();
}

class _TeamBox extends State<TeamBox> {
  Map<String, dynamic> team;

  @override
  void initState() {
    super.initState();
    team = widget.team;
  }

  Widget build(BuildContext context) {
    team = widget.team;
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
                    team["teamPicture"],
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
                          team["teamName"],
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => new TeamProfilePage(
                  teamID: widget.teamID,
                  team: widget.team,
                ),
          ),
        );
      },
    );
  }
}