import 'package:flutter/material.dart';
import 'package:gg/globals.dart' as globals;
import 'package:gg/Components/user_list_page.dart';
import 'post_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:io';
import 'package:gg/UI/post_box.dart';
import 'settings_page.dart';
import 'package:flutter/cupertino.dart';

class ProfilePage extends StatefulWidget {
  _ProfilePage createState() => new _ProfilePage();

  final String userID;
  final bool visitor;

  ProfilePage({
    Key key,
    @required this.userID,
    @required this.visitor,
  }) : super(key: key);
}

class _ProfilePage extends State<ProfilePage> {
  String _currentUser;
  Map<String, dynamic> user;
  List<Map<String, dynamic>> userPosts;
  bool userLoaded;
  bool userPostsLoaded;
  List postReposts = List();
  List postLikes = List();
  List userFollowers = List();

  void initState() {
    super.initState();
    userLoaded = false;
    userPostsLoaded = false;
    if (globals.currentUser == null) {
      _fetchCurrentUser();
    } else {
      _currentUser = widget.userID;
      _fetchUserInfo(_currentUser);
      _fetchUserPosts(_currentUser);
    }
  }

  _fetchCurrentUser() async {
    await FirebaseAuth.instance.currentUser().then((user) {
      if (user != null) {
        _currentUser = user.uid;
        _fetchUserInfo(_currentUser);
        _fetchUserPosts(_currentUser);
      } else {
        print("error");
      }
    });
  }

  _fetchUserInfo(String currentUser) {
    user = {};
    try {
      Firestore.instance.document("Users/$currentUser").get().then(
        (userInfo) {
          if (userInfo.exists) {
            userFollowers = List.from(userInfo.data["userFollowers"]);
            user.addAll({
              "userID": userInfo.data["userID"],
              "userUsername": userInfo.data["userUsername"],
              "userEmail": userInfo.data["userEmail"],
              "userFollowers": userFollowers.length,
              "userPreferredRegion": userInfo.data["userPreferredRegion"],
              "userPhoneNumber": userInfo.data["userPhoneNumber"],
              "userPassword": userInfo.data["userPassword"],
              "userFirstName": userInfo.data["userFirstName"],
              "userLastName": userInfo.data["userLastName"],
              "userBanner": userInfo.data["userBanner"],
              "userPicture": userInfo.data["userPicture"],
            });
          }
        },
      ).whenComplete(() {
        Firestore.instance
            .collection("Users")
            .where("userFollowers", arrayContains: currentUser)
            .getDocuments()
            .then(
          (userFollowingDocuments) {
            user.addAll({
              "userFollowing": userFollowingDocuments.documents.length,
            });
          },
        );
      }).whenComplete(() {
        Firestore.instance
            .collection("Posts")
            .where("postUserID", isEqualTo: currentUser)
            .getDocuments()
            .then(
          (userPostDocuments) {
            user.addAll({"userPosts": userPostDocuments.documents.length});
            setState(() {
              userLoaded = true;
            });
          },
        );
      });
    } catch (error) {
      print(error);
    }
  }

  _fetchUserPosts(String currentUser) async {
    List<Map<String, dynamic>> posts = [];
    List<Map<String, dynamic>> reposts = [];
    bool postsLoaded = false;
    bool repostsLoaded = false;

    try {
      Firestore.instance
          .collection("Posts")
          .where("postUserID", isEqualTo: _currentUser)
          .getDocuments()
          .then((postDocuments) {
        if (postDocuments.documents.isNotEmpty) {
          for (DocumentSnapshot post in postDocuments.documents) {
            Map<String, dynamic> postInfo = Map.from(post.data);
            postInfo.addAll({"postRepostUserID": _currentUser});
            posts.add(postInfo);
            if (posts.length == postDocuments.documents.length) {
              postsLoaded = true;
              if (postsLoaded && repostsLoaded) {
                setState(() {
                  userPosts = posts + reposts;
                  userPosts.sort((postA, postB) =>
                      postA["postDate"].compareTo(postB["postDate"]));
                  userPosts = userPosts.reversed.toList();
                  userPostsLoaded = true;
                });
              }
            }
          }
        } else {
          postsLoaded = true;
          if (postsLoaded && repostsLoaded) {
            setState(() {
              userPosts = posts + reposts;
              userPosts.sort((postA, postB) =>
                  postA["postDate"].compareTo(postB["postDate"]));
              userPosts = userPosts.reversed.toList();
              userPostsLoaded = true;
            });
          }
        }
        Firestore.instance
            .collection("Posts")
            .where("postReposts", arrayContains: _currentUser)
            .getDocuments()
            .then((repostDocuments) {
          if (repostDocuments.documents.isNotEmpty) {
            for (DocumentSnapshot repost in repostDocuments.documents) {
              Map<String, dynamic> repostInfo = Map.from(repost.data);
              repostInfo.addAll({"postRepostUserID": _currentUser});
              reposts.add(repostInfo);
              if (reposts.length == repostDocuments.documents.length) {
                repostsLoaded = true;
                if (postsLoaded && repostsLoaded) {
                  setState(() {
                    userPosts = posts + reposts;
                    userPosts.sort((postA, postB) =>
                        postA["postDate"].compareTo(postB["postDate"]));
                    userPosts = userPosts.reversed.toList();
                    userPostsLoaded = true;
                  });
                }
              }
            }
          } else {
            repostsLoaded = true;
            if (postsLoaded && repostsLoaded) {
              setState(() {
                userPosts = posts + reposts;
                userPosts.sort((postA, postB) =>
                    postA["postDate"].compareTo(postB["postDate"]));
                userPosts = userPosts.reversed.toList();
                userPostsLoaded = true;
              });
            }
          }
        });
      });
    } catch (error) {
      print("Error: $error");
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

  _handleRepost(int repostIndex) {
    bool add;
    setState(() {
      if (postReposts[repostIndex].contains(_currentUser)) {
        postReposts[repostIndex].remove(_currentUser);
        add = false;
      } else {
        postReposts[repostIndex].add(_currentUser);
        add = true;
      }
    });
    try {
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance
                .document("Posts/${userPosts[repostIndex]["postID"]}"))
            .then((postInfo) async {
          if (postInfo.exists) {
            List reposts = List.from(postInfo.data["postReposts"]);
            if (add == true) {
              reposts.add(_currentUser);
            } else {
              reposts.remove(_currentUser);
            }
            await transaction.update(
                Firestore.instance
                    .document("Posts/${userPosts[repostIndex]["postID"]}"),
                <String, dynamic>{"postReposts": reposts});
          }
        });
      });
    } catch (error) {
      print(error);
    }
  }

  _handleLike(int likeIndex) {
    bool add;
    setState(() {
      if (postLikes[likeIndex].contains(_currentUser)) {
        postLikes[likeIndex].remove(_currentUser);
        add = false;
      } else {
        postLikes[likeIndex].add(_currentUser);
        add = true;
      }
    });
    try {
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance
                .document("Posts/${userPosts[likeIndex]["postID"]}"))
            .then((postInfo) async {
          if (postInfo.exists) {
            List likes = List.from(postInfo.data["postLikes"]);
            if (add == true) {
              likes.add(_currentUser);
            } else {
              likes.remove(_currentUser);
            }
            await transaction.update(
                Firestore.instance
                    .document("Posts/${userPosts[likeIndex]["postID"]}"),
                <String, dynamic>{"postLikes": likes});
          }
        });
      });
    } catch (error) {
      print(error);
    }
  }

  _handleFollow(String profileUser, String currentUser) async {
    bool follow;
    setState(() {
      if (userFollowers.contains(currentUser)) {
        userFollowers.remove(currentUser);
        follow = false;
      } else {
        userFollowers.add(currentUser);
        follow = true;
      }
    });
    try {
      Firestore.instance.runTransaction((Transaction transaction) async {
        await transaction
            .get(Firestore.instance.document("Users/$profileUser"))
            .then((userInfo) async {
          if (userInfo.exists) {
            List followers = List.from(userInfo.data["userFollowers"]);
            if (follow == true) {
              followers.add(currentUser);
            } else {
              followers.remove(currentUser);
            }
            await transaction.update(
                Firestore.instance.document("Users/$profileUser"),
                <String, dynamic>{"userFollowers": followers});
          }
        });
      });
    } catch (error) {
      print(error);
    }
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      body: new SafeArea(
        top: false,
        child: new ListView.builder(
          padding: EdgeInsets.only(top: 0.0, bottom: 10.0),
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return new Column(
                children: <Widget>[
                  new Container(
                    height: 160.0,
                    child: new Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        new Container(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(50, 50, 50, 1.0),
                            image: userLoaded
                                ? DecorationImage(
                                    image: NetworkImage(user["userBanner"]),
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center)
                                : null,
                          ),
                          child: new Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                new CircleAvatar(
                                  backgroundColor:
                                      Color.fromRGBO(0, 150, 255, 1.0),
                                  radius: 50.0,
                                  child: new CircleAvatar(
                                    backgroundColor:
                                        Color.fromRGBO(50, 50, 50, 1.0),
                                    backgroundImage: userLoaded
                                        ? NetworkImage(user["userPicture"])
                                        : null,
                                    radius: 46.0,
                                  ),
                                ),
                                new Container(
                                  margin:
                                      EdgeInsets.only(top: 2.0, bottom: 3.0),
                                  child: new Text(
                                    userLoaded ? user["userUsername"] : "",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        fontFamily: "Century Gothic",
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        new AppBar(
                          backgroundColor: Colors.transparent,
                          leading: widget.visitor
                              ? new BackButton(
                                  color: Color.fromRGBO(0, 150, 255, 1.0),
                                )
                              : new Container(),
                          actions: <Widget>[
                            widget.userID != globals.currentUser
                                ? new Container(
                                    margin: EdgeInsets.only(right: 10.0),
                                    alignment: Alignment.center,
                                    child: new GestureDetector(
                                      child: new Container(
                                        alignment: Alignment.center,
                                        child: new Text(
                                          !userFollowers
                                                  .contains(globals.currentUser)
                                              ? "Follow"
                                              : "Following",
                                          style: new TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.0,
                                            fontFamily: "Century Gothic",
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        decoration: BoxDecoration(
                                          color: !userFollowers
                                                  .contains(globals.currentUser)
                                              ? Color.fromRGBO(0, 150, 255, 1.0)
                                              : Color.fromRGBO(
                                                  137, 145, 151, 1.0),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(2.0),
                                          ),
                                        ),
                                        height: 25.0,
                                        width: 85.0,
                                      ),
                                      onTap: () {
                                        _handleFollow(
                                            widget.userID, globals.currentUser);
                                      },
                                    ),
                                  )
                                : new Container(),
                            widget.userID != globals.currentUser
                                ? new GestureDetector(
                                    child: new Container(
                                      height: 20.0,
                                      width: 20.0,
                                      margin: EdgeInsets.only(right: 10.0),
                                      color: Colors.transparent,
                                      child: new Icon(
                                        Icons.more_vert,
                                        size: 20.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () {
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CupertinoActionSheet(
                                            actions: <Widget>[
                                              new Container(
                                                color: Color.fromRGBO(40, 40, 40, 1.0),
                                              child: new CupertinoActionSheetAction(
                                                child: new Container(
                                                  child: new Text(
                                                    "Block User",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 20.0,
                                                      fontFamily: "Century Gothic",
                                                      fontWeight: FontWeight.bold
                                                    ),
                                                  )
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                          ),
                                            ],
                                            cancelButton: new Container(
                                              decoration: BoxDecoration(
                                                color: Color.fromRGBO(40, 40, 40, 1.0),
                                                borderRadius: BorderRadius.all(Radius.circular(13.0))
                                              ),
                                              child: new CupertinoActionSheetAction(
                                                child: new Container(
                                                  child: new Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20.0,
                                                      fontFamily: "Century Gothic",
                                                      fontWeight: FontWeight.bold
                                                    ),
                                                  )
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                          ),
                                          );
                                        }
                                      );
                                    }
                                  )
                                : new Container(),
                            !widget.visitor &&
                                    globals.currentUser == _currentUser
                                ? new IconButton(
                                    icon: new Icon(
                                      Icons.description,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      if (userLoaded) {
                                        if (widget.visitor) {
                                        } else {
                                          Navigator.of(context)
                                              .pushNamed('/PostPage');
                                        }
                                      }
                                    },
                                  )
                                : new Container(),
                          ],
                          elevation: 0.0,
                        ),
                      ],
                    ),
                  ),
                  new Container(
                    child: new Stack(
                      alignment: Alignment.centerRight,
                      children: <Widget>[
                        new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            new Container(
                              width: 65.0,
                              child: new Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  new Container(
                                    child: new AutoSizeText(
                                      userLoaded
                                          ? user["userPosts"].toString()
                                          : "",
                                      minFontSize: 20.0,
                                      maxFontSize: 25.0,
                                      style: new TextStyle(
                                        color:
                                            Color.fromRGBO(170, 170, 170, 1.0),
                                        fontFamily: "Century Gothic",
                                        fontSize: 25.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  new Container(
                                    margin:
                                        EdgeInsets.only(top: 4.0, left: 4.0),
                                    child: new Text(
                                      "Posts",
                                      style: new TextStyle(
                                        color:
                                            Color.fromRGBO(170, 170, 170, 1.0),
                                        fontFamily: "Century Gothic",
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            new GestureDetector(
                              child: new Container(
                                width: 65.0,
                                color: Colors.transparent,
                                margin:
                                    EdgeInsets.only(left: 25.0, right: 25.0),
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Container(
                                      child: new AutoSizeText(
                                        userLoaded
                                            ? user["userFollowers"].toString()
                                            : "",
                                        minFontSize: 20.0,
                                        maxFontSize: 25.0,
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    new Container(
                                      margin:
                                          EdgeInsets.only(top: 4.0, left: 4.0),
                                      child: new Text(
                                        "Followers",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                if (widget.visitor != true &&
                                    userLoaded &&
                                    user["userFollowers"] != 0) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          new UserListPage(
                                            title: "Followers",
                                            id: _currentUser,
                                            currentUser: "",
                                          ),
                                    ),
                                  );
                                }
                              },
                            ),
                            new GestureDetector(
                              child: new Container(
                                width: 65.0,
                                color: Colors.transparent,
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new Container(
                                      child: new AutoSizeText(
                                        userLoaded
                                            ? user["userFollowing"].toString()
                                            : "",
                                        minFontSize: 20.0,
                                        maxFontSize: 25.0,
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 25.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    new Container(
                                      margin: EdgeInsets.only(top: 4.0),
                                      child: new Text(
                                        "Following",
                                        style: new TextStyle(
                                          color: Color.fromRGBO(
                                              170, 170, 170, 1.0),
                                          fontFamily: "Century Gothic",
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                if (widget.visitor != true &&
                                    userLoaded &&
                                    user["userFollowing"] != 0) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          new UserListPage(
                                            title: "Following",
                                            id: _currentUser,
                                            currentUser: "",
                                          ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        userLoaded && !widget.visitor
                            ? new IconButton(
                                padding: EdgeInsets.only(right: 10.0),
                                icon: new Icon(
                                  Icons.settings,
                                  size: 30.0,
                                  color: Color.fromRGBO(170, 170, 170, 1.0),
                                ),
                                onPressed: () {
                                  print(user);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          new SettingsPage(
                                            userInfo: user,
                                          ),
                                    ),
                                  );
                                },
                              )
                            : new Container(),
                      ],
                    ),
                  ),
                  userPostsLoaded && userPosts.isEmpty
                      ? new Container(
                          margin: EdgeInsets.only(top: 200.0),
                          alignment: Alignment.center,
                          child: new Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              new Container(
                                margin: EdgeInsets.only(bottom: 10.0),
                                child: new Text(
                                  "No Posts Yet",
                                  style: TextStyle(
                                      color: Color.fromRGBO(170, 170, 170, 1.0),
                                      fontSize: 20.0,
                                      fontFamily: "Century Gothic",
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              !widget.visitor
                                  ? new GestureDetector(
                                      child: new Container(
                                        color: Colors.transparent,
                                        child: new Text(
                                          "Share your first post",
                                          style: TextStyle(
                                              color: Color.fromRGBO(
                                                  0, 150, 255, 1.0),
                                              fontSize: 18.0,
                                              fontFamily: "Century Gothic",
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.of(context)
                                            .pushNamed('/PostPage');
                                      })
                                  : new Container(),
                            ],
                          ),
                        )
                      : new Container()
                ],
              );
            } else {
              int postIndex;
              Map<dynamic, dynamic> userPost;
              if (userPostsLoaded) {
                postIndex = index - 1;
                userPost = userPosts[postIndex];
              }
              return userPostsLoaded
                  ? new PostBox(
                      post: userPost,
                      currentUser: _currentUser,
                    )
                  : new Center(
                      child: new CircularProgressIndicator(
                        backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                      ),
                    );
            }
          },
          itemCount: userPostsLoaded ? userPosts.length + 1 : 2,
        ),
      ),
    );
  }
}
