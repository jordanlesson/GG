import 'package:flutter/material.dart';
import 'dart:io';
import 'package:gg/UI/custom_textfield.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:gg/Utilities/formatters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'master_page.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gg/globals.dart' as globals;

class SettingsPage extends StatefulWidget {
  _SettingsPage createState() => new _SettingsPage();

  final Map<String, dynamic> userInfo;

  SettingsPage({Key key, @required this.userInfo}) : super(key: key);
}

class _SettingsPage extends State<SettingsPage> {
  Map<dynamic, dynamic> userInfo;
  Map<dynamic, dynamic> previousUserInfo;
  TextEditingController usernameTextController;
  TextEditingController emailTextController;
  TextEditingController firstNameTextController;
  TextEditingController lastNameTextController;
  TextEditingController phoneNumberTextController;
  TextEditingController passwordTextController;
  final RegExp usernameExp = RegExp(r'^[A-Za-z0-9 ]+$');
  final RegExp emailExp = RegExp(
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');
  bool settingsValid;
  bool updateInProgress;
  bool usernameValid;
  bool emailValid;
  bool phoneNumberValid;
  bool passwordValid;
  File userPicture;
  File userBanner;

  @override
  void initState() {
    super.initState();
    print(widget.userInfo["userPassword"]);
    userInfo = new Map.from(widget.userInfo);
    previousUserInfo = new Map.from(widget.userInfo);
    usernameTextController = new TextEditingController();
    emailTextController = new TextEditingController();
    firstNameTextController = new TextEditingController();
    lastNameTextController = new TextEditingController();
    phoneNumberTextController =
        new MaskedTextController(mask: "(000) 000-0000");
    passwordTextController = new TextEditingController();

    usernameTextController.text = userInfo["userUsername"];
    emailTextController.text = userInfo["userEmail"];
    firstNameTextController.text = userInfo["userFirstName"];
    lastNameTextController.text = userInfo["userLastName"];
    phoneNumberTextController.text = userInfo["userPhoneNumber"];
    passwordTextController.text = userInfo["userPassword"];

    usernameTextController.addListener(settings);
    emailTextController.addListener(settings);
    firstNameTextController.addListener(settings);
    lastNameTextController.addListener(settings);
    phoneNumberTextController.addListener(settings);
    passwordTextController.addListener(settings);

    settingsValid = false;
    updateInProgress = false;
    usernameValid = true;
    emailValid = true;
    if (phoneNumberTextController.text.trim().length == 14) {
      phoneNumberValid = true;
    } else {
      phoneNumberValid = false;
    }
    passwordValid = true;
  }

  settings() {
    setState(() {
      userInfo["userUsername"] = usernameTextController.text.trim();
      userInfo["userEmail"] = emailTextController.text.trim();
      userInfo["userFirstName"] = firstNameTextController.text.trim();
      userInfo["userLastName"] = lastNameTextController.text.trim();
      userInfo["userPhoneNumber"] = phoneNumberTextController.text;
      userInfo["userPassword"] = passwordTextController.text;

      if (usernameValid &&
          emailValid &&
          phoneNumberValid &&
          passwordValid &&
          userInfo["userPicture"] != null &&
          userInfo["userBanner"] != null) {
        setState(() {
          settingsValid = true;
        });
      }
    });
  }

  _handleLogOut() {
    FirebaseAuth.instance.signOut().then((_) {
      globals.currentUser = null;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (BuildContext context) => new LoginPage()
        ), ModalRoute.withName("/LoginPage"));
    });
    
    
  }

  Future<Null> _selectPreferredRegion(BuildContext context) async {
    String selectedRegion = userInfo["userPreferredRegion"];

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new Center(
          child: new Container(
            height: 375.0,
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 40.0, right: 40.0),
            constraints: BoxConstraints(maxWidth: 350.0),
            decoration: BoxDecoration(
              color: Color.fromRGBO(23, 23, 23, 1.0),
              border: Border.all(
                width: 1.0,
                color: Color.fromRGBO(0, 150, 255, 1.0),
              ),
            ),
            child: new Material(
              type: MaterialType.transparency,
              child: new ListView.builder(
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  List<String> regions = [
                    "Regions",
                    "North America East",
                    "North America West",
                    "Europe",
                    "Asia",
                    "Oceana",
                    "Brasil",
                    "Global",
                  ];

                  return new Material(
                    type: MaterialType.transparency,
                    child: new GestureDetector(
                      child: new Container(
                        alignment: index != 0
                            ? Alignment.centerLeft
                            : Alignment.center,
                        padding: EdgeInsets.only(
                            top: 10.0,
                            bottom: 10.0,
                            left: index != 0 ? 15.0 : 0.0),
                        child: new Text(
                          regions[index],
                          style: TextStyle(
                            color: regions[index] == selectedRegion
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : index != 0
                                    ? Color.fromRGBO(170, 170, 170, 1.0)
                                    : Colors.white,
                            fontSize: 20.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(23, 23, 23, 1.0),
                          border: index == 7
                              ? Border()
                              : Border(
                                  bottom: BorderSide(
                                    width: 1.0,
                                    color: Color.fromRGBO(40, 40, 40, 1.0),
                                  ),
                                ),
                        ),
                      ),
                      onTap: () {
                        if (index != 0) {
                          setState(() {
                            selectedRegion = regions[index];
                            Navigator.of(context, rootNavigator: true)
                                .pop([selectedRegion]);
                          });
                        }
                      },
                    ),
                  );
                },
                itemCount: 8,
              ),
            ),
          ),
        );
      },
    ).then((region) {
      setState(() {
        userInfo["userPreferredRegion"] = selectedRegion;
      });
    });
  }

  _fetchCamera(String media) async {
    File previousMedia;
    if (media == "Picture") {
      previousMedia = userPicture;
    } else {
      previousMedia = userBanner;
    }
    File userMedia = await ImagePicker.pickImage(source: ImageSource.camera);
    if (userMedia != null) {
      setState(() {
        if (media == "Picture") {
          userPicture = userMedia;
        } else {
          userBanner = userMedia;
        }
        if (usernameValid &&
            emailValid &&
            phoneNumberValid &&
            passwordValid &&
            userPicture != null &&
            userBanner != null) {
          settingsValid = true;
        }
      });
    } else {
      setState(() {
        if (media == "Picture") {
          userPicture = previousMedia;
        } else {
          userBanner = previousMedia;
        }
        if (usernameValid &&
            emailValid &&
            phoneNumberValid &&
            passwordValid &&
            userPicture != null &&
            userBanner != null) {
          settingsValid = true;
        }
      });
    }
  }

  _fetchMediaLibrary(String media) async {
    File previousMedia;
    if (media == "Picture") {
      previousMedia = userPicture;
    } else {
      previousMedia = userBanner;
    }
    File userMedia = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (userMedia != null) {
      setState(() {
        if (media == "Picture") {
          userPicture = userMedia;
        } else {
          userBanner = userMedia;
        }
        if (usernameValid &&
            emailValid &&
            phoneNumberValid &&
            passwordValid &&
            userPicture != null &&
            userBanner != null) {
          settingsValid = true;
        }
      });
    } else {
      setState(() {
        if (media == "Picture") {
          userPicture = previousMedia;
        } else {
          userBanner = previousMedia;
        }
        if (usernameValid &&
            emailValid &&
            phoneNumberValid &&
            passwordValid &&
            userPicture != null &&
            userBanner != null) {
          settingsValid = true;
        }
      });
    }
  }

  Future<Null> _mediaPicker(BuildContext context, String media) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new Center(
            child: new Material(
              type: MaterialType.transparency,
              child: new Container(
                height: 150.0,
                margin: EdgeInsets.symmetric(horizontal: 40.0),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  border: Border.all(
                    width: 1.0,
                    color: Color.fromRGBO(0, 150, 255, 1.0),
                  ),
                ),
                child: new Column(
                  children: <Widget>[
                    new Container(
                      height: 50.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1.0,
                            color: Color.fromRGBO(40, 40, 40, 1.0),
                          ),
                        ),
                      ),
                      child: new Text(
                        "Pick $media From...",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    new Expanded(
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new GestureDetector(
                              child: new Container(
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Icon(
                                      Icons.camera,
                                      color: Color.fromRGBO(170, 170, 170, 1.0),
                                    ),
                                    new Text(
                                      "Camera",
                                      style: TextStyle(
                                        color:
                                            Color.fromRGBO(170, 170, 170, 1.0),
                                        fontSize: 18.0,
                                        fontFamily: "Century Gothic",
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                print("CAMERA");
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                _fetchCamera(media);
                              },
                            ),
                          ),
                          new Container(
                            width: 1.0,
                            color: Color.fromRGBO(40, 40, 40, 1.0),
                          ),
                          new Expanded(
                            child: new Row(
                              children: <Widget>[
                                new Expanded(
                                  child: new GestureDetector(
                                    child: new Container(
                                      color: Colors.transparent,
                                      alignment: Alignment.center,
                                      child: new Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          new Icon(
                                            Icons.photo_library,
                                            color: Color.fromRGBO(
                                                170, 170, 170, 1.0),
                                          ),
                                          new Text(
                                            "Library",
                                            style: TextStyle(
                                              color: Color.fromRGBO(
                                                  170, 170, 170, 1.0),
                                              fontSize: 18.0,
                                              fontFamily: "Century Gothic",
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      print("PHOTO LIBRARY");
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                      _fetchMediaLibrary(media);
                                    },
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
          );
        });
  }

  _handleProfileUpdate(Map<dynamic, dynamic> userPreviousInfo,
      Map<dynamic, dynamic> userUpdatedInfo) async {
    setState(() {
      updateInProgress = true;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: userPreviousInfo["userEmail"],
              password: userPreviousInfo["userPassword"])
          .then((firebaseUser) {
        firebaseUser
          ..updateEmail(userUpdatedInfo["userEmail"]).catchError(() {
            setState(() {
              updateInProgress = false;
              emailValid = false;
            });
          })
          ..updatePassword(userUpdatedInfo["userPassword"]);
      }).whenComplete(() async {
        if (userPicture != null && userBanner != null) {
          FirebaseStorage.instance
              .ref()
              .child("Users/${userPreviousInfo["userID"]}/picture/picture.png")
              .putFile(userPicture)
              .onComplete
              .then((userPicture) async {
            FirebaseStorage.instance
                .ref()
                .child("Users/${userPreviousInfo["userID"]}/banner/banner.png")
                .putFile(userBanner)
                .onComplete
                .then((userBanner) async {
              await FirebaseStorage.instance
                  .ref()
                  .child(
                      "Users/${userPreviousInfo["userID"]}/picture/picture.png")
                  .getDownloadURL()
                  .then((userPictureURL) async {
                await FirebaseStorage.instance
                    .ref()
                    .child(
                        "Users/${userPreviousInfo["userID"]}/banner/banner.png")
                    .getDownloadURL()
                    .then((userBannerURL) async {
                  await Firestore.instance
                      .document("Users/${userPreviousInfo["userID"]}")
                      .updateData({
                    "userUsername": userUpdatedInfo["userUsername"],
                    "userEmail": userUpdatedInfo["userEmail"],
                    "userFirstName": userUpdatedInfo["userFirstName"],
                    "userLastName": userUpdatedInfo["userLastName"],
                    "userPhoneNumber": userUpdatedInfo["userPhoneNumber"],
                    "userPreferredRegion":
                        userUpdatedInfo["userPreferredRegion"],
                    "userPassword": userUpdatedInfo["userPassword"],
                    "userPicture": userPictureURL,
                    "userBanner": userBannerURL,
                  }).then((_) {
                    setState(() {
                      updateInProgress = false;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (BuildContext context) => new MasterPage(
                                currentIndex: 4,
                              ),
                        ),
                      );
                    });
                  });
                });
              });
            });
          });
        } else {
          await Firestore.instance
              .document("Users/${userPreviousInfo["userID"]}")
              .updateData({
            "userUsername": userUpdatedInfo["userUsername"],
            "userEmail": userUpdatedInfo["userEmail"],
            "userFirstName": userUpdatedInfo["userFirstName"],
            "userLastName": userUpdatedInfo["userLastName"],
            "userPhoneNumber": userUpdatedInfo["userPhoneNumber"],
            "userPreferredRegion": userUpdatedInfo["userPreferredRegion"],
            "userPassword": userUpdatedInfo["userPassword"],
            "userPicture": userInfo["userPicture"],
            "userBanner": userInfo["userBanner"],
          }).then((_) {
            setState(() {
              updateInProgress = false;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (BuildContext context) => new MasterPage(
                        currentIndex: 4,
                      ),
                ),
              );
            });
          });
        }
      });
    } catch (error) {
      setState(() {
        updateInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        centerTitle: true,
        title: new Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: updateInProgress
            ? new Icon(
                Icons.arrow_back_ios,
                color: Color.fromRGBO(170, 170, 170, 1.0),
              )
            : new BackButton(
                color: Color.fromRGBO(0, 150, 255, 1.0),
              ),
        actions: <Widget>[
          new GestureDetector(
            child: new Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(right: 10.0),
              color: Colors.transparent,
              child: new Text(
                "Save",
                style: TextStyle(
                  color: settingsValid
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              if (settingsValid) {
                print("SAVE");
                _handleProfileUpdate(previousUserInfo, userInfo);
              }
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new GestureDetector(
            child: new ListView(
              shrinkWrap: true,
              children: <Widget>[
                new Container(
                  height: 160.0,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(50, 50, 50, 1.0),
                    image: DecorationImage(
                      image: userBanner != null
                          ? FileImage(userBanner)
                          : NetworkImage(userInfo["userBanner"]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: new Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      new Container(
                        child: new Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            new GestureDetector(
                              child: new CircleAvatar(
                                radius: 50.0,
                                backgroundColor:
                                    Color.fromRGBO(0, 150, 255, 1.0),
                                child: new CircleAvatar(
                                  radius: 46.0,
                                  backgroundColor:
                                      Color.fromRGBO(50, 50, 50, 1.0),
                                  backgroundImage: userPicture != null
                                      ? FileImage(userPicture)
                                      : NetworkImage(userInfo["userPicture"]),
                                ),
                              ),
                              onTap: () {
                                _mediaPicker(context, "Picture");
                              },
                            ),
                            new Container(
                                margin: EdgeInsets.only(top: 2.0, bottom: 3.0),
                                child: new Text(
                                  userInfo["userUsername"],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                    fontFamily: "Century Gothic",
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      new GestureDetector(
                        child: new Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(left: 75.0, bottom: 30.0),
                          height: 25.0,
                          width: 25.0,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(0, 150, 255, 1.0),
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.5)),
                          ),
                          child: new Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _mediaPicker(context, "Picture");
                        },
                      ),
                      new Align(
                        alignment: Alignment.topRight,
                        child: new GestureDetector(
                          child: new Container(
                            margin: EdgeInsets.only(top: 10.0, right: 10.0),
                            width: 30.0,
                            height: 25.0,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(0, 150, 255, 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2.0)),
                            ),
                            child: new Icon(
                              Icons.brush,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _mediaPicker(context, "Banner");
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(top: 10.0, bottom: 20.0),
                  height: 60.0,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
                        constraints: BoxConstraints(maxWidth: 370.0),
                        child: new Text(
                          "Username",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 16.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      new CustomTextfield(
                        height: 30.0,
                        textFontSize: 18.0,
                        margin: EdgeInsets.symmetric(horizontal: 40.0),
                        maxWidth: 350.0,
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                        controller: usernameTextController,
                        enabledBorderColor:
                            usernameTextController.text.isNotEmpty
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                        inputFormatters: [LowerCaseTextFormatter()],
                        autovalidate: true,
                        maxLength: 15,
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
                            } else {
                              usernameValid = true;
                              return "";
                            }
                            // else if (usernameExists == true) {
                            //   userValid = false;
                            //   return "Username is taken";
                            // }
                          } else {
                            usernameValid = false;
                            return "";
                          }
                        },
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  height: 60.0,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
                        constraints: BoxConstraints(maxWidth: 370.0),
                        child: new Text(
                          "Email",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 16.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      new CustomTextfield(
                        height: 30.0,
                        textFontSize: 18.0,
                        margin: EdgeInsets.symmetric(horizontal: 40.0),
                        maxWidth: 350.0,
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                        controller: emailTextController,
                        keyboardType: TextInputType.emailAddress,
                        enabledBorderColor: emailTextController.text.isNotEmpty
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(40, 40, 40, 1.0),
                        inputFormatters: [LowerCaseTextFormatter()],
                        autovalidate: true,
                        validator: (emailText) {
                          if (emailText.trim().length > 0) {
                            if (!emailExp.hasMatch(emailText)) {
                              emailValid = false;
                              return "Email is invalid";
                            } else {
                              emailValid = true;
                              return "";
                            }
                            // else if (emailExists == true) {
                            //   emailValid = false;
                            //   return "Already an Account with this email";
                            // }
                          } else {
                            emailValid = false;
                            return "";
                          }
                        },
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  height: 60.0,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
                        constraints: BoxConstraints(maxWidth: 370.0),
                        child: new Text(
                          "First Name",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 16.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      new CustomTextfield(
                        height: 30.0,
                        textFontSize: 18.0,
                        margin: EdgeInsets.symmetric(horizontal: 40.0),
                        maxWidth: 350.0,
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                        controller: firstNameTextController,
                        enabledBorderColor:
                            firstNameTextController.text.isNotEmpty
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                        maxLength: 20,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  height: 60.0,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
                        constraints: BoxConstraints(maxWidth: 370.0),
                        child: new Text(
                          "Last Name",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 16.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      new CustomTextfield(
                        height: 30.0,
                        textFontSize: 18.0,
                        margin: EdgeInsets.symmetric(horizontal: 40.0),
                        maxWidth: 350.0,
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                        controller: lastNameTextController,
                        enabledBorderColor:
                            lastNameTextController.text.isNotEmpty
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                        maxLength: 20,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  height: 60.0,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
                        constraints: BoxConstraints(maxWidth: 370.0),
                        child: new Text(
                          "Phone Number",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 16.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      new CustomTextfield(
                        height: 30.0,
                        textFontSize: 18.0,
                        margin: EdgeInsets.symmetric(horizontal: 40.0),
                        maxWidth: 350.0,
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                        controller: phoneNumberTextController,
                        enabledBorderColor:
                            phoneNumberTextController.text.isNotEmpty
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                        keyboardType: TextInputType.number,
                        autovalidate: true,
                        validator: (phoneNumber) {
                          if (phoneNumber.length > 0) {
                            if (phoneNumber.trim().length != 14) {
                              phoneNumberValid = false;
                              return "Phone Number is invalid";
                            } else {
                              phoneNumberValid = true;
                              return "";
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  height: 60.0,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
                        constraints: BoxConstraints(maxWidth: 370.0),
                        child: new Text(
                          "Preferred Region",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 16.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      new GestureDetector(
                        child: new Container(
                          height: 35.0,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 10.0),
                          margin: EdgeInsets.symmetric(horizontal: 40.0),
                          constraints: BoxConstraints(maxWidth: 350.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(5, 5, 10, 1.0),
                            border: Border.all(
                              width: 1.0,
                              color: userInfo["userPreferredRegion"] != ""
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: new Text(
                            userInfo["userPreferredRegion"],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontFamily: "Avenir",
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () {
                          _selectPreferredRegion(context);
                        },
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  height: 60.0,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      new Container(
                        padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
                        constraints: BoxConstraints(maxWidth: 370.0),
                        child: new Text(
                          "Password",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 16.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      new CustomTextfield(
                        height: 30.0,
                        textFontSize: 18.0,
                        margin: EdgeInsets.symmetric(horizontal: 40.0),
                        maxWidth: 350.0,
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                        controller: passwordTextController,
                        enabledBorderColor:
                            passwordTextController.text.isNotEmpty
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
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
                    ],
                  ),
                ),
                new GestureDetector(
                child: new Container(
                  alignment: Alignment.center,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(23, 23, 23, 1.0),
                    border: Border(
                      top: BorderSide(
                        width: 1.0,
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                  ),
                  child: new Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  _handleLogOut();
                },
            ),
              ],
            ),
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
          updateInProgress
              ? new Center(
                  child: new CircularProgressIndicator(
                    backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                  ),
                )
              : new Container(),
        ],
      ),
    );
  }
}

class SettingsTitle extends StatefulWidget {
  _SettingsTitle createState() => new _SettingsTitle();

  final String title;

  SettingsTitle({Key key, @required this.title}) : super(key: key);
}

class _SettingsTitle extends State<SettingsTitle> {
  Widget build(BuildContext context) {
    return new Container(
      margin: EdgeInsets.only(top: 10.0),
      height: 60.0,
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            padding: EdgeInsets.only(left: 20.0, bottom: 3.0),
            constraints: BoxConstraints(maxWidth: 370.0),
            child: new Text(
              widget.title,
              style: TextStyle(
                  color: Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 16.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold),
            ),
          ),
          new CustomTextfield(
            height: 30.0,
            textFontSize: 18.0,
            margin: EdgeInsets.symmetric(horizontal: 40.0),
            maxWidth: 350.0,
            contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
          ),
        ],
      ),
    );
  }
}
