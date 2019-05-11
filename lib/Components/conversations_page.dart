import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/Components/messages_page.dart';
import 'package:gg/globals.dart' as globals;
import 'package:cached_network_image/cached_network_image.dart';
import 'conversation_creation_page.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class ConversationsPage extends StatefulWidget {
  _ConversationsPage createState() => new _ConversationsPage();
}

class _ConversationsPage extends State<ConversationsPage> {
  String _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = globals.currentUser;
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Messages",
          style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontFamily: "Century Gothic",
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: new Container(),
        actions: <Widget>[
          new IconButton(
            icon: Icon(
              Icons.add_comment,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new ConversationCreationPage(
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
        alignment: Alignment.center,
        child: new StreamBuilder(
          stream: Firestore.instance
              .collection("Conversations")
              .where("conversationUsers", arrayContains: _currentUser)
              .orderBy("conversationDate", descending: true)
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> conversationSnapshot) {
            if (!conversationSnapshot.hasData) {
              return new Center(
                child: new CircularProgressIndicator(
                  backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                ),
              );
            } else {
              return conversationSnapshot.data.documents.isNotEmpty ? new ListView.builder(
                padding: EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 10.0),
                itemBuilder: (BuildContext context, int index) {
                  Map<dynamic, dynamic> conversation =
                      Map.from(conversationSnapshot.data.documents[index].data);
                  String conversationID =
                      conversationSnapshot.data.documents[index].documentID;
                  if (conversation["conversationUsers"].length == 2) {
                    List conversationUsers =
                        List.from(conversation["conversationUsers"]);
                    conversationUsers.remove(_currentUser);
                    return new StreamBuilder(
                        stream: Firestore.instance
                            .document("Users/${conversationUsers[0]}")
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return new Center(
                              child: new CircularProgressIndicator(
                                backgroundColor:
                                    Color.fromRGBO(0, 150, 255, 1.0),
                              ),
                            );
                          } else {
                            conversation.addAll({
                              "conversationName":
                                  userSnapshot.data.data["userUsername"],
                              "conversationPicture":
                                  userSnapshot.data.data["userPicture"],
                            });
                            return new ConversationBox(
                              conversation: conversation,
                              conversationID: conversationID,
                              currentUser: _currentUser,
                            );
                          }
                        });
                  } else {
                    return new ConversationBox(
                      conversation: conversation,
                      conversationID: conversationID,
                      currentUser: _currentUser,
                    );
                  }
                },
                itemCount: conversationSnapshot.data.documents.length,
              ) : new Center(
                        child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
new Container(
  margin: EdgeInsets.only(bottom: 10.0),
                       child: new Text(
                          "No Conversations Yet",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 20.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        ),
                        new GestureDetector(
                          child: new Text(
                            "Send your first message",
                            style: TextStyle(
                              color: Color.fromRGBO(0, 150, 255, 1.0),
                              fontSize: 18.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => new ConversationCreationPage(
                                  currentUser: _currentUser,
                                ),
                              ),
                            );
                          },
                        ),
        ],
                      ),
                      );
            }
          },
        ),
      ),
    );
  }
}

class ConversationBox extends StatefulWidget {
  _ConversationBox createState() => new _ConversationBox();

  final String conversationID;
  final Map<dynamic, dynamic> conversation;
  final String currentUser;

  ConversationBox(
      {Key key,
      @required this.conversation,
      @required this.currentUser,
      @required this.conversationID})
      : super(key: key);
}

class _ConversationBox extends State<ConversationBox> {
  String conversationID;
  Map<dynamic, dynamic> conversation;
  String _currentUser;

  @override
  void initState() {
    super.initState();
    conversation = widget.conversation;
    _currentUser = widget.currentUser;
    conversationID = widget.conversationID;
  }

  fetchTimeStamp(DateTime conversationDate) {
    var timeDifference = conversationDate.difference(DateTime.now()).abs();
    if (timeDifference.inSeconds < 60) {
      // BETWEEN 0 SECONDS AND 1 MINUTE
      return "${timeDifference.inSeconds.toString()}s";
    } else if (timeDifference.inSeconds >= 60 &&
        timeDifference.inSeconds < 3600) {
      // BETWEEN 1 MINUTE AND 1 HOUR
      return "${timeDifference.inMinutes.toString()}m";
    } else if (timeDifference.inSeconds >= 3600 &&
        timeDifference.inSeconds <= 43200) {
      // BETWEEN 1 HOUR AND 12 HOURS
      return "${timeDifference.inHours.toString()}h";
    } else if (timeDifference.inSeconds > 43200 &&
        timeDifference.inSeconds <= 86400) {
      // BETWEEN 12 HOURS AND 1 DAY
      return "Today";
    } else if (timeDifference.inSeconds > 86400 &&
        timeDifference.inSeconds <= 172800) {
      // BETWEEN 1 DAY AND 2 DAYS
      return "Yesterday";
    } else if (timeDifference.inSeconds > 172800) {
      // GREATER THAN 2 DAYS
      return "${conversationDate.month.toString()}/${conversationDate.day.toString()}/${conversationDate.year.toString()}";
    }
  }

  Widget build(BuildContext context) {
    conversation = widget.conversation;
    _currentUser = widget.currentUser;
    conversationID = widget.conversationID;
    return new GestureDetector(
      child: new Container(
        height: 80.0,
        margin: EdgeInsets.only(top: 10.0),
        decoration: BoxDecoration(
          color: Color.fromRGBO(23, 23, 23, 1.0),
          border: Border.all(
            width: 1.0,
            color: Color.fromRGBO(40, 40, 40, 1.0),
          ),
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              blurRadius: 4.0,
              color: Colors.black,
              offset: new Offset(0.0, 4.0),
            ),
          ],
        ),
        child: new Row(
          children: <Widget>[
            new Container(
              margin: EdgeInsets.only(left: 10.0),
              child: new CircleAvatar(
                backgroundColor: conversation["conversationRead"][_currentUser] != true ? new Color.fromRGBO(0, 150, 255, 1.0) : Color.fromRGBO(50, 50, 50, 1.0),
                radius: 28.0,
                child: new CircleAvatar(
                  backgroundColor: new Color.fromRGBO(50, 50, 50, 1.0),
                  radius: 26.0,
                  backgroundImage: new CachedNetworkImageProvider(
                      conversation["conversationPicture"]),
                ),
              ),
            ),
            new Expanded(
              child: new Container(
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Container(
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Container(
                              margin: EdgeInsets.only(
                                  top: 5.0, left: 5.0, right: 5.0),
                              child: new Text(
                                conversation["conversationName"],
                                maxLines: 1,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                style: new TextStyle(
                                  fontSize: 17.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          new Container(
                              margin: EdgeInsets.only(top: 5.0, right: 20.0),
                              child: new Text(
                                fetchTimeStamp(
                                    conversation["conversationDate"].toDate(),
                                    ),
                                textAlign: TextAlign.end,
                                style: new TextStyle(
                                  fontSize: 13.0,
                                  fontFamily: "Avenir",
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                ),
                              )),
                        ],
                      ),
                    ),
                    new Expanded(
                      child: new Container(
                        margin: EdgeInsets.only(
                            left: 10.0, bottom: 10.0, right: 20.0, top: 3.0),
                        alignment: Alignment.topLeft,
                        child: new Text(
                          conversation["conversationBody"],
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: new TextStyle(
                            height: 0.95,
                            fontSize: 16.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (BuildContext context) => new MessagesPage(
                  conversationID: conversationID,
                  conversation: conversation,
                  currentUser: _currentUser)),
        );
      },
    );
  }
}
