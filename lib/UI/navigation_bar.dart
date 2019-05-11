import "package:flutter/material.dart";
import 'package:gg/main.dart';
import 'package:gg/Components/home_page.dart';

class NavigationBar extends StatefulWidget {
  _NavigationBar createState() => new _NavigationBar();
}

class _NavigationBar extends State<NavigationBar> {
  
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return new Theme(
      data: new ThemeData(
        canvasColor: Color.fromRGBO(5, 5, 10, 0.9),
        primaryColor: Color.fromRGBO(0, 150, 255, 1.0),
        textTheme: new TextTheme(
          caption: new TextStyle(
            color: Color.fromRGBO(170, 170, 170, 1.0),
            fontSize: 12.0,
          ),
        ),
      ),
      child: new BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        fixedColor: Color.fromRGBO(0, 150, 255, 1.0),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.home,
            ),
            title: new Text(
              "Home",
              style: new TextStyle(
                fontSize: 12.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.search,
              size: 25.0,
            ),
            title: new Text(
              "Search",
              style: new TextStyle(
                fontSize: 12.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              IconData(0xe900, fontFamily: "Trophy"),
            ),
            title: new Text(
              "Tournaments",
              style: new TextStyle(
                fontSize: 12.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              Icons.chat,
            ),
            title: new Text(
              "Messages",
              style: new TextStyle(
                fontSize: 12.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          BottomNavigationBarItem(
            icon: new Icon(
              IconData(0xe971, fontFamily: "Profile"),
              size: 25.0,
            ),
            title: new Text(
              "Me",
              style: new TextStyle(
                fontSize: 12.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
