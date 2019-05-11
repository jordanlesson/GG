import 'package:flutter/material.dart';
import 'package:gg/Components/master_page.dart';
import 'package:gg/UI/background_image.dart';
import 'package:gg/UI/gg_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gg/globals.dart' as globals;
import 'package:gg/UI/custom_textfield.dart';
import 'package:flutter/gestures.dart';
import 'package:gg/Utilities/formatters.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => new _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  String _token;

  TextEditingController usernameTextController;
  TextEditingController passwordTextController;

  bool loginValid;
  bool loginInProgress;
  bool loginError;

  @override
  void initState() {
    super.initState();

    loginValid = false;
    loginInProgress = false;
    loginError = false;

    usernameTextController = new TextEditingController()..addListener(login);
    passwordTextController = new TextEditingController()..addListener(login);

  }

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    usernameTextController.removeListener(login);
    usernameTextController.dispose();
    passwordTextController.removeListener(login);
    passwordTextController.dispose();

    super.dispose();
  }

  login() {
    setState(() {
      if (usernameTextController.text.isNotEmpty &&
          passwordTextController.text.isNotEmpty) {
        loginValid = true;
        loginError = false;
        print(loginError);
      } else {
        loginValid = false;
      }
    });
  }

  void _handleAuthentication(String email, String password) async {
    try {
      FirebaseUser user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      print("Signed In: ${user.uid}");
      globals.currentUser = user.uid;
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
      print(token);
      _token = token;
      Firestore.instance.document("Users/${user.uid}").get().then((userInfo) {
        if (userInfo.exists) {
          List userTokens = List.from(userInfo["userTokens"]);
          if (!userTokens.contains(token)) {
            userTokens.add(token);
            Firestore.instance.document("Users/${user.uid}").updateData({
              "userTokens": userTokens
            });
          }
        }
      });
    });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => WillPopScope(
          child: new MasterPage(
                currentIndex: 0,
              ),
              onWillPop: () async {
                return false;
              },
        ),
        ),
      );
    } catch (error) {
      print("Error: $error");
      setState(() {
        loginError = true;
        loginInProgress = false;
      });
    }
  }

  void _fetchUsername(String usernameText, String passwordText) async {
    final QuerySnapshot username = await Firestore.instance
        .collection("Users")
        .where("userUsername", isEqualTo: usernameText)
        .where("userPassword", isEqualTo: passwordText)
        .limit(1)
        .getDocuments();
    if (username.documents.isNotEmpty) {
      for (DocumentSnapshot userInfo in username.documents) {
        _handleAuthentication(
            userInfo.data["userEmail"], passwordTextController.text);
      }
    } else {
      setState(() {
        loginError = true;
        loginInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
        body: new Column(
          children: <Widget>[
            new Stack(
              children: <Widget>[
                new BackgroundImage(),
                new GGLogo(),
              ],
            ),
            new Container(
              padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
              child: new Column(
                children: <Widget>[
                  new CustomTextfield(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 5.0),
                    height: 50.0,
                    margin: EdgeInsets.symmetric(horizontal: 20.0),
                    maxWidth: 350.0,
                    textFontSize: 18.0,
                    enabledBorderColor: usernameTextController.text.isNotEmpty
                        ? Color.fromRGBO(0, 150, 255, 1.0)
                        : Color.fromRGBO(40, 40, 40, 1.0),
                    hintText: "Username or Email",
                    hintFontSize: 16.0,
                    controller: usernameTextController,
                    inputFormatters: [LowerCaseTextFormatter()],
                    keyboardType: TextInputType.emailAddress,
                  ),
                  new CustomTextfield(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 5.0),
                    height: 50.0,
                    margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
                    maxWidth: 350.0,
                    textFontSize: 18.0,
                    enabledBorderColor: passwordTextController.text.isNotEmpty
                        ? Color.fromRGBO(0, 150, 255, 1.0)
                        : Color.fromRGBO(40, 40, 40, 1.0),
                    hintText: "Password",
                    hintFontSize: 16.0,
                    controller: passwordTextController,
                    password: true,
                    validator: (_) {
                      if (loginError) {
                        return "Username or password are invalid";
                      }
                    },
                  ),
                  new GestureDetector(
                    child: new Container(
                      alignment: Alignment.center,
                      height: 60.0,
                      constraints: BoxConstraints(maxWidth: 350.0),
                      margin: EdgeInsets.fromLTRB(40.0, 20.0, 40.0, 0.0),
                      decoration: BoxDecoration(
                        color: loginValid
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(137, 145, 151, 1.0),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: loginInProgress
                          ? new Theme(
                              child: new CircularProgressIndicator(
                                backgroundColor: Colors.white,
                              ),
                              data: ThemeData(accentColor: Colors.white),
                            )
                          : new Text(
                              "Log In",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 25.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                    onTap: () {
                      if (loginValid) {
                        setState(() {
                          loginInProgress = true;
                          FocusScope.of(context).requestFocus(FocusNode());
                        });
                        String usernameText =
                            usernameTextController.text.trim().toLowerCase();
                        if (usernameText.contains("@")) {
                          _handleAuthentication(
                              usernameText, passwordTextController.text);
                        } else {
                          _fetchUsername(
                              usernameText, passwordTextController.text);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            // new Container(
            //   margin: EdgeInsets.only(top: 20.0),
            //   child: new Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: <Widget>[
            //       new Expanded(
            //         child: new Container(
            //           margin: EdgeInsets.only(left: 25.0),
            //           height: 1.0,
            //           color: Colors.white,
            //           constraints: BoxConstraints(maxWidth: 200.0),
            //         ),
            //       ),
            //       new Container(
            //         alignment: Alignment.center,
            //         margin: EdgeInsets.symmetric(horizontal: 10.0),
            //         child: new Text(
            //           "or",
            //           style: new TextStyle(
            //             color: Colors.white,
            //             fontSize: 17.0,
            //             fontFamily: "Century Gothic",
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       ),
            //       new Expanded(
            //         child: new Container(
            //           margin: EdgeInsets.only(right: 25.0),
            //           height: 1.0,
            //           color: Colors.white,
            //           constraints: BoxConstraints(maxWidth: 200.0),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // new Expanded(
            //   child: new Align(
            //     alignment: Alignment.topCenter,
            //     child: new Container(
            //       height: 60.0,
            //       margin: EdgeInsets.only(top: 20.0, left: 40.0, right: 40.0),
            //       constraints: BoxConstraints(maxWidth: 350.0),
            //       alignment: Alignment.center,
            //       child: new FlatButton(
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(2.0),
            //         ),
            //         color: Colors.white,
            //         onPressed: () async {
            //           GoogleSignIn().signOut();
            //           GoogleSignIn().signIn().then((googleUser) {
                      
            //             if (googleUser != null) {
            //             googleUser.authentication.then((googleAuth) {
            //               FirebaseAuth.instance
            //                   .signInWithGoogle(
            //                     accessToken: googleAuth.accessToken,
            //                     idToken: googleAuth.idToken,
            //                   )
            //                   .then((firebaseUser) {
            //                     if (firebaseUser != null) {
            //                       FirebaseAuth.instance.sign
            //                       print("Signed in with Google");
            //                     } else {
            //                       print("This is null");
                                  
            //                     }
            //                   })
            //                   .catchError((error) {
            //                 print("1st error");
            //               });
            //             });
            //             } else {
            //               print("this is null");
            //             }
            //           });
            //         },
            //         child: new Center(
            //           child: new Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: <Widget>[
            //               new Container(
            //                 height: 40.0,
            //                 margin: EdgeInsets.only(right: 10.0),
            //                 child: new Image.asset(
            //                   "assets/googleIcon.png",
            //                   fit: BoxFit.cover,
            //                 ),
            //               ),
            //               new Text(
            //                 "Log in with Google",
            //                 style: new TextStyle(
            //                   color: Colors.black,
            //                   fontSize: 20.0,
            //                   fontFamily: "Century Gothic",
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            new Expanded(
              child: new Container()
            ),
            new SafeArea(
              child: new Container(
                margin: EdgeInsets.only(bottom: 10.0),
                child: new RichText(
                  text: TextSpan(
                    children: [
                      new TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 15.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold),
                      ),
                      new TextSpan(
                        text: "Sign Up.",
                        style: TextStyle(
                            color: Color.fromRGBO(0, 150, 255, 1.0),
                            fontSize: 17.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (!loginInProgress) {
                            Navigator.of(context).pushNamed("/SignUpPage");
                            }
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }
}
