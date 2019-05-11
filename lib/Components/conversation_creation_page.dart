import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/UI/user_box.dart';
import 'package:gg/Utilities/formatters.dart';
import 'dart:collection';
import 'messages_page.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'media_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'dart:typed_data';

class ConversationCreationPage extends StatefulWidget {
  _ConversationCreationPage createState() => new _ConversationCreationPage();

  final String currentUser;

  ConversationCreationPage({Key key, @required this.currentUser})
      : super(key: key);
}

class _ConversationCreationPage extends State<ConversationCreationPage> {
  String _currentUser;
  TextEditingController searchTextController;
  TextEditingController messageTextController;
  bool messageReady;
  bool messageMediaLoaded;
  File messageMedia;
  String messageMediaType;
  List<String> conversationUsers;
  List<String> conversationUsernames;
  VideoPlayerController messageMediaController;
  bool checkInProgress;

  void initState() {
    super.initState();

    _currentUser = widget.currentUser;
    conversationUsers = new List();
    conversationUsernames = new List();

    checkInProgress = false;
    messageReady = false;
    messageMediaLoaded = false;

    messageTextController = TextEditingController()..addListener(messageTyping);

    searchTextController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });
  }

  messageTyping() {
    if (messageTextController.text.isEmpty && messageMedia == null) {
      setState(() {
        messageReady = false;
      });
    } else {
      setState(() {
        messageReady = true;
      });
    }
  }

  _handleMessage(String currentUser, String messageText, File media,
      String mediaType, String conversationID) async {
    print(messageText);

    setState(() {
      messageTextController.clear();
      messageMedia = null;
      messageMediaLoaded = false;
    });

    DateTime messageDate = DateTime.now();

    try {
      await Firestore.instance.collection("Messages").add({
        "messageBody": messageText,
        "messageDate": messageDate.toUtc(),
        "messageUserID": currentUser,
        "messageConversationID": "",
        "messagePicture": "",
        "messageVideo": "",
      }).then((messageInfo) async {
        print(messageInfo.documentID);

        if (media != null) {
          dynamic pictureDownloadUrl = "";
          dynamic videoDownloadUrl = "";
          StorageReference mediaRef;
          print(mediaType);
          if (mediaType == "Image") {
            mediaRef = FirebaseStorage.instance
                .ref()
                .child("Messages/${messageInfo.documentID}/media.png");
          } else {
            mediaRef = FirebaseStorage.instance
                .ref()
                .child("Messages/${messageInfo.documentID}/media.mov");
          }

          print(mediaRef);

          mediaRef.putFile(media).onComplete.then((_) async {
            if (messageMediaType == "Image") {
              pictureDownloadUrl = await mediaRef.getDownloadURL();
            } else {
              videoDownloadUrl = await mediaRef.getDownloadURL();
            }
          }).then((_) {
            Firestore.instance
                .document("Messages/${messageInfo.documentID}")
                .updateData({
              "messagePicture": pictureDownloadUrl.toString(),
              "messageVideo": videoDownloadUrl.toString(),
              "messageConversationID": conversationID,
            }).then((_) {
              if (messageText != "" && messageText != null) {
                Firestore.instance
                    .runTransaction((Transaction transaction) async {
                  await transaction
                      .get(Firestore.instance
                          .document("Conversations/$conversationID"))
                      .then((conversationInfo) async {
                    if (conversationInfo.exists) {
                      Map<String, dynamic> conversationRead =
                          Map.from(conversationInfo["conversationRead"]);
                      int number = 0;
                      for (String conversationUser in conversationRead.keys) {
                        if (conversationUser != currentUser) {
                          conversationRead[conversationUser] = false;
                        } else {
                          conversationRead[currentUser] = true;
                        }
                        print(conversationRead);
                        number = number + 1;
                        if (number ==
                            conversationInfo["conversationUsers"].length) {
                          await transaction.update(
                              Firestore.instance
                                  .document("Conversations/$conversationID"),
                              <String, dynamic>{
                                "conversationBody": messageText,
                                "conversationDate": messageDate.toUtc(),
                                "conversationRead": conversationRead,
                              });
                        }
                      }
                    }
                  });
                });
              }
            });
          });
        } else {
          Firestore.instance
              .document("Messages/${messageInfo.documentID}")
              .updateData({
            "messagePicture": "",
            "messageVideo": "",
            "messageConversationID": conversationID,
          }).then((_) {
            if (messageText != "" && messageText != null) {
              Firestore.instance
                  .runTransaction((Transaction transaction) async {
                await transaction
                    .get(Firestore.instance
                        .document("Conversations/$conversationID"))
                    .then((conversationInfo) async {
                  if (conversationInfo.exists) {
                    Map<String, dynamic> conversationRead =
                        Map.from(conversationInfo["conversationRead"]);
                    int number = 0;
                    for (String conversationUser in conversationRead.keys) {
                      if (conversationUser != currentUser) {
                        conversationRead[conversationUser] = false;
                      } else {
                        conversationRead[currentUser] = true;
                      }
                      print(conversationRead);
                      number = number + 1;
                      if (number ==
                          conversationInfo["conversationUsers"].length) {
                        await transaction.update(
                            Firestore.instance
                                .document("Conversations/$conversationID"),
                            <String, dynamic>{
                              "conversationBody": messageText,
                              "conversationDate": messageDate.toUtc(),
                              "conversationRead": conversationRead,
                            });
                      }
                    }
                  }
                });
              });
            }
          });
        }
      });
    } catch (error) {
      print("MESSAGE ERROR: $error");
    }
  }

  _handleConversation(List conversationUsers, String messageText, File media,
      String mediaType) async {
    setState(() {
      checkInProgress = true;
    });
    List conversationUserIDS = List.from(conversationUsers);
    conversationUserIDS.add(_currentUser);
    Firestore.instance
        .collection("Conversations")
        .where("conversationUsers", arrayContains: _currentUser)
        .getDocuments()
        .then((conversationDocuments) async {
      bool conversationExist = false;
      int number = 0;
      if (conversationDocuments.documents.isNotEmpty) {
      for (DocumentSnapshot conversationInfo
          in conversationDocuments.documents) {
        number = number + 1;
        Set convoUsers = Set.from(conversationInfo.data["conversationUsers"]);
        print(convoUsers);
        print(conversationUserIDS);
        if (convoUsers.containsAll(conversationUserIDS) &&
            conversationUserIDS.length == convoUsers.length) {
          conversationExist = true;
          setState(() {
            checkInProgress = false;
          });
          _handleMessage(_currentUser, messageText, messageMedia,
              messageMediaType, conversationInfo.documentID);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) => new MessagesPage(
                    conversation: conversationInfo.data,
                    conversationID: conversationInfo.documentID,
                    currentUser: _currentUser,
                  ),
            ),
          );
        }
        if (number == conversationDocuments.documents.length &&
            conversationExist != true) {
          Map<String, dynamic> conversationRead = new Map();
          for (String conversationUser in conversationUserIDS) {
            conversationRead.addAll({
              conversationUser: false,
            });
          }
          try {
            int defaultPicture = Random().nextInt(38);

            ByteData bytes = await rootBundle
                .load("assets/default/default$defaultPicture.png");
            Directory tempDir = Directory.systemTemp;
            String fileName = "$defaultPicture.png";
            File file = File("${tempDir.path}/$fileName");
            file.writeAsBytes(bytes.buffer.asUint8List(), mode: FileMode.write);

            DateTime messageDate = DateTime.now();

            Firestore.instance.collection("Conversations").add({
              "conversationName": conversationUsernames.join(", "),
              "conversationDate": messageDate,
              "conversationBody": messageText,
              "conversationUsers": conversationUserIDS,
            }).then((newConversationInfo) {
              StorageReference conversationPictureRef = FirebaseStorage.instance
                  .ref()
                  .child(
                      "Conversations/${newConversationInfo.documentID}/picture/picture.png");
              conversationPictureRef.putFile(file).onComplete.then((_) async {
                await conversationPictureRef
                    .getDownloadURL()
                    .then((conversationPictureURL) {
                  Firestore.instance
                      .document(
                          "Conversations/${newConversationInfo.documentID}")
                      .setData({
                    "conversationID": newConversationInfo.documentID,
                    "conversationRead": conversationRead,
                    "conversationPicture": conversationPictureURL.toString(),
                  }, merge: true).then((_) {
                    _handleMessage(_currentUser, messageText, media, mediaType,
                        newConversationInfo.documentID);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (BuildContext context) => new MessagesPage(
                            conversation: {
                              "conversationName":
                                  conversationUsernames.join(", "),
                              "conversationDate": messageDate,
                              "conversationBody": messageText,
                              "conversationUsers": conversationUserIDS,
                              "conversationID": newConversationInfo.documentID,
                              "conversationRead": conversationRead,
                              "conversationPicture":
                                  conversationPictureURL.toString(),
                            },
                            conversationID: newConversationInfo.documentID,
                            currentUser: _currentUser,
                          ),
                    ));
                  });
                });
              });
            });
          } catch (error) {
            print("Error: $error");
          }
        }
      }
        } else {
          Map<String, dynamic> conversationRead = new Map();
          for (String conversationUser in conversationUserIDS) {
            conversationRead.addAll({
              conversationUser: false,
            });

            print("STEP 1");
          }
          try {
            int defaultPicture = Random().nextInt(38);

            ByteData bytes = await rootBundle
                .load("assets/default/default$defaultPicture.png");
            Directory tempDir = Directory.systemTemp;
            String fileName = "$defaultPicture.png";
            File file = File("${tempDir.path}/$fileName");
            file.writeAsBytes(bytes.buffer.asUint8List(), mode: FileMode.write);

            print("SETP 2");

            DateTime messageDate = DateTime.now();

            Firestore.instance.collection("Conversations").add({
              "conversationName": conversationUsernames.join(", "),
              "conversationDate": messageDate,
              "conversationBody": messageText,
              "conversationUsers": conversationUserIDS.toList(),
            }).then((newConversationInfo) {
              StorageReference conversationPictureRef = FirebaseStorage.instance
                  .ref()
                  .child(
                      "Conversations/${newConversationInfo.documentID}/picture/picture.png");
              conversationPictureRef.putFile(file).onComplete.then((_) async {
                await conversationPictureRef
                    .getDownloadURL()
                    .then((conversationPictureURL) {
                  Firestore.instance
                      .document(
                          "Conversations/${newConversationInfo.documentID}")
                      .setData({
                    "conversationID": newConversationInfo.documentID,
                    "conversationRead": conversationRead,
                    "conversationPicture": conversationPictureURL.toString(),
                  }, merge: true).then((_) {
                    _handleMessage(_currentUser, messageText, media, mediaType,
                        newConversationInfo.documentID);
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (BuildContext context) => new MessagesPage(
                            conversation: {
                              "conversationName":
                                  conversationUsernames.join(", "),
                              "conversationDate": messageDate,
                              "conversationBody": messageText,
                              "conversationUsers": conversationUserIDS.toList(),
                              "conversationID": newConversationInfo.documentID,
                              "conversationRead": conversationRead,
                              "conversationPicture":
                                  conversationPictureURL.toString(),
                            },
                            conversationID: newConversationInfo.documentID,
                            currentUser: _currentUser,
                          ),
                    ));
                  });
                });
              });
            });
          } catch (error) {
            print("Error: $error");
          }
        }
    });
  }

  _fetchStream(String searchQuery) {
    if (searchQuery != "") {
      var strSearch = searchQuery;
      var strlength = strSearch.length;
      var strFrontCode = strSearch.substring(0, strlength - 1);
      var strEndCode = strSearch.substring(strlength - 1, strSearch.length);

      var startcode = strSearch;
      var endcode =
          strFrontCode + String.fromCharCode(strEndCode.codeUnitAt(0) + 1);

      return Firestore.instance
          .collection("Users")
          // .where("userFollowers", arrayContains: _currentUser)
          .where("userUsername", isGreaterThanOrEqualTo: startcode)
          .where("userUsername", isLessThan: endcode)
          .snapshots();
    }
    return new Stream<QuerySnapshot>.empty();
  }

  _fetchCamera(String media) async {
    File previousMessageMedia = messageMedia;
    if (media == "Image") {
      messageMedia = await ImagePicker.pickImage(source: ImageSource.camera);
    } else {
      messageMedia = await ImagePicker.pickVideo(source: ImageSource.camera);
    }
    if (messageMedia != null) {
      setState(() {
        messageMediaType = media;
        messageMediaLoaded = true;
        messageReady = true;
      });
      if (messageMediaType == "Video") {
        messageMediaController = VideoPlayerController.file(messageMedia)
          ..initialize().then((_) {
            setState(() {});
          });
      }
    } else {
      setState(() {
        messageMedia = previousMessageMedia;
        if (messageMediaType == "Video") {
          messageMediaController = VideoPlayerController.file(messageMedia)
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    }
  }

  _fetchMediaLibrary(String media) async {
    File previousMessageMedia = messageMedia;
    if (media == "Image") {
      messageMedia = await ImagePicker.pickImage(source: ImageSource.gallery);
    } else {
      messageMedia = await ImagePicker.pickVideo(source: ImageSource.gallery);
    }
    if (messageMedia != null) {
      setState(() {
        messageMediaType = media;
        messageMediaLoaded = true;
        messageReady = true;
        if (messageMediaType == "Video") {
          messageMediaController = VideoPlayerController.file(messageMedia)
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    } else {
      setState(() {
        messageMedia = previousMessageMedia;
        if (messageMediaType == "Video") {
          messageMediaController = VideoPlayerController.file(messageMedia)
            ..initialize().then((_) {
              setState(() {});
            });
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

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Create",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: checkInProgress
            ? new Icon(
                Icons.arrow_back_ios,
                color: Color.fromRGBO(170, 170, 170, 1.0),
              )
            : new BackButton(
                color: Color.fromRGBO(0, 150, 255, 1.0),
              ),
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new Column(
            children: <Widget>[
              conversationUsers.isNotEmpty
                  ? new Container(
                      height: 50.0,
                      child: new ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 5.0),
                        itemBuilder: (BuildContext context, int index) {
                          return new Container(
                            alignment: Alignment.center,
                            margin: EdgeInsets.only(right: 5.0),
                            child: new Container(
                              padding: EdgeInsets.only(
                                  left: 10.0,
                                  right: 10.0,
                                  top: 2.0,
                                  bottom: 2.0),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(0, 150, 255, 1.0),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  new Container(
                                      child: new Text(
                                    conversationUsernames[index],
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        fontFamily: "Avenir",
                                        fontWeight: FontWeight.bold),
                                  )),
                                  new GestureDetector(
                                    child: new Icon(
                                      Icons.clear,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        conversationUsers.removeAt(index);
                                        conversationUsernames.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: conversationUsers.length,
                      ),
                    )
                  : new Container(),
              new Container(
                constraints: BoxConstraints(
                  minHeight: 50.0,
                ),
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
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
                  maxLines: null,
                  autocorrect: false,
                  autofocus: true,
                  inputFormatters: [LowerCaseTextFormatter()],
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontFamily: "Avenir",
                      fontWeight: FontWeight.bold),
                  controller: searchTextController,
                  decoration: InputDecoration.collapsed(
                    hintText: "Add People to Chat With...",
                    hintStyle: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 18.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              new Expanded(
                child: new StreamBuilder(
                  stream: _fetchStream(searchTextController.text),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return new Center(
                        child: new Text(
                          "No Users Found",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    } else if (userSnapshot.data.documents.isEmpty) {
                      return new Center(
                        child: new Text(
                          "No Users Found",
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    } else {
                      print(userSnapshot.data.documents.length);
                      return new ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 15.0),
                        itemBuilder: (BuildContext context, int index) {
                          Map<dynamic, dynamic> user =
                              Map.from(userSnapshot.data.documents[index].data);
                          if (user["userID"] != _currentUser &&
                              !conversationUsers.contains(user["userID"])) {
                            return new GestureDetector(
                              child: new UserBox(
                                user: user,
                                userBoxType: "Conversation",
                                currentUser: _currentUser,
                              ),
                              onTap: () {
                                setState(() {
                                  searchTextController.text = "";
                                  conversationUsers.add(user["userID"]);
                                  conversationUsernames
                                      .add(user["userUsername"]);
                                });
                              },
                            );
                          } else {
                            return new Container();
                          }
                        },
                        itemCount: userSnapshot.data.documents.length,
                      );
                    }
                  },
                ),
              ),
              new SafeArea(
                top: false,
                child: new Container(
                  constraints:
                      BoxConstraints(maxHeight: 200.0, minHeight: 50.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(23, 23, 23, 1.0),
                    border: Border(
                      top: BorderSide(
                        width: 1.0,
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                  ),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      new Material(
                        child: new Container(
                          alignment: Alignment.center,
                          height: 50.0,
                          color: Colors.transparent,
                          child: new IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                            ),
                            onPressed: () {
                              _mediaPicker(context, "Image");
                            },
                          ),
                        ),
                        color: Color.fromRGBO(23, 23, 23, 1.0),
                      ),
                      new Material(
                        child: new Container(
                          alignment: Alignment.center,
                          height: 50.0,
                          color: Colors.transparent,
                          child: new IconButton(
                            icon: Icon(
                              Icons.video_library,
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                            ),
                            onPressed: () {
                              _mediaPicker(context, "Video");
                            },
                          ),
                        ),
                        color: Color.fromRGBO(23, 23, 23, 1.0),
                      ),
                      new Flexible(
                        child: Container(
                          margin: EdgeInsets.only(left: 8.0),
                          padding: EdgeInsets.only(top: 5.0, bottom: 10.0),
                          child: messageMediaLoaded
                              ? new Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    new GestureDetector(
                                        child: new AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: new Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              border: Border.all(
                                                width: 1.0,
                                                color: Color.fromRGBO(
                                                    40, 40, 40, 1.0),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2.0),
                                            ),
                                            child: new Stack(
                                              fit: StackFit.expand,
                                              children: <Widget>[
                                                messageMediaType == "Image"
                                                    ? new Image.file(
                                                        messageMedia,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : new RotatedBox(
                                                        quarterTurns: 1,
                                                        child: new VideoPlayer(
                                                            messageMediaController),
                                                      ),
                                                new Align(
                                                  alignment: Alignment.topRight,
                                                  child: new Container(
                                                    color: Color.fromRGBO(
                                                        0, 150, 255, 1.0),
                                                    width: 40.0,
                                                    height: 40.0,
                                                    child: new IconButton(
                                                      icon: Icon(
                                                        Icons.clear,
                                                        color: Colors.white,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          messageMedia = null;
                                                          messageMediaLoaded =
                                                              false;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                messageMediaType == "Video"
                                                    ? new Center(
                                                        child: new Container(
                                                          height: 50.0,
                                                          width: 50.0,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Color.fromRGBO(
                                                                    40,
                                                                    40,
                                                                    40,
                                                                    0.7),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        25.0),
                                                          ),
                                                          child: new Icon(
                                                            Icons.play_arrow,
                                                            color:
                                                                Color.fromRGBO(
                                                                    255,
                                                                    255,
                                                                    255,
                                                                    0.7),
                                                            size: 40.0,
                                                          ),
                                                        ),
                                                      )
                                                    : new Container(),
                                              ],
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          FocusScope.of(context)
                                              .requestFocus(new FocusNode());
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder:
                                                (BuildContext context) {
                                              return new MediaPage(
                                                postMedia: messageMedia,
                                                postMediaType: messageMediaType,
                                                postMediaObject: "File",
                                                postVideoController:
                                                    messageMediaController,
                                              );
                                            }),
                                          ).then((_) {
                                            if (messageMediaType == "Video" &&
                                                messageMediaLoaded) {
                                              messageMediaController
                                                  .initialize()
                                                  .then((_) {
                                                setState(() {});
                                              });
                                            }
                                          });
                                        }),
                                    new Expanded(
                                      child: new Container(
                                        alignment: Alignment.bottomCenter,
                                        child: new Scrollbar(
                                          child: new TextField(
                                            maxLines: null,
                                            onTap: () {},
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18.0,
                                                fontFamily: "Avenir",
                                                fontWeight: FontWeight.bold),
                                            controller: messageTextController,
                                            decoration:
                                                InputDecoration.collapsed(
                                              hintText: "Say Something...",
                                              hintStyle: TextStyle(
                                                  color: Color.fromRGBO(
                                                      170, 170, 170, 1.0),
                                                  fontSize: 18.0,
                                                  fontFamily: "Avenir",
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : new Scrollbar(
                                  child: new TextField(
                                    maxLines: null,
                                    onTap: () {},
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.0,
                                        fontFamily: "Avenir",
                                        fontWeight: FontWeight.bold),
                                    controller: messageTextController,
                                    decoration: InputDecoration.collapsed(
                                      hintText: "Say Something...",
                                      hintStyle: TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontSize: 18.0,
                                          fontFamily: "Avenir",
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      new Material(
                        child: new GestureDetector(
                          child: new Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            margin: new EdgeInsets.symmetric(horizontal: 8.0),
                            height: 50.0,
                            width: 50.0,
                            child: new Text(
                              "Send",
                              style: TextStyle(
                                  color: messageReady
                                      ? Color.fromRGBO(0, 150, 255, 1.0)
                                      : Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 18.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          onTap: () {
                            if (messageReady && checkInProgress != true) {
                            setState(() {
                              checkInProgress = true;
                              _handleConversation(
                                  conversationUsers,
                                  messageTextController.text,
                                  messageMedia,
                                  messageMediaType);
                            });
                            }
                          },
                        ),
                        color: Color.fromRGBO(23, 23, 23, 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          checkInProgress
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
