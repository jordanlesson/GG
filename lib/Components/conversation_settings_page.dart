import 'package:flutter/material.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'package:gg/UI/user_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ConversationSettingsPage extends StatefulWidget {
  _ConversationSettingsPage createState() => new _ConversationSettingsPage();

  final Map<dynamic, dynamic> conversation;
  final String currentUser;

  ConversationSettingsPage(
      {Key key, @required this.conversation, @required this.currentUser})
      : super(key: key);
}

class _ConversationSettingsPage extends State<ConversationSettingsPage> {
  Map<dynamic, dynamic> conversation;
  String _currentUser;
  List<Map<dynamic, dynamic>> users;
  bool conversationUsersLoaded;
  File conversationMedia;
  bool updateInProgress;
  TextEditingController conversationNameTextController;

  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    conversation = Map.from(widget.conversation);
    List conversationUsers = List.from(conversation["conversationUsers"]);
    conversationUsers.remove(_currentUser);

    conversationUsersLoaded = false;
    updateInProgress = false;

    conversationNameTextController = TextEditingController()
      ..addListener(conversationName);

    conversationNameTextController.text = conversation["conversationName"];

    _fetchConversationUsers(conversationUsers);
  }

  conversationName() {
    if (conversationNameTextController.text.isNotEmpty) {
      conversation["conversationName"] = conversationNameTextController.text;
    } else {
      conversation["conversationName"] =
          widget.conversation["conversationName"];
    }
  }

  _fetchConversationUsers(List conversationUsers) async {
    users = [];
    int number = 0;

    for (String conversationUser in conversationUsers) {
      await Firestore.instance
          .document("Users/$conversationUser")
          .get()
          .then((userInfo) {
        if (userInfo.exists) {
          number = number + 1;
          users.add(userInfo.data);
          if (number == conversationUsers.length) {
            setState(() {
              conversationUsersLoaded = true;
            });
          }
        }
      });
    }
  }

  _fetchCamera(String media) async {
    File previousMedia;

    if (conversationMedia != null) {
      previousMedia = conversationMedia;
    }

    File conversationPicture =
        await ImagePicker.pickImage(source: ImageSource.camera);

    if (conversationPicture != null) {
      setState(() {
        conversationMedia = conversationPicture;
      });
    } else {
      setState(() {
        conversationMedia = previousMedia;
      });
    }
  }

  _fetchMediaLibrary(String media) async {
    File previousMedia;

    if (conversationMedia != null) {
      previousMedia = conversationMedia;
    }

    File conversationPicture =
        await ImagePicker.pickImage(source: ImageSource.gallery);
    if (conversationPicture != null) {
      setState(() {
        conversationMedia = conversationPicture;
      });
    } else {
      setState(() {
        if (media == "Picture") {
          conversationMedia = previousMedia;
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

  _handleConversationUpdate(Map<dynamic, dynamic> conversation) async {
    setState(() {
      updateInProgress = true;
    });
    StorageReference storageRef = FirebaseStorage.instance.ref().child(
        "Conversations/${conversation["conversationID"]}/picture/picture.png");
    try {
      if (conversationMedia != null) {
        storageRef
            .putFile(conversationMedia)
            .onComplete
            .then((conversationPictureInfo) {
          storageRef.getDownloadURL().then((conversationPictureURL) {
            Firestore.instance
                .document("Conversations/${conversation["conversationID"]}")
                .updateData({
              "conversationName": conversation["conversationName"],
              "conversationPicture": conversationPictureURL,
            }).then((_) {
              setState(() {
                updateInProgress = false;
              });
              Navigator.of(context).pop();
            });
          });
        });
      } else {
        print(conversation["conversationID"]);
        Firestore.instance
            .document("Conversations/${conversation["conversationID"]}")
            .get()
            .then((conversationInfo) {
              print(conversationInfo.data);
          if (conversationInfo.exists) {
            print(conversation["conversationName"]);
            Firestore.instance
                .document("Conversations/${conversation["conversationID"]}")
                .updateData({
              "conversationName": conversation["conversationName"],
            }).then((_) {
              print("HELLO");
              setState(() {
                updateInProgress = false;
                Navigator.of(context).pop();
              });
            });
          }
        });
      }
    } catch (error) {
      print("Error: $error");
      setState(() {
        updateInProgress = false;
      });
    }
  }

  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Scaffold(
        backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
        resizeToAvoidBottomPadding: false,
        appBar: new AppBar(
          backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
          title: new Text(
            "Info",
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
            conversation["conversationUsers"].length > 2
                ? new GestureDetector(
                    child: new Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.only(right: 10.0),
                      color: Colors.transparent,
                      child: new Text(
                        "Save",
                        style: TextStyle(
                          color: Color.fromRGBO(0, 150, 255, 1.0),
                          fontSize: 20.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      _handleConversationUpdate(conversation);
                    },
                  )
                : new Container(),
          ],
          elevation: 0.0,
        ),
        body: new Stack(
          children: <Widget>[
            new Column(
              children: <Widget>[
                conversation["conversationUsers"].length > 2
                    ? new Container(
                        height: 50.0,
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1.0,
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: new TextField(
                          maxLines: 1,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontFamily: "Avenir",
                              fontWeight: FontWeight.bold),
                          controller: conversationNameTextController,
                          decoration: InputDecoration.collapsed(
                            hintText: "Conversation Name",
                            hintStyle: TextStyle(
                                color: Color.fromRGBO(170, 170, 170, 1.0),
                                fontSize: 18.0,
                                fontFamily: "Avenir",
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    : new Container(),
                new CustomScrollView(
                  shrinkWrap: true,
                  slivers: <Widget>[
                    new SliverToBoxAdapter(
                      child: new Column(
                        children: <Widget>[
                          conversation["conversationUsers"].length > 2
                              ? new Container(
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.only(top: 20.0),
                                  child: new GestureDetector(
                                    child: new Stack(
                                      alignment: Alignment.bottomLeft,
                                      children: <Widget>[
                                        new CircleAvatar(
                                          radius: 50.0,
                                          backgroundColor:
                                              Color.fromRGBO(0, 150, 255, 1.0),
                                          child: new CircleAvatar(
                                            radius: 46.0,
                                            backgroundColor:
                                                Color.fromRGBO(50, 50, 50, 1.0),
                                            backgroundImage:
                                                conversationMedia != null
                                                    ? FileImage(
                                                        conversationMedia)
                                                    : NetworkImage(
                                                        conversation["conversationPicture"],
                                                      ),
                                          ),
                                        ),
                                        new Container(
                                          alignment: Alignment.center,
                                          margin: EdgeInsets.only(
                                              left: 75.0, bottom: 10.0),
                                          height: 25.0,
                                          width: 25.0,
                                          decoration: BoxDecoration(
                                            color: Color.fromRGBO(
                                                0, 150, 255, 1.0),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(12.5)),
                                          ),
                                          child: new Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 20.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      _mediaPicker(context, "Picture");
                                    },
                                  ),
                                )
                              : new Container(),
                          new Container(
                            height: 50.0,
                            color: Color.fromRGBO(23, 23, 23, 1.0),
                            alignment: Alignment.bottomLeft,
                            child: new Container(
                              margin: EdgeInsets.only(left: 10.0, bottom: 10.0),
                              child: new Text(
                                "Members",
                                style: new TextStyle(
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 17.0,
                                  fontFamily: "Avenir",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    conversationUsersLoaded
                        ? new SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (BuildContext context, int index) {
                                Map<dynamic, dynamic> user = users[index];
                                return conversationUsersLoaded
                                    ? new Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 15.0),
                                        child: new UserBox(
                                          user: user,
                                          currentUser: _currentUser,
                                        ),
                                      )
                                    : new Container(
                                        margin: EdgeInsets.only(top: 100.0),
                                        alignment: Alignment.center,
                                        child: new CircularProgressIndicator(
                                          backgroundColor:
                                              Color.fromRGBO(0, 150, 255, 1.0),
                                        ),
                                      );
                              },
                              childCount:
                                  conversationUsersLoaded ? users.length : 1,
                            ),
                          )
                        : new SliverToBoxAdapter(
                            child: new Container(
                              child: new Center(
                                child: new CircularProgressIndicator(
                                  backgroundColor:
                                      Color.fromRGBO(0, 150, 255, 1.0),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ],
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
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }
}
