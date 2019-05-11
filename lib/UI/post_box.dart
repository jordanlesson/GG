import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gg/Components/media_page.dart';
import 'package:gg/Components/post_detail_page.dart';

class PostBox extends StatefulWidget {
  _PostBox createState() => new _PostBox();

  final Map<dynamic, dynamic> post;
  final String currentUser;

  PostBox({Key key, @required this.post, @required this.currentUser})
      : super(key: key);
}

class _PostBox extends State<PostBox> {
  Map<dynamic, dynamic> post;
  String _currentUser;
  VideoPlayerController postVideoController;
  bool reported;

  @override
  void initState() {
    super.initState();
    reported = false;
    post = Map.from(widget.post);
    _currentUser = widget.currentUser;
    if (post["postVideo"] != "") {
      print("Initialized");
      postVideoController = new VideoPlayerController.network(post["postVideo"])
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  fetchTimeStamp(DateTime postDate) {
    var timeDifference = postDate.difference(DateTime.now()).abs();
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
      return "${postDate.month.toString()}/${postDate.day.toString()}/${postDate.year.toString()}";
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
            .get(Firestore.instance.document("Posts/${post["postID"]}"))
            .then((postInfo) async {
          if (postInfo.exists) {
            List reposts = List.from(postInfo.data["postReposts"]);
            if (add == true) {
              reposts.add(_currentUser);
            } else {
              reposts.remove(_currentUser);
            }
            await transaction.update(
                Firestore.instance.document("Posts/${post["postID"]}"),
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
            .get(Firestore.instance.document("Posts/${post["postID"]}"))
            .then((postInfo) async {
          if (postInfo.exists) {
            List likes = List.from(postInfo.data["postLikes"]);
            if (add == true) {
              likes.add(_currentUser);
            } else {
              likes.remove(_currentUser);
            }
            await transaction.update(
                Firestore.instance.document("Posts/${post["postID"]}"),
                <String, dynamic>{"postLikes": likes});
          }
        });
      });
    } catch (error) {
      print(error);
    }
  }

  _handleReport() {
    setState(() {
          if (reported) {
            reported = false;
          } else {
            reported = true;
          }
        });
  }

  Widget build(BuildContext context) {
    post = Map.from(widget.post);
     _currentUser = widget.currentUser;
    return new GestureDetector(
      child: new Container(
        margin: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 0.0),
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
                        new GestureDetector(
                          child: new Container(
                            color: Colors.transparent,
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                new Container(
                              child: new Icon(
                                Icons.report,
                                color: reported
                                    ? Colors.red
                                    : Color.fromRGBO(170, 170, 170, 1.0),
                              ),
                            ),
                              ],
                            ),
                          ),
                          onTap: () {
                            _handleReport();
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
      ),
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (BuildContext context) => new PostDetailPage(
                  currentUser: _currentUser,
                  post: post,
                  postLikes: post["postLikes"],
                  postReposts: post["postReposts"],
                ),
          ),
        )
            .then((postInfo) {
          setState(() {
            if (post["postVideo"] != "") {
              postVideoController =
                  new VideoPlayerController.network(post["postVideo"])
                    ..initialize().then((_) {
                      setState(() {});
                    });
            }
            if (postInfo != null) {
              post["postReposts"] = postInfo[1];
              post["postLikes"] = postInfo[2];
            }
          });
        });
      },
    );
  }
}

