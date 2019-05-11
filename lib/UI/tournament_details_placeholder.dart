import 'package:flutter/material.dart';

class TournamentDetailsPlaceholder extends StatelessWidget {
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      body: new Stack(
        children: <Widget>[
          new Column(
            children: <Widget>[
              new Container(
                height: 160.0,
                alignment: Alignment.bottomCenter,
                color: Color.fromRGBO(40, 40, 40, 1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new CircleAvatar(
                      radius: 50.0,
                      backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                      child: new CircleAvatar(
                        radius: 46.0,
                        backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                      ),
                    ),
                    new Container(
                      margin: EdgeInsets.only(top: 2.0, bottom: 3.0),
                      child: new Text(
                        "",
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
              ),
            ],
          ),
          new AppBar(
            backgroundColor: Colors.transparent,
            leading: new BackButton(
              color: Color.fromRGBO(0, 150, 255, 1.0),
            ),
            elevation: 0.0,
          ),
        ],
      ),
    );
  }
}
