import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'media_page.dart';
import 'conversation_settings_page.dart';

class MessagesPage extends StatefulWidget {
  _MessagesPage createState() => new _MessagesPage();

  final String conversationID;
  final Map<dynamic, dynamic> conversation;
  final String currentUser;

  MessagesPage(
      {Key key,
      @required this.conversationID,
      @required this.conversation,
      @required this.currentUser})
      : super(key: key);
}

class _MessagesPage extends State<MessagesPage> {
  String conversationID;
  Map<dynamic, dynamic> conversation;
  bool messageReady;
  bool messageMediaLoaded;
  String _currentUser;
  TextEditingController messageTextController;
  File messageMedia;
  String messageMediaType;
  VideoPlayerController messageMediaController;

  @override
  void initState() {
    super.initState();
    conversationID = widget.conversationID;
    conversation = widget.conversation;
    messageReady = false;
    messageMediaLoaded = false;
    _currentUser = widget.currentUser;
    messageTextController = new TextEditingController()
      ..addListener(messageTyping);
  }

  @override
  void dispose() {
    super.dispose();
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
      String mediaType) async {
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
        title: new StreamBuilder(
          stream: Firestore.instance
              .document("Conversations/$conversationID")
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<DocumentSnapshot> conversationSnapshot) {
            if (!conversationSnapshot.hasData) {
              return new Text(
                conversation["conversationName"],
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontFamily: "Century Gothic",
                    fontWeight: FontWeight.bold),
              );
            } else {
              String conversationName =
                  conversationSnapshot.data.data["conversationName"];
              if (conversationName == "") {
                conversationName = conversation["conversationName"];
              }
              return new Text(
                conversationName,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontFamily: "Century Gothic",
                    fontWeight: FontWeight.bold),
              );
            }
          },
        ),
        centerTitle: true,
        leading: new BackButton(
          color: Color.fromRGBO(0, 150, 255, 1.0),
        ),
        actions: <Widget>[
          new IconButton(
            icon: Icon(
              Icons.info_outline,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      new ConversationSettingsPage(
                        conversation: conversation,
                        currentUser: _currentUser,
                      ),
                ),
              );
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Container(
        child: new Column(
          children: <Widget>[
            new Expanded(
              child: new GestureDetector(
                child: new Container(
                  alignment: Alignment.topCenter,
                  child: new StreamBuilder(
                    stream: Firestore.instance
                        .collection("Messages")
                        .where("messageConversationID",
                            isEqualTo: widget.conversationID)
                        .orderBy("messageDate", descending: true)
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> messageSnapshot) {
                      if (!messageSnapshot.hasData) {
                        return new Center(
                          child: new CircularProgressIndicator(
                            backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                          ),
                        );
                      } else {
                        try {
                          Firestore.instance
                              .runTransaction((Transaction transaction) async {
                            await transaction
                                .get(Firestore.instance.document(
                                    "Conversations/${widget.conversationID}"))
                                .then((conversationInfo) async {
                              if (conversationInfo.exists) {
                                Map<String, dynamic> conversationRead =
                                    Map.from(
                                        conversationInfo["conversationRead"]);
                                conversationRead[_currentUser] = true;
                                await transaction.update(
                                    Firestore.instance.document(
                                        "Conversations/${widget.conversationID}"),
                                    <String, dynamic>{
                                      "conversationRead": conversationRead,
                                    });
                              }
                            });
                          });
                        } catch (error) {
                          print("Error: $error");
                        }
                        return new ListView.builder(
                          padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 10.0),
                          reverse: true,
                          itemBuilder: (BuildContext context, int index) {
                            List<DocumentSnapshot> messages =
                                messageSnapshot.data.documents;
                            Map<dynamic, dynamic> message =
                                messageSnapshot.data.documents[index].data;
                            Map<dynamic, dynamic> previousMessage;
                            if (index != messages.length - 1) {
                              previousMessage = messages[index + 1].data;
                            } else {
                              previousMessage = {
                                "messageID": "",
                                "messageUserID": "",
                                "messageUserUsername": "",
                                "messageBody": "",
                                "messageDate": "",
                              };
                            }
                            return message["messageUserID"] == _currentUser
                                ? new MessageBoxSender(
                                    message: message,
                                    previousMessage: previousMessage,
                                  )
                                : new MessageBoxReceiver(
                                    message: message,
                                    previousMessage: previousMessage,
                                    conversation: conversation,
                                  );
                          },
                          itemCount: messageSnapshot.data.documents.length,
                        );
                      }
                    },
                  ),
                ),
                onPanDown: (downDetails) {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
            ),
            new SafeArea(
              top: false,
              child: new Container(
                constraints: BoxConstraints(maxHeight: 200.0, minHeight: 50.0),
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
                                                          color: Color.fromRGBO(
                                                              40, 40, 40, 0.7),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      25.0),
                                                        ),
                                                        child: new Icon(
                                                          Icons.play_arrow,
                                                          color: Color.fromRGBO(
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
                                          MaterialPageRoute(
                                              builder: (BuildContext context) {
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
                                        color:
                                            Color.fromRGBO(170, 170, 170, 1.0),
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
                          if (messageReady) {
                            _handleMessage(
                                _currentUser,
                                messageTextController.text,
                                messageMedia,
                                messageMediaType);
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
      ),
    );
  }
}

class MessageBoxReceiver extends StatefulWidget {
  _MessageBoxReceiver createState() => new _MessageBoxReceiver();

  final Map<dynamic, dynamic> message;
  final Map<dynamic, dynamic> previousMessage;
  final Map<dynamic, dynamic> conversation;

  MessageBoxReceiver(
      {Key key,
      @required this.message,
      @required this.previousMessage,
      @required this.conversation})
      : super(key: key);
}

class _MessageBoxReceiver extends State<MessageBoxReceiver> {
  Map<dynamic, dynamic> message;
  Map<dynamic, dynamic> previousMessage;
  Map<dynamic, dynamic> conversation;
  VideoPlayerController messageVideoController;

  @override
  void initState() {
    super.initState();
    message = widget.message;
    previousMessage = widget.previousMessage;
    conversation = widget.conversation;
    if (message["messageVideo"] != "") {
      messageVideoController =
          new VideoPlayerController.network(message["messageVideo"])
            ..initialize().then((_) {
              setState(() {});
            });
    }
  }

  topMargin() {
    DateTime messageDate = message["messageDate"].toDate();
    DateTime previousMessageDate;
    if (previousMessage["messageDate"] != "") {
      previousMessageDate = previousMessage["messageDate"].toDate();
    } else {
      previousMessageDate = null;
    }
    if (previousMessageDate == null ||
        messageDate.microsecondsSinceEpoch >
            previousMessageDate.microsecondsSinceEpoch + (pow(21.6, 10))) {
      return 15.0;
    } else if (message["messageUserID"] == previousMessage["messageUserID"]) {
      return 3.0;
    } else {
      return 10.0;
    }
  }

  fetchTimeStamp(DateTime messageDate) {
    String month;
    String weekday;
    switch (messageDate.month) {
      case 1:
        month = "Jan";
        break;
      case 2:
        month = "Feb";
        break;
      case 3:
        month = "Mar";
        break;
      case 4:
        month = "Apr";
        break;
      case 5:
        month = "May";
        break;
      case 6:
        month = "Jun";
        break;
      case 7:
        month = "Jul";
        break;
      case 8:
        month = "Aug";
        break;
      case 9:
        month = "Sep";
        break;
      case 10:
        month = "Oct";
        break;
      case 11:
        month = "Nov";
        break;
      case 12:
        month = "Dec";
        break;
    }
    switch (messageDate.weekday) {
      case 1:
        weekday = "Mon";
        break;
      case 2:
        weekday = "Tues";
        break;
      case 3:
        weekday = "Wed";
        break;
      case 4:
        weekday = "Thur";
        break;
      case 5:
        weekday = "Fri";
        break;
      case 6:
        weekday = "Sat";
        break;
      case 7:
        weekday = "Sun";
        break;
    }
    return "$weekday, $month ${messageDate.day}, ${messageDate.year}";
  }

  Widget build(BuildContext context) {
    if (message["messageVideo"] != "") {
      messageVideoController =
          new VideoPlayerController.network(message["messageVideo"])
            ..initialize().then((_) {
              setState(() {});
            });
    }
    message = widget.message;
    previousMessage = widget.previousMessage;
    conversation = widget.conversation;
    return new Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(
        top: topMargin(),
      ),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          previousMessage["messageDate"] == "" ||
                  message["messageDate"].microsecondsSinceEpoch >
                      previousMessage["messageDate"].microsecondsSinceEpoch +
                          (pow(21.6, 10))
              ? new Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10.0),
                  child: new Text(
                    fetchTimeStamp(message["messageDate"].toDate()),
                    style: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 13.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                )
              : new Container(),
          conversation["conversationUsers"].length > 2 &&
                  previousMessage["messageUserID"] != message["messageUserID"]
              ? new Container(
                  margin: EdgeInsets.only(left: 5.0, bottom: 2.0),
                  child: new StreamBuilder(
                    stream: Firestore.instance
                        .document("Users/${message["messageUserID"]}")
                        .snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return new Container(
                          height: 10.0,
                          width: 75.0,
                          color: Color.fromRGBO(50, 50, 50, 0.5),
                        );
                      } else {
                        return new Text(
                          userSnapshot.data.data["userUsername"],
                          style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 13.0,
                              fontFamily: "Avenir",
                              fontWeight: FontWeight.bold),
                        );
                      }
                    },
                  ),
                )
              : new Container(),
          message["messagePicture"] != ""
              ? new GestureDetector(
                  child: new Container(
                    height: 192.0,
                    width: 108.0,
                    margin: EdgeInsets.only(top: 10.0),
                    constraints: BoxConstraints(maxWidth: 265.0),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(50, 50, 50, 1.0),
                      border: Border.all(
                        width: 1.0,
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          message["messagePicture"],
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => new MediaPage(
                              postMedia: message["messagePicture"],
                              postMediaObject: "Network",
                              postMediaType: "Image",
                            ),
                      ),
                    );
                  })
              : new Container(),
          message["messageVideo"] != ""
              ? new GestureDetector(
                  child: new Container(
                    alignment: Alignment.topLeft,
                    height: 192.0,
                    width: 108.0,
                    margin: EdgeInsets.only(top: 10.0),
                    child: new Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        new Container(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(50, 50, 50, 1.0),
                            border: Border.all(
                              width: 1.0,
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: new RotatedBox(
                            quarterTurns: 1,
                            child: new VideoPlayer(messageVideoController),
                          ),
                        ),
                        new Align(
                          alignment: Alignment.center,
                          child: new Container(
                            height: 50.0,
                            width: 50.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(40, 40, 40, 0.7),
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            child: new Icon(
                              Icons.play_arrow,
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                              size: 40.0,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => new MediaPage(
                              postMedia: message["messageVideo"],
                              postMediaObject: "Network",
                              postMediaType: "Video",
                              postVideoController: messageVideoController,
                            ),
                      ),
                    );
                  })
              : new Container(),
          message["messageBody"] != ""
              ? new Container(
                  margin: EdgeInsets.only(top: 5.0),
                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  constraints: BoxConstraints(maxWidth: 265.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(50, 50, 50, 1.0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                  ),
                  child: new Text(
                    message["messageBody"],
                    textAlign: TextAlign.start,
                    style: new TextStyle(
                      color: Colors.white,
                      fontSize: 17.0,
                      fontFamily: "Avenir",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : new Container(),
        ],
      ),
    );
  }
}

class MessageBoxSender extends StatefulWidget {
  _MessageBoxSender createState() => new _MessageBoxSender();

  final Map<dynamic, dynamic> message;
  final Map<dynamic, dynamic> previousMessage;

  MessageBoxSender(
      {Key key, @required this.message, @required this.previousMessage})
      : super(key: key);
}

class _MessageBoxSender extends State<MessageBoxSender> {
  Map<dynamic, dynamic> message;
  Map<dynamic, dynamic> previousMessage;
  VideoPlayerController messageVideoController;

  @override
  void initState() {
    super.initState();
    message = widget.message;
    previousMessage = widget.previousMessage;

    if (message["messageVideo"] != "") {
      messageVideoController =
          new VideoPlayerController.network(message["messageVideo"])
            ..initialize().then((_) {
              setState(() {});
            });
    }
  }

  fetchTopMargin() {
    DateTime messageDate = message["messageDate"].toDate();
    DateTime previousMessageDate;
    if (previousMessage["messageDate"] != "") {
      previousMessageDate = previousMessage["messageDate"].toDate();
    } else {
      previousMessageDate = null;
    }
    if (previousMessageDate == null ||
        messageDate.microsecondsSinceEpoch >
            previousMessageDate.microsecondsSinceEpoch + (pow(21.6, 10))) {
      return 15.0;
    } else if (message["messageUserID"] == previousMessage["messageUserID"]) {
      return 3.0;
    } else {
      return 10.0;
    }
  }

  fetchTimeStamp(DateTime messageDate) {
    String month;
    String weekday;
    switch (messageDate.month) {
      case 1:
        month = "Jan";
        break;
      case 2:
        month = "Feb";
        break;
      case 3:
        month = "Mar";
        break;
      case 4:
        month = "Apr";
        break;
      case 5:
        month = "May";
        break;
      case 6:
        month = "Jun";
        break;
      case 7:
        month = "Jul";
        break;
      case 8:
        month = "Aug";
        break;
      case 9:
        month = "Sep";
        break;
      case 10:
        month = "Oct";
        break;
      case 11:
        month = "Nov";
        break;
      case 12:
        month = "Dec";
        break;
    }
    switch (messageDate.weekday) {
      case 1:
        weekday = "Mon";
        break;
      case 2:
        weekday = "Tues";
        break;
      case 3:
        weekday = "Wed";
        break;
      case 4:
        weekday = "Thur";
        break;
      case 5:
        weekday = "Fri";
        break;
      case 6:
        weekday = "Sat";
        break;
      case 7:
        weekday = "Sun";
        break;
    }
    return "$weekday, $month ${messageDate.day}, ${messageDate.year}";
  }

  Widget build(BuildContext context) {
    if (message["messageVideo"] != "") {
      messageVideoController =
          new VideoPlayerController.network(message["messageVideo"])
            ..initialize().then((_) {
              setState(() {});
            });
    }
    message = widget.message;
    previousMessage = widget.previousMessage;
    return new Container(
      alignment: Alignment.topRight,
      margin: EdgeInsets.only(
        top: fetchTopMargin(),
      ),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          previousMessage["messageDate"] == "" ||
                  message["messageDate"].microsecondsSinceEpoch >
                      previousMessage["messageDate"].microsecondsSinceEpoch +
                          (pow(21.6, 10))
              ? new Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(bottom: 10.0),
                  child: new Text(
                    fetchTimeStamp(message["messageDate"].toDate()),
                    style: TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 13.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold),
                  ),
                )
              : new Container(),
          message["messagePicture"] != ""
              ? new GestureDetector(
                  child: new Container(
                    height: 192.0,
                    width: 108.0,
                    margin: EdgeInsets.only(top: 10.0),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(50, 50, 50, 1.0),
                      border: Border.all(
                        width: 1.0,
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(20.0),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          message["messagePicture"],
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    print(message["messagePicture"]);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => new MediaPage(
                              postMedia: message["messagePicture"],
                              postMediaObject: "Network",
                              postMediaType: "Image",
                            ),
                      ),
                    );
                  },
                )
              : new Container(),
          message["messageVideo"] != ""
              ? new GestureDetector(
                  child: new Container(
                    alignment: Alignment.topRight,
                    height: 192.0,
                    width: 108.0,
                    margin: EdgeInsets.only(top: 10.0),
                    child: new Stack(
                      alignment: Alignment.centerRight,
                      children: <Widget>[
                        new Container(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(50, 50, 50, 1.0),
                            border: Border.all(
                              width: 1.0,
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: new RotatedBox(
                            quarterTurns: 1,
                            child: new VideoPlayer(messageVideoController),
                          ),
                        ),
                        new Align(
                          alignment: Alignment.center,
                          child: new Container(
                            height: 50.0,
                            width: 50.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(40, 40, 40, 0.7),
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            child: new Icon(
                              Icons.play_arrow,
                              color: Color.fromRGBO(255, 255, 255, 0.7),
                              size: 40.0,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => new MediaPage(
                              postMedia: message["messageVideo"],
                              postMediaObject: "Network",
                              postMediaType: "Video",
                              postVideoController: messageVideoController,
                            ),
                      ),
                    );
                  })
              : new Container(),
          message["messageBody"] != ""
              ? new Container(
                  margin: EdgeInsets.only(top: 5.0),
                  padding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                  constraints: BoxConstraints(maxWidth: 265.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 150, 255, 1.0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0),
                      topLeft: Radius.circular(10.0),
                    ),
                  ),
                  child: new Text(
                    message["messageBody"],
                    textAlign: TextAlign.start,
                    style: new TextStyle(
                      color: Colors.white,
                      fontSize: 17.0,
                      fontFamily: "Avenir",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : new Container(),
        ],
      ),
    );
  }
}
