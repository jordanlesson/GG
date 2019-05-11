import 'package:flutter/material.dart';
import 'package:gg/UI/navigation_bar.dart';

class ProfilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      body: new Stack(
        children: <Widget>[
          new CustomScrollView(
            slivers: <Widget>[
              new SliverAppBar(
                backgroundColor: Colors.transparent,
                leading: new Container(),
                expandedHeight: 190.0,
                elevation: 0.0,
                flexibleSpace: new FlexibleSpaceBar(
                  background: new Container(
                    child: new Column(
                      children: <Widget>[
                        new Container(
                          color: Color.fromRGBO(40, 40, 40, 1.0),
                          height: 160.0,
                          child: new Stack(
                            alignment: Alignment.bottomCenter,
                            fit: StackFit.expand,
                            children: <Widget>[
                              new Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  new CircleAvatar(
                                    radius: 50.0,
                                    backgroundColor:
                                        Color.fromRGBO(0, 150, 255, 1.0),
                                    child: CircleAvatar(
                                      radius: 46.0,
                                      backgroundColor:
                                          Color.fromRGBO(50, 50, 50, 1.0),
                                    ),
                                  ),
                                  new Container(
                                    margin:
                                        EdgeInsets.only(top: 2.0, bottom: 3.0),
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
                            ],
                          ),
                        ),
                        new Container(
                          alignment: Alignment.center,
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              new Container(
                                width: 60.0,
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Container(
                                      child: new Text(
                                        "",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    new Container(
                                      margin:
                                          EdgeInsets.only(top: 4.0, left: 4.0),
                                      child: new Text(
                                        "Posts",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              new Container(
                                margin:
                                    EdgeInsets.only(left: 25.0, right: 25.0),
                                width: 60.0,
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Container(
                                      child: new Text(
                                        "",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    new Container(
                                      margin:
                                          EdgeInsets.only(top: 4.0, left: 4.0),
                                      child: new Text(
                                        "Followers",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              new Container(
                                width: 60.0,
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Container(
                                      child: new Text(
                                        "",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    new Container(
                                      margin: EdgeInsets.only(top: 4.0),
                                      child: new Text(
                                        "Following",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 12.0,
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
                ),
              ),
            ],
          ),
          new Center(
              child: new CircularProgressIndicator(
            backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
          ))
        ],
      ),
    );
  }
}
