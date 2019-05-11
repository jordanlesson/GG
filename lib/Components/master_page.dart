import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gg/globals.dart' as globals;
import 'package:gg/Components/home_page.dart';
import 'package:gg/Components/profile_page.dart';
import 'package:gg/Components/conversations_page.dart';
import 'package:gg/Components/tournaments_page_2.dart';
import 'package:gg/Components/notifications_page.dart';

class MasterPage extends StatefulWidget {
  _MasterPage createState() => new _MasterPage();

  final int currentIndex;

  MasterPage({Key key, @required this.currentIndex}) : super(key: key);
}

int _currentIndex;
List<String> userTeams;

class _MasterPage extends State<MasterPage> {
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;

    FirebaseMessaging().configure(onLaunch: ((Map<String, dynamic> message) {
      print(message);
    }), onMessage: ((Map<String, dynamic> message) {
      print(message);
    }), onResume: ((Map<String, dynamic> message) {
      print(message);
    }));

    FirebaseMessaging().requestNotificationPermissions(
        const IosNotificationSettings(sound: true, alert: true, badge: true));
    FirebaseMessaging().onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print(settings);
    });

    FirebaseMessaging().getToken().then((token) {
      print(globals.currentUser);
      print(token);
      Firestore.instance.document("Users/${globals.currentUser}").get().then((userInfo) {
        if (userInfo.exists) {
          List userTokens = List.from(userInfo["userTokens"]);
          if (!userTokens.contains(token)) {
            userTokens.add(token);
            print(token);
            Firestore.instance.document("Users/${globals.currentUser}").updateData({
              "userTokens": userTokens
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
            body: new Stack(
              children: <Widget>[
                new Offstage(
                  child: HomePage(),
                  offstage: _currentIndex == 0 ? false : true,
                ),
                new Offstage(
                  child: new NotificationsPage(
                    currentUser: globals.currentUser,
                  ),
                  offstage: _currentIndex == 1 ? false : true,
                ),
                new Offstage(
                  child: new TournamentsPage(
                      currentUser: globals.currentUser),
                  offstage: _currentIndex == 2 ? false : true,
                ),
                new Offstage(
                  child: new ConversationsPage(),
                  offstage: _currentIndex == 3 ? false : true,
                ),
                new Offstage(
                  child: ProfilePage(
                    userID: globals.currentUser,
                    visitor: false,
                  ),
                  offstage: _currentIndex == 4 ? false : true,
                ),
              ],
            ),
            bottomNavigationBar: new Theme(
              data: new ThemeData(
                canvasColor: Color.fromRGBO(5, 5, 10, 1.0),
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
                  if (_currentIndex != index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  }
                },
                items: [
                  BottomNavigationBarItem(
                    icon: new Icon(
                      Icons.home,
                      size: 25.0,
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
                      Icons.notifications,
                      size: 25.0,
                    ),
                    title: new Text(
                      "Alerts",
                      style: new TextStyle(
                        fontSize: 12.0,
                        fontFamily: "Century Gothic",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: new Icon(IconData(0xe900, fontFamily: "Trophy"),
                        size: 22.0),
                    title: new Text(
                      "Compete",
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
                      size: 25.0,
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
            ),
          );
  }
}
