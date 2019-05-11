import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gg/Components/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'package:video_player/video_player.dart';
import 'media_page.dart';

class PostDetailPage extends StatefulWidget {
  _PostDetailPage createState() => new _PostDetailPage();

  final String currentUser;
  final Map<dynamic, dynamic> post;
  final List postReposts;
  final List postLikes;

  PostDetailPage(
      {Key key,
      @required this.currentUser,
      @required this.post,
      @required this.postReposts,
      @required this.postLikes})
      : super(key: key);
}

class _PostDetailPage extends State<PostDetailPage> {

  Map<String, dynamic> post;

  List<Map<String, dynamic>> comments;
  List<String> commentUserID;
  bool commentsLoaded;
  bool commentsExist;
  bool readyToSend;
  String _currentUser;
  List postLikes;
  List postReposts;
  final ScrollController postScrollController = new ScrollController();
  VideoPlayerController postVideoController;
  TextEditingController commentTextController;

  @override
  void initState() {
    super.initState();
    commentsLoaded = false;
    commentsExist = true;
    readyToSend = false;
    _currentUser = widget.currentUser;
    postLikes = List.from(widget.postLikes);
    postReposts = List.from(widget.postReposts);
    commentTextController = new TextEditingController()..addListener(comment);
    fetchComments();
    if (widget.post["postVideo"] != "") {
      print("INITIALIZED");
      setState(() {
        postVideoController =
            new VideoPlayerController.network(widget.post["postVideo"])
              ..initialize().then((_) {
                setState(() {});
              });
      });
    }
  }

  comment() {
    if (commentTextController.text.isNotEmpty) {
      setState(() {
        readyToSend = true;
      });
    } else {
      setState(() {
        readyToSend = false;
      });
    }
  }

  void fetchComments() async {

    post = new Map.from(widget.post);

    comments = [];
    commentUserID = [];
    Firestore.instance
        .collection("Comments")
        .where("commentPostID", isEqualTo: widget.post["postID"])
        .orderBy("commentDate", descending: true)
        .getDocuments()
        .then((commentInfo) {
      if (commentInfo != null && commentInfo.documents.isNotEmpty) {
        for (DocumentSnapshot commentDocument in commentInfo.documents) {
          Firestore.instance
              .document("Users/${commentDocument.data["commentUser"]}")
              .get()
              .then((userInfo) {
            if (userInfo.exists) {
              comments.add({
                commentDocument.data["commentUser"]: {
                  "commentUsername": userInfo.data["userUsername"],
                  "commentBody": commentDocument.data["commentBody"],
                  "commentDate": commentDocument.data["commentDate"],
                  "commentPicture": userInfo.data["userPicture"]
                }
              });
              commentUserID.add(commentDocument.data["commentUser"]);

              if (comments.length == commentInfo.documents.length) {
                setState(() {
                  commentsLoaded = true;
                  commentsExist = true;
                });
              }
            } else {
              setState(() {
                commentsExist = false;
              });
            }
          });
        }
      } else {
        setState(() {
          commentsExist = false;
        });
      }
    });
  }

  fetchTimeStamp(DateTime date) {
    var timeDifference = date.difference(DateTime.now()).abs();
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
      return "${date.month.toString()}/${date.day.toString()}/${date.year.toString()}";
    }
  }

  _handleRepost() {
    bool add;
    setState(() {
      if (post["postReposts"].contains(_currentUser)) {
        post["postReposts"].remove(_currentUser);
        add = false;
      } else {
        post["postReposts"].add(_currentUser);
        add = true;
      }
    });
    try {
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance.document("Posts/${widget.post["postID"]}"))
            .then((postInfo) async {
          if (postInfo.exists) {
            List reposts = List.from(postInfo.data["postReposts"]);
            if (add == true) {
              reposts.add(_currentUser);
            } else {
              reposts.remove(_currentUser);
            }
            await transaction.update(
                Firestore.instance.document("Posts/${widget.post["postID"]}"),
                <String, dynamic>{"postReposts": reposts});
          }
        });
      });
    } catch (error) {
      print(error);
    }
  }

  _handleLike() {
    bool add;
    setState(() {
      if (post["postLikes"].contains(_currentUser)) {
        post["postLikes"].remove(_currentUser);
        add = false;
      } else {
        post["postLikes"].add(_currentUser);
        add = true;
      }
    });
    try {
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance.document("Posts/${widget.post["postID"]}"))
            .then((postInfo) async {
          if (postInfo.exists) {
            List likes = List.from(postInfo.data["postLikes"]);
            if (add == true) {
              likes.add(_currentUser);
            } else {
              likes.remove(_currentUser);
            }
            await transaction.update(
                Firestore.instance.document("Posts/${widget.post["postID"]}"),
                <String, dynamic>{"postLikes": likes});
          }
        });
      });
    } catch (error) {
      print(error);
    }
  }

  _handleComment(String commentBody) {
    setState(() {
      commentTextController.clear();
      FocusScope.of(context).requestFocus(FocusNode());
      readyToSend = false;
    });

    Map<String, dynamic> comment = {
      "commentBody": commentBody,
      "commentDate": DateTime.now(),
      "commentPostID": widget.post["postID"],
      "commentUser": widget.currentUser,
    };
    try {
      Firestore.instance.collection("Comments").add(comment).then((_) {
        setState(() {
          fetchComments();
        });
      });
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {

    post = Map.from(widget.post);

    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new GestureDetector(
          child: new Text(
            "Post",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontFamily: "Century Gothic",
                fontWeight: FontWeight.bold),
          ),
          onTap: () {
            postScrollController.position.animateTo(0.0,
                duration: Duration(milliseconds: 500), curve: Curves.ease);
          },
        ),
        leading: new IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color.fromRGBO(0, 150, 255, 1.0),
          ),
          onPressed: () {
            Navigator.of(context).pop([widget.post, postReposts, postLikes]);
          },
        ),
        elevation: 0.0,
      ),
      body: new Column(
        children: <Widget>[
          new Expanded(
            child: new GestureDetector(
              child: new ListView.builder(
                controller: postScrollController,
                itemBuilder: (BuildContext context, int index) {
                  return index == 0
                      ? new Container(
        margin: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
        padding: EdgeInsets.only(bottom: 5.0),
        decoration: new BoxDecoration(
          color: Color.fromRGBO(23, 23, 23, 1.0),
          boxShadow: [
            new BoxShadow(
              blurRadius: 4.0,
              color: Color.fromRGBO(0, 0, 0, 0.5),
              offset: new Offset(0.0, 4.0),
            )
          ],
          borderRadius: new BorderRadius.all(Radius.circular(20.0)),
          border: new Border.all(
            width: 1.0,
            color: Color.fromRGBO(40, 40, 40, 1.0),
          ),
        ),
        child: new Container(
          child: new Column(
            children: <Widget>[
              new StreamBuilder(
                stream: Firestore.instance.document("Users/${post["postUserID"]}").snapshots(),
                builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> postUserSnapshot) {
                  
                    return new Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new Container(
                    padding: EdgeInsets.only(top: 2.0, left: 2.0),
                    child: new GestureDetector(
                        child: new CircleAvatar(
                          radius: 20.0,
                          backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                          child: CircleAvatar(
                            radius: 18.0,
                            backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                            backgroundImage: new NetworkImage(
                              postUserSnapshot.hasData ? postUserSnapshot.data.data["userPicture"] : "",
                            ),
                          ),
                        ),
                        onTap: () {
                          // Navigator.of(context).push(
                          //   MaterialPageRoute(
                          //     builder: (BuildContext context) =>
                          //         new ProfilePage(
                          //           userID: postUser[index],
                          //           visitor: true,
                          //         ),
                          //   ),
                          // );
                        }),
                  ),

                    new Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left: 2.0),
                      child: new GestureDetector(
                        child: new Text(
                          postUserSnapshot.hasData ? postUserSnapshot.data.data["userUsername"] : "",
                          style: new TextStyle(
                            color: Colors.white,
                            fontFamily: "Century Gothic",
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // Navigator.of(context).push(
                          //   MaterialPageRoute(
                          //     builder: (BuildContext context) =>
                          //         new ProfilePage(
                          //           userID: postUser[index],
                          //           visitor: true,
                          //         ),
                          //   ),
                          // );
                        },
                      ),
                    ),
                  new Expanded(
                  child: 
                  post["postUserID"] != post["postRepostUserID"] ? new Container(
                    margin: EdgeInsets.only(left: 5.0),
                    child: new Row(
                      children: <Widget>[
                        new Icon(
                          Icons.repeat,
                          color: Color.fromRGBO(0, 122, 255, 1.0),
                          size: 17.0,
                        ),
                        new Text(
                          "Reposted",
                          style: TextStyle(
                            color: Color.fromRGBO(0, 122, 255, 1.0),
                            fontSize: 13.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold
                          ),
                        )
                      ],
                    ),
                  ) : 
                  new Container(),
                    ),
                  new Container(
                    padding: EdgeInsets.only(right: 15.0),
                    child: new Text(
                      fetchTimeStamp(post["postDate"].toDate()),
                      style: new TextStyle(
                        color: Color.fromRGBO(170, 170, 170, 1.0),
                        fontSize: 13.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
                  
                }
              ),
              new Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
                child: new Text(
                  post["postBody"],
                  textAlign: TextAlign.left,
                  style: new TextStyle(
                    color: Colors.white,
                    fontFamily: "Avenir",
                    fontSize: 17.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              post["postPicture"] != ""
                  ? new GestureDetector(
                      child: new AspectRatio(
                        aspectRatio: 16.0 / 9.0,
                        child: new Container(
                          margin: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 0.0),
                          constraints: BoxConstraints(maxWidth: 350.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.0,
                              color: Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                          child: new Image.network(
                            post["postPicture"],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                new MediaPage(
                                  postMedia: post["postPicture"],
                                  postMediaType: "Image",
                                  postMediaObject: "Network",
                                  postVideoController: postVideoController,
                                ),
                          ),
                        )
                            .then((_) {
                          setState(() {
                            postVideoController.initialize().then((_) {
                                    setState(() {});
                                  });
                          });
                        });
                      })
                  : new Container(),
              post["postVideo"] != ""
                  ? new GestureDetector(
                      child: new Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          new AspectRatio(
                            aspectRatio: 16.0 / 9.0,
                            child: new Container(
                              margin:
                                  EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 0.0),
                              constraints: BoxConstraints(
                                maxWidth: 350.0,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1.0,
                                  color: Color.fromRGBO(40, 40, 40, 1.0),
                                ),
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              child: new RotatedBox(
                                quarterTurns: 1,
                                child: new VideoPlayer(postVideoController),
                              ),
                            ),
                          ),
                          new Center(
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
                      onTap: () {
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                new MediaPage(
                                  postMedia: post["postVideo"],
                                  postMediaType: "Video",
                                  postMediaObject: "Network",
                                  postVideoController: postVideoController,
                                ),
                          ),
                        )
                            .then((_) {
                          setState(() {
                            postVideoController.initialize().then((_) {
                                    setState(() {});
                                  });
                          });
                        });
                      })
                  : new Container(),
              new StreamBuilder(
                stream: Firestore.instance.collection("Posts").where("postID", isEqualTo: post["postID"]).limit(1).snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> postSnapshot) {

                  if (postSnapshot.hasData) {
                    Map<String, dynamic> postInfo = postSnapshot.data.documents[0].data;
                  post["postReposts"] = List.from(postInfo["postReposts"]);
                  post["postLikes"] = List.from(postInfo["postLikes"]);
                  }
                  return new Container(
                    margin: EdgeInsets.only(top: 10.0),
                    constraints: BoxConstraints(
                      maxWidth: 350.0,
                    ),
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        new GestureDetector(
                          child: new Container(
                            color: Colors.transparent,
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                new Container(
                              child: new Icon(
                                Icons.repeat,
                                color: post["postReposts"].contains(_currentUser)
                                    ? Color.fromRGBO(0, 122, 255, 1.0)
                                    : Color.fromRGBO(170, 170, 170, 1.0),
                              ),
                            ),
                            new Text(
                              post["postReposts"].length.toString(),
                              style: TextStyle(
                                  color:
                                      post["postReposts"].contains(_currentUser)
                                          ? Color.fromRGBO(0, 122, 255, 1.0)
                                    : Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 15.0,
                                  fontFamily: "Avenir",
                                  fontWeight: FontWeight.bold),
                            ),
                              ],
                            ),
                          ),
                          onTap: () {
                            _handleRepost();
                          },
                        ),
                        new GestureDetector(
                          child: new Container(
                            color: Colors.transparent,
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                new Container(
                              child: new Icon(
                                post["postLikes"].contains(_currentUser) ? Icons.mood : Icons.sentiment_neutral,
                                color: post["postLikes"].contains(_currentUser)
                                    ? Colors.yellow
                                    : Color.fromRGBO(170, 170, 170, 1.0),
                              ),
                            ),
                            new Text(
                              post["postLikes"].length.toString(),
                              style: TextStyle(
                                  color:
                                      post["postLikes"].contains(_currentUser)
                                          ? Colors.yellow
                                          : Color.fromRGBO(170, 170, 170, 1.0),
                                  fontSize: 15.0,
                                  fontFamily: "Avenir",
                                  fontWeight: FontWeight.bold),
                            ),
                              ],
                            ),
                          ),
                          onTap: () {
                            _handleLike();
                          }
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      )
                      : index == 1
                          ? new Container(
                              height: 50.0,
                              color: Color.fromRGBO(23, 23, 23, 1.0),
                              alignment: Alignment.bottomLeft,
                              child: new Container(
                                margin:
                                    EdgeInsets.only(left: 10.0, bottom: 10.0),
                                child: new Text(
                                  "Comments",
                                  style: new TextStyle(
                                    color: Color.fromRGBO(170, 170, 170, 1.0),
                                    fontSize: 17.0,
                                    fontFamily: "Avenir",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : index > 1 && commentsLoaded != true
                              ? new Container(
                                  margin: EdgeInsets.only(top: 20.0),
                                  alignment: Alignment.center,
                                  child: commentsExist == true
                                      ? new CircularProgressIndicator(
                                          backgroundColor:
                                              Color.fromRGBO(0, 150, 255, 1.0),
                                        )
                                      : new Container(
                                          child: new Text(
                                            "No Comments Yet",
                                            style: TextStyle(
                                                color: Color.fromRGBO(
                                                    170, 170, 170, 1.0),
                                                fontSize: 20.0,
                                                fontFamily: "Century Gothic",
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                )
                              : new Container(
                                  margin: EdgeInsets.fromLTRB(
                                      10.0, 0.0, 10.0, 10.0),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(23, 23, 23, 1.0),
                                    boxShadow: [
                                      new BoxShadow(
                                        blurRadius: 4.0,
                                        color: Color.fromRGBO(0, 0, 0, 0.5),
                                        offset: new Offset(0.0, 4.0),
                                      )
                                    ],
                                    border: Border.all(
                                      width: 1.0,
                                      color: Color.fromRGBO(40, 40, 40, 1.0),
                                    ),
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: new Column(
                                    children: <Widget>[
                                      new Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          new GestureDetector(
                                            child: new Container(
                                              padding: EdgeInsets.only(
                                                  top: 2.0, left: 2.0),
                                              child: new CircleAvatar(
                                                radius: 15.0,
                                                backgroundColor: Color.fromRGBO(
                                                    0, 150, 255, 1.0),
                                                child: CircleAvatar(
                                                  radius: 13.0,
                                                  backgroundColor:
                                                      Color.fromRGBO(
                                                          50, 50, 50, 1.0),
                                                  backgroundImage:
                                                      new CachedNetworkImageProvider(
                                                    comments[index - 2][
                                                            commentUserID[
                                                                index - 2]]
                                                        ["commentPicture"],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (BuildContext context) =>
                                                          new ProfilePage(
                                                            userID:
                                                                commentUserID[
                                                                    index - 2],
                                                            visitor: true,
                                                          ),
                                                ),
                                              );
                                            },
                                          ),
                                          new Expanded(
                                            child: new Container(
                                              alignment: Alignment.centerLeft,
                                              child: new Container(
                                                padding:
                                                    EdgeInsets.only(left: 2.0),
                                                child: new GestureDetector(
                                                  child: new Text(
                                                    comments[index - 2][
                                                            commentUserID[
                                                                index - 2]]
                                                        ["commentUsername"],
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily:
                                                          "Century Gothic",
                                                      fontSize: 15.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (BuildContext
                                                                context) =>
                                                            new ProfilePage(
                                                              userID:
                                                                  commentUserID[
                                                                      index -
                                                                          2],
                                                              visitor: true,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          new Container(
                                            margin:
                                                EdgeInsets.only(right: 15.0),
                                            child: new Text(
                                              fetchTimeStamp(comments[index - 2]
                                                      [commentUserID[index - 2]]
                                                  ["commentDate"].toDate()),
                                              style: new TextStyle(
                                                color: Color.fromRGBO(
                                                    170, 170, 170, 1.0),
                                                fontSize: 13.0,
                                                fontFamily: "Avenir",
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      new Container(
                                          alignment: Alignment.topLeft,
                                          margin: EdgeInsets.only(
                                              left: 20.0,
                                              top: 5.0,
                                              right: 20.0,
                                              bottom: 10.0),
                                          child: new Text(
                                            comments[index - 2]
                                                    [commentUserID[index - 2]]
                                                ["commentBody"],
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.0,
                                                fontFamily: "Avenir",
                                                fontWeight: FontWeight.w500),
                                          ))
                                    ],
                                  ),
                                );
                },
                itemCount: commentsLoaded != true ? 3 : comments.length + 2,
              ),
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
          ),
          new SafeArea(
            top: false,
            child: new Container(
              constraints: BoxConstraints(maxHeight: 200.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    width: 1.0,
                    color: Color.fromRGBO(40, 40, 40, 1.0),
                  ),
                ),
              ),
              child: new Row(
                children: <Widget>[
                  new Flexible(
                    child: Container(
                      margin: EdgeInsets.only(left: 10.0),
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      child: TextField(
                        controller: commentTextController,
                        maxLines: null,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold),
                        // controller: textEditingController,
                        decoration: InputDecoration.collapsed(
                          hintText: "Leave a comment...",
                          hintStyle: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 18.0,
                              fontFamily: "Avenir",
                              fontWeight: FontWeight.bold),
                          // focusNode: focusNode,
                        ),
                      ),
                    ),
                  ),

                  // Button send message
                  new Material(
                    child: new Container(
                      margin: new EdgeInsets.symmetric(horizontal: 8.0),
                      child: new IconButton(
                        icon: new Icon(Icons.send),
                        color: readyToSend
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(170, 170, 170, 1.0),
                        onPressed: () {
                          if (readyToSend) {
                            _handleComment(commentTextController.text.trim());
                          }
                        },
                      ),
                    ),
                    color: Color.fromRGBO(23, 23, 23, 1.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// new Container(
//                           margin: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
//                           padding: EdgeInsets.only(bottom: 5.0),
//                           decoration: new BoxDecoration(
//                             color: Color.fromRGBO(23, 23, 23, 1.0),
//                             boxShadow: [
//                               new BoxShadow(
//                                 blurRadius: 4.0,
//                                 color: Color.fromRGBO(0, 0, 0, 0.5),
//                                 offset: new Offset(0.0, 4.0),
//                               )
//                             ],
//                             borderRadius:
//                                 new BorderRadius.all(Radius.circular(20.0)),
//                             border: new Border.all(
//                               width: 1.0,
//                               color: Color.fromRGBO(40, 40, 40, 1.0),
//                             ),
//                           ),
//                           child: new Container(
//                             child: new Column(
//                               children: <Widget>[
//                                 new Row(
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: <Widget>[
//                                     new GestureDetector(
//                                       child: new Container(
//                                         padding: EdgeInsets.only(
//                                             top: 2.0, left: 2.0),
//                                         child: new CircleAvatar(
//                                           radius: 20.0,
//                                           backgroundColor:
//                                               Color.fromRGBO(0, 150, 255, 1.0),
//                                           child: CircleAvatar(
//                                             radius: 18.0,
//                                             backgroundColor:
//                                                 Color.fromRGBO(50, 50, 50, 1.0),
//                                             backgroundImage:
//                                                 new CachedNetworkImageProvider(
//                                               widget.post["postUserPicture"],
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       onTap: () {
//                                         Navigator.of(context).push(
//                                           MaterialPageRoute(
//                                             builder: (BuildContext context) =>
//                                                 new ProfilePage(
//                                                   userID:
//                                                       widget.post["postUserID"],
//                                                   visitor: true,
//                                                 ),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                     new Expanded(
//                                       child: new Container(
//                                         alignment: Alignment.centerLeft,
//                                         padding: EdgeInsets.only(left: 2.0),
//                                         child: new GestureDetector(
//                                           child: new Text(
//                                             widget.post["postUserUsername"],
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontFamily: "Century Gothic",
//                                               fontSize: 15.0,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           onTap: () {
//                                             Navigator.of(context).push(
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (BuildContext context) =>
//                                                         new ProfilePage(
//                                                           userID: widget.post[
//                                                               "postUserID"],
//                                                           visitor: true,
//                                                         ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                       ),
//                                     ),
//                                     new Container(
//                                       padding: EdgeInsets.only(right: 15.0),
//                                       child: new Text(
//                                         fetchTimeStamp(widget.post["postDate"].toDate()),
//                                         style: new TextStyle(
//                                           color: Color.fromRGBO(
//                                               170, 170, 170, 1.0),
//                                           fontSize: 13.0,
//                                           fontFamily: "Avenir",
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 new Container(
//                                   alignment: Alignment.centerLeft,
//                                   margin:
//                                       EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
//                                   child: new Text(widget.post["postBody"],
//                                       textAlign: TextAlign.left,
//                                       style: new TextStyle(
//                                         color: Colors.white,
//                                         fontFamily: "Avenir",
//                                         fontSize: 17.0,
//                                         fontWeight: FontWeight.w500,
//                                       )),
//                                 ),
//                                 widget.post["postPicture"] != ""
//                                     ? new GestureDetector(
//                                         child: new AspectRatio(
//                                           aspectRatio: 16.0 / 9.0,
//                                           child: new Container(
//                                             margin: EdgeInsets.fromLTRB(
//                                                 30.0, 10.0, 30.0, 0.0),
//                                             constraints:
//                                                 BoxConstraints(maxWidth: 350.0),
//                                             decoration: BoxDecoration(
//                                               border: Border.all(
//                                                 width: 1.0,
//                                                 color: Color.fromRGBO(
//                                                     40, 40, 40, 1.0),
//                                               ),
//                                               borderRadius:
//                                                   BorderRadius.circular(2.0),
//                                             ),
//                                             child: new Image.network(
//                                               widget.post["postPicture"],
//                                               fit: BoxFit.cover,
//                                             ),
//                                           ),
//                                         ),
//                                         onTap: () {
//                                           Navigator.of(context)
//                                               .push(
//                                             MaterialPageRoute(
//                                               builder: (BuildContext context) =>
//                                                   new MediaPage(
//                                                     postMedia: widget
//                                                         .post["postPicture"],
//                                                     postMediaType: "Image",
//                                                     postMediaObject: "Network",
//                                                     postVideoController:
//                                                         postVideoController,
//                                                   ),
//                                             ),
//                                           )
//                                               .then((_) {
//                                             setState(() {
//                                               postVideoController =
//                                                   new VideoPlayerController
//                                                           .network(
//                                                       widget.post["postVideo"])
//                                                     ..initialize().then((_) {
//                                                       setState(() {});
//                                                     });
//                                             });
//                                           });
//                                         })
//                                     : new Container(),
//                                 widget.post["postVideo"] != ""
//                                     ? new GestureDetector(
//                                         child: new Stack(
//                                           alignment: Alignment.center,
//                                           children: <Widget>[
//                                             new AspectRatio(
//                                               aspectRatio: 16.0 / 9.0,
//                                               child: new Container(
//                                                 margin: EdgeInsets.fromLTRB(
//                                                     30.0, 10.0, 30.0, 0.0),
//                                                 constraints: BoxConstraints(
//                                                   maxWidth: 350.0,
//                                                 ),
//                                                 decoration: BoxDecoration(
//                                                   border: Border.all(
//                                                     width: 1.0,
//                                                     color: Color.fromRGBO(
//                                                         40, 40, 40, 1.0),
//                                                   ),
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                           2.0),
//                                                 ),
//                                                 child: new RotatedBox(
//                                                   quarterTurns: 1,
//                                                   child: new VideoPlayer(
//                                                       postVideoController),
//                                                 ),
//                                               ),
//                                             ),
//                                             new Center(
//                                               child: new Container(
//                                                 height: 50.0,
//                                                 width: 50.0,
//                                                 alignment: Alignment.center,
//                                                 decoration: BoxDecoration(
//                                                   color: Color.fromRGBO(
//                                                       40, 40, 40, 0.7),
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                           25.0),
//                                                 ),
//                                                 child: new Icon(
//                                                   Icons.play_arrow,
//                                                   color: Color.fromRGBO(
//                                                       255, 255, 255, 0.7),
//                                                   size: 40.0,
//                                                 ),
//                                               ),
//                                             )
//                                           ],
//                                         ),
//                                         onTap: () {
//                                           Navigator.of(context)
//                                               .push(
//                                             MaterialPageRoute(
//                                               builder: (BuildContext context) =>
//                                                   new MediaPage(
//                                                     postMedia: widget
//                                                         .post["postVideo"],
//                                                     postMediaType: "Video",
//                                                     postMediaObject: "Network",
//                                                     postVideoController:
//                                                         postVideoController,
//                                                   ),
//                                             ),
//                                           )
//                                               .then((_) {
//                                             setState(() {
//                                               postVideoController =
//                                                   new VideoPlayerController
//                                                           .network(
//                                                       widget.post["postVideo"])
//                                                     ..initialize().then((_) {
//                                                       setState(() {});
//                                                     });
//                                             });
//                                           });
//                                         })
//                                     : new Container(), // MEDIA
//                                 new Container(
//                                   margin: EdgeInsets.only(top: 10.0),
//                                   constraints: BoxConstraints(maxWidth: 350.0),
//                                   child: new Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceEvenly,
//                                     children: <Widget>[
//                                       new GestureDetector(
//                                         child: new Container(
//                                           child: new Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.center,
//                                             children: <Widget>[
//                                               new Container(
//                                                 child: new Icon(
//                                                   Icons.repeat,
//                                                   color: postReposts.contains(
//                                                           _currentUser)
//                                                       ? Color.fromRGBO(
//                                                           0, 150, 255, 1.0)
//                                                       : Color.fromRGBO(
//                                                           170, 170, 170, 1.0),
//                                                 ),
//                                               ),
//                                               new Text(
//                                                 postReposts.length.toString(),
//                                                 style: TextStyle(
//                                                     color: postReposts.contains(
//                                                             _currentUser)
//                                                         ? Color.fromRGBO(
//                                                             0, 150, 255, 1.0)
//                                                         : Color.fromRGBO(
//                                                             170, 170, 170, 1.0),
//                                                     fontSize: 15.0,
//                                                     fontFamily: "Avenir",
//                                                     fontWeight:
//                                                         FontWeight.bold),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         onTap: () {
//                                           _handleRepost(index - 1);
//                                         },
//                                       ),
//                                       new GestureDetector(
//                                           child: new Container(
//                                             child: new Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.center,
//                                               children: <Widget>[
//                                                 new Container(
//                                                   child: new Icon(
//                                                     postLikes.contains(
//                                                             _currentUser) ? Icons.mood : Icons.sentiment_neutral,
//                                                     color: postLikes.contains(
//                                                             _currentUser)
//                                                         ? Colors.yellow
//                                                         : Color.fromRGBO(
//                                                             170, 170, 170, 1.0),
//                                                   ),
//                                                 ),
//                                                 new Text(
//                                                   postLikes.length.toString(),
//                                                   style: TextStyle(
//                                                       color: postLikes.contains(
//                                                               _currentUser)
//                                                           ? Colors.yellow
//                                                           : Color.fromRGBO(170,
//                                                               170, 170, 1.0),
//                                                       fontSize: 15.0,
//                                                       fontFamily: "Avenir",
//                                                       fontWeight:
//                                                           FontWeight.bold),
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           onTap: () {
//                                             _handleLike(index - 1);
//                                           }),
//                                       // new GestureDetector(
//                                       //   child: new Container(
//                                       //     child: new Container(
//                                       //       child: new Icon(
//                                       //         Icons.send,
//                                       //         color: Color.fromRGBO(
//                                       //             170, 170, 170, 1.0),
//                                       //       ),
//                                       //     ),
//                                       //   ),
//                                       // ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         )