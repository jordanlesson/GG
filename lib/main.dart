import 'package:flutter/material.dart';
import 'package:gg/Components/sign_up_page.dart';
import 'package:gg/Components/profile_page.dart';
import 'package:gg/Components/login_page.dart';
import 'package:gg/Components/home_page.dart';
import 'package:gg/Components/master_page.dart';
import 'package:gg/Components/post_page.dart';
import 'package:gg/Components/conversations_page.dart';
import 'package:gg/Components/tournament_creation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'globals.dart' as globals;
import 'package:gg/Components/tournaments_page_2.dart';
import 'package:gg/Components/team_creation_page.dart';

void main() async {

  Widget homePage = new LoginPage();

  await FirebaseAuth.instance.currentUser().then((_currentUser) {
    if (_currentUser != null) {
      print(_currentUser);
      globals.currentUser = _currentUser.uid;
      homePage = new MasterPage(
        currentIndex: 0,
      );
    } else {
      homePage = new LoginPage();
    }
  }).catchError((error) {
    print(error);
    homePage = new LoginPage();
  });

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "GG",
    theme: ThemeData(
      primaryColor: Color.fromRGBO(0, 150, 255, 1.0),
      hintColor: Color.fromRGBO(40, 40, 40, 1.0),
      fontFamily: "Avenir Next",
      cursorColor: Color.fromRGBO(0, 150, 255, 1.0),
    ),
    home: homePage,
    routes: <String, WidgetBuilder>{
      "/LoginPage": (BuildContext context) => LoginPage(),
      "/SignUpPage": (BuildContext context) => SignUpPage(),
      "/MasterPage": (BuildContext context) => MasterPage(
            currentIndex: 0,
          ),
      "/ProfilePage": (BuildContext context) => ProfilePage(),
      "/HomePage": (BuildContext context) => HomePage(
      ),
      "/PostPage": (BuildContext context) => PostPage(),
      "/ConversationPage": (BuildContext context) => ConversationsPage(),
      "/TournamentCreationPage": (BuildContext context) => TournamentCreationPage(),
      "/TournamentsPage": (BuildContext context) => TournamentsPage(
        currentUser: globals.currentUser,
        ),
      "/TeamCreationPage": (BuildContext context) => TeamCreationPage(
        currentUser: globals.currentUser,
      ),
    },
  ));
}
