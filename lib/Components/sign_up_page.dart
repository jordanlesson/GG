import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/UI/gg_logo.dart';
import 'package:gg/UI/background_image.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'package:gg/Utilities/formatters.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'master_page.dart';
import 'user_agreement_page.dart';
import 'package:gg/globals.dart' as globals;
import 'package:google_sign_in/google_sign_in.dart';

class SignUpPage extends StatefulWidget {
  _SignUpPage createState() => new _SignUpPage();
}

class _SignUpPage extends State<SignUpPage> {
  bool usernameExists;
  bool emailExists;

  bool usernameValid;
  bool emailValid;
  bool passwordValid;
  bool userAgreementValid;

  bool signUpValid;
  bool signUpInProgress;

  TextEditingController usernameTextController;
  TextEditingController emailTextController;
  TextEditingController passwordTextController;

  final RegExp usernameExp = RegExp(r'^[A-Za-z0-9 ]+$');
  final RegExp emailExp = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

  @override
  void initState() {
    super.initState();

    signUpValid = false;
    signUpInProgress = false;

    emailExists = false;

    usernameValid = false;
    emailValid = false;
    passwordValid = false;
    userAgreementValid = false;

    usernameTextController = new TextEditingController()..addListener(signUp);
    emailTextController = new TextEditingController()..addListener(signUp);
    passwordTextController = new TextEditingController()..addListener(signUp);
  }

  signUp() {
    setState(() {
      usernameExists = false;
      emailExists = false;
      if (usernameValid && emailValid && passwordValid && userAgreementValid) {
        signUpValid = true;
      } else {
        signUpValid = false;
      }
    });
  }

  void _handleInitialization(String userID, String usernameText,
      String emailText, String passwordText) async {
    FirebaseMessaging().getToken().then((token) async {
      StorageReference userPictureRef = FirebaseStorage.instance
          .ref()
          .child("Users/$userID/picture/picture.png");
      StorageReference userBannerRef = FirebaseStorage.instance
          .ref()
          .child("Users/$userID/banner/banner.png");

      int userDefaultPicture = Random().nextInt(38);
      int userThemeBanner = Random().nextInt(9);

      ByteData pictureBytes = await rootBundle
          .load("assets/default/default$userDefaultPicture.png");
      Directory pictureTempDir = Directory.systemTemp;
      String pictureFileName = "$userDefaultPicture.png";
      File userPictureFile = File("${pictureTempDir.path}/$pictureFileName");
      userPictureFile
          .writeAsBytes(pictureBytes.buffer.asUint8List(), mode: FileMode.write)
          .then((_) async {
        ByteData bannerBytes =
            await rootBundle.load("assets/theme/theme$userThemeBanner.png");
        Directory bannerTempDir = Directory.systemTemp;
        String bannerFileName = "$userThemeBanner.png";
        File userBannerFile = File("${bannerTempDir.path}/$bannerFileName");
        userBannerFile.writeAsBytes(bannerBytes.buffer.asUint8List(),
            mode: FileMode.write);

        userPictureRef.putFile(userPictureFile).onComplete.then((_) {
          userBannerRef.putFile(userBannerFile).onComplete.then((_) async {
            String userPictureURL = await userPictureRef.getDownloadURL();
            String userBannerURL = await userBannerRef.getDownloadURL();

            Map<String, dynamic> initialUserInfo = <String, dynamic>{
              "userEmail": emailText,
              "userUsername": usernameText,
              "userPassword": passwordText,
              "userFirstName": "",
              "userLastName": "",
              "userPhoneNumber": "",
              "userTokens": [token],
              "userID": userID,
              "userBanner": userBannerURL,
              "userPicture": userPictureURL,
              "userPreferredRegion": "",
              "userFollowers": [],
            };

            try {
              Firestore.instance
                  .document("Users/$userID")
                  .setData(initialUserInfo)
                  .then((_) {
                globals.currentUser = userID;

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

                FirebaseMessaging().configure(
                    onLaunch: ((Map<String, dynamic> message) {
                  print(message);
                }), onMessage: ((Map<String, dynamic> message) {
                  print(message);
                }), onResume: ((Map<String, dynamic> message) {
                  print(message);
                }));

                FirebaseMessaging().requestNotificationPermissions(
                    const IosNotificationSettings(
                        sound: true, alert: true, badge: true));
                FirebaseMessaging()
                    .onIosSettingsRegistered
                    .listen((IosNotificationSettings settings) {
                  print(settings);
                });
              });
            } catch (error) {
              print("Error: $error");
            }
          });
        });
      });
    });
  }

  void _handleRegistration(
      String usernameText, String emailText, String passwordText) async {
    try {
      await Firestore.instance
          .collection("Users")
          .where("userUsername", isEqualTo: usernameText)
          .limit(1)
          .getDocuments()
          .then((usernameDocuments) async {
        if (usernameDocuments.documents.isNotEmpty) {
          setState(() {
            usernameExists = true;
          });
        } else {
          await Firestore.instance
              .collection("Users")
              .where("userEmail", isEqualTo: emailText)
              .limit(1)
              .getDocuments()
              .then((emailDocuments) async {
            if (emailDocuments.documents.isNotEmpty) {
              setState(() {
                emailExists = true;
              });
            } else {
              await FirebaseAuth.instance
                  .createUserWithEmailAndPassword(
                email: emailTextController.text.toLowerCase().trim(),
                password: passwordTextController.text,
              )
                  .then((userInfo) {
                _handleInitialization(
                    userInfo.uid, usernameText, emailText, passwordText);
                print("Registered: ${userInfo.uid}");
              });
            }
          });
        }
      });
    } catch (error) {
      print("Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Scaffold(
        resizeToAvoidBottomPadding: false,
        backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
        body: new Stack(
          children: <Widget>[
            new BackgroundImage(),
            new AppBar(
              backgroundColor: Colors.transparent,
              title: new Text(
                "Create an Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: signUpInProgress
                  ? new Icon(
                      Icons.arrow_back_ios,
                      color: Color.fromRGBO(170, 170, 170, 1.0),
                    )
                  : new BackButton(
                      color: Color.fromRGBO(0, 150, 255, 1.0),
                    ),
              elevation: 0.0,
            ),
            new Column(
              children: <Widget>[
                new GGLogo(),
                new Container(
                  padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 0.0),
                  child: new Column(
                    children: <Widget>[
                      new CustomTextfield(
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 5.0),
                        height: 50.0,
                        margin:
                            EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0),
                        maxWidth: 350.0,
                        textFontSize: 18.0,
                        enabledBorderColor:
                            usernameTextController.text.isNotEmpty
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                        hintText: "Username",
                        hintFontSize: 16.0,
                        controller: usernameTextController,
                        inputFormatters: [LowerCaseTextFormatter()],
                        autovalidate: true,
                        validator: (usernameText) {
                          if (usernameText.trim().length > 0) {
                            if (usernameText.trim().length < 4) {
                              usernameValid = false;
                              return "Username must contain at least 4 characters";
                            } else if (usernameText.trim().length > 15) {
                              usernameValid = false;
                              return "Username must contain less than 15 characters";
                            } else if (usernameText.trim().isNotEmpty &&
                                !usernameExp.hasMatch(usernameText)) {
                              usernameValid = false;
                              return "Username must contain alphanumeric characters only";
                            } else if (usernameExists == true) {
                              usernameValid = false;
                              return "Already an account with this username";
                            } else {
                              usernameValid = true;
                              return "";
                            }
                          } else {
                            usernameValid = false;
                            return "";
                          }
                        },
                      ),
                      new CustomTextfield(
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 5.0),
                        height: 50.0,
                        margin:
                            EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0),
                        maxWidth: 350.0,
                        textFontSize: 18.0,
                        keyboardType: TextInputType.emailAddress,
                        enabledBorderColor: emailTextController.text.isNotEmpty
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(40, 40, 40, 1.0),
                        hintText: "Email",
                        hintFontSize: 16.0,
                        controller: emailTextController,
                        inputFormatters: [LowerCaseTextFormatter()],
                        autovalidate: true,
                        validator: (emailText) {
                          if (emailText.trim().length > 0) {
                            if (!emailExp.hasMatch(emailText)) {
                              emailValid = false;
                              return "Email is invalid";
                            } else if (emailExists == true) {
                              emailValid = false;
                              return "Already an account with this email";
                            } else {
                              emailValid = true;
                              return "";
                            }
                          } else {
                            emailValid = false;
                            return "";
                          }
                        },
                      ),
                      new CustomTextfield(
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 5.0),
                        height: 50.0,
                        margin:
                            EdgeInsets.only(left: 20.0, right: 20.0, top: 30.0),
                        maxWidth: 350.0,
                        textFontSize: 18.0,
                        enabledBorderColor:
                            passwordTextController.text.isNotEmpty
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                        hintText: "Password",
                        hintFontSize: 16.0,
                        controller: passwordTextController,
                        password: true,
                        autovalidate: true,
                        validator: (passwordText) {
                          if (passwordText.length > 0) {
                            if (passwordText.length < 6) {
                              passwordValid = false;
                              return "Password must contain at least 6 characters";
                            } else {
                              passwordValid = true;
                              return "";
                            }
                          } else {
                            passwordValid = false;
                            return "";
                          }
                        },
                      ),
                      new GestureDetector(
                          child: new Container(
                            margin: EdgeInsets.only(top: 25.0, left: 20.0),
                            child: new Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                new Container(
                                  width: 25.0,
                                  height: 25.0,
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.only(right: 5.0),
                                  decoration: BoxDecoration(
                                      color: Color.fromRGBO(5, 5, 10, 1.0),
                                      border: Border.all(
                                          color: userAgreementValid
                                              ? Color.fromRGBO(0, 122, 255, 1.0)
                                              : Color.fromRGBO(40, 40, 40, 1.0),
                                          width: 1.0),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(2.0))),
                                          child: userAgreementValid ? new Icon(Icons.check, size: 20.0, color: Color.fromRGBO(0, 122, 255, 1.0),) : new Container()
                                ),
                                new Text(
                                  "I Agree to the Terms and Conditions",
                                  style: TextStyle(
                                      color: Color.fromRGBO(170, 170, 170, 1.0),
                                      fontSize: 13.0,
                                      fontFamily: "Avenir",
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                          onTap: () {
                            if (userAgreementValid) {
                              setState(() {
                                userAgreementValid = false;
                                signUp();
                              });
                            } else {
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      UserAgreementPage(),
                                ),
                              )
                                  .then((userAgreed) {
                                if (userAgreed) {
                                  setState(() {

                                    userAgreementValid = true;
                                    signUp();
                                  });
                                }
                              });
                            }
                          }),
                      new Container(
                        alignment: Alignment.center,
                        height: 60.0,
                        constraints: BoxConstraints(maxWidth: 350.0),
                        margin: EdgeInsets.fromLTRB(40.0, 25.0, 40.0, 0.0),
                        child: new FlatButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: new Center(
                            child: signUpInProgress
                                ? new Theme(
                                    child: new CircularProgressIndicator(
                                      backgroundColor: Colors.white,
                                    ),
                                    data: ThemeData(accentColor: Colors.white),
                                  )
                                : new Text(
                                    "Sign Up",
                                    style: TextStyle(
                                        fontSize: 25.0,
                                        fontFamily: "Century Gothic",
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                          textColor: Colors.white,
                          color: signUpValid
                              ? Color.fromRGBO(0, 150, 255, 1.0)
                              : Color.fromRGBO(137, 145, 151, 1.0),
                          onPressed: () {
                            if (signUpValid) {
                              setState(() {
                                signUpInProgress = true;
                              });
                              String usernameText = usernameTextController.text
                                  .trim()
                                  .toLowerCase();
                              String emailText =
                                  emailTextController.text.trim().toLowerCase();
                              String passwordText = passwordTextController.text;

                              _handleRegistration(
                                  usernameText, emailText, passwordText);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // new Container(
                //   margin: EdgeInsets.only(top: 15.0),
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
                //       margin:
                //           EdgeInsets.only(top: 15.0, left: 40.0, right: 40.0),
                //       constraints: BoxConstraints(maxWidth: 350.0),
                //       alignment: Alignment.center,
                //       child: new FlatButton(
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(2.0),
                //         ),
                //         color: Colors.white,
                //         onPressed: () async {
                //       GoogleSignIn().signIn().then((googleUser) {
                //         googleUser.clearAuthCache();
                //         if (googleUser != null) {
                //         googleUser.authentication.then((googleAuth) {
                //           FirebaseAuth.instance
                //               .linkWithGoogleCredential(
                //                 accessToken: googleAuth.accessToken,
                //                 idToken: googleAuth.idToken,
                //               )
                //               .then((firebaseUser) {
                //                 if (firebaseUser != null) {
                //                   print(firebaseUser.uid);
                //                   print("Signed un with Google");
                //                 } else {
                //                   print(firebaseUser.uid);
                //                   print("This is null");
                //                   Navigator.of(context).pop();
                //                 }
                //               });
                //         });
                //         } else {
                //           print("this is null");
                //         }
                //       });
                //     },
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
                //                 "Sign up with Google",
                //                 style: new TextStyle(
                //                   color: Colors.black,
                //                   fontSize: 18.0,
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
              ],
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
