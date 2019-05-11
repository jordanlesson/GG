import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gg/globals.dart' as globals;
import 'post_detail_page.dart';
import 'package:video_player/video_player.dart';
import 'media_page.dart';
import 'package:gg/UI/post_box.dart';
import 'search_page.dart';
import 'report_bug_page.dart';

class HomePage extends StatefulWidget {
  _HomePage createState() => new _HomePage();
}

class _HomePage extends State<HomePage> {
  String _currentUser;
  List<Map<String, dynamic>> posts;
  bool postsLoaded;
  List postReposts = List();
  List postLikes = List();
  bool postsEmpty;
  ScrollController postScrollController;

  void initState() {
    super.initState();
    postsLoaded = false;
    postsEmpty = false;
    if (globals.currentUser == null) {
      _fetchCurrentUser();
    } else {
      _currentUser = globals.currentUser;
      _fetchFollowerPosts();
    }
    postScrollController = new ScrollController();
  }

  _fetchCurrentUser() async {
    await FirebaseAuth.instance.currentUser().then((user) {
      if (user != null) {
        _currentUser = user.uid;
        _fetchFollowerPosts();
      } else {
        print("error");
      }
    });
  }

  _orderPosts(List<Map<String, dynamic>> postInfo) {

    postInfo.sort((postA, postB) => postA["postDate"].compareTo(postB["postDate"]));
    
    setState(() {
      posts = postInfo.reversed.toList();
      postsLoaded = true;
      print("Posts Loaded");
        });

  }

  _fetchUserPosts(List<Map<String, dynamic>> followerPosts) async {
    List<Map<String, dynamic>> posts = [];

    List<Map<String, dynamic>> userPosts = [];
    Firestore.instance
        .collection("Posts")
        .where("postUserID", isEqualTo: _currentUser)
        .orderBy("postDate", descending: true)
        .getDocuments()
        .then((userPostDocuments) {
          print("User Posts Loaded");
      if (userPostDocuments.documents.isNotEmpty) {
        for (DocumentSnapshot userPost in userPostDocuments.documents) {
          Map<String, dynamic> userPostInfo = Map.from(userPost.data);
            userPostInfo.addAll({"postRepostUserID": _currentUser});
            userPosts.add(userPostInfo);
          if (userPosts.length == userPostDocuments.documents.length) {
              posts = userPosts + followerPosts;
              _orderPosts(posts);
            
          }
        }
      } else {
          posts = userPosts + followerPosts;
          _orderPosts(posts);
      }
    });
  }

  _fetchFollowerPosts() async {
    print("Loading Follower Posts...");
    List<Map<String, dynamic>> followerTotalPosts = [];
    bool followerPostsLoaded = false;
    bool followerRepostsLoaded = false;

    try {
      List<Map<String, dynamic>> followerPosts = [];
      List<Map<String, dynamic>> followerReposts = [];
      Firestore.instance.collection("Users").where("userFollowers", arrayContains: _currentUser).getDocuments().then((followingDocuments) {
        if (followingDocuments.documents.isNotEmpty) {
          for (DocumentSnapshot followingDocument in followingDocuments.documents) {
            String following = followingDocument.documentID;
            Firestore.instance
                .collection("Posts")
                .where("postUserID", isEqualTo: following)
                .orderBy("postDate", descending: true)
                .getDocuments()
                .then((followerPostDocuments) {
                  print("Follow Posts Loaded");
              Firestore.instance
                  .collection("Posts")
                  .where("postReposts", arrayContains: following)
                  .orderBy("postDate", descending: true)
                  .getDocuments()
                  .then((followerRepostDocuments) {
                    print("Follow Reposts Loaded");
                if (followerRepostDocuments.documents.isNotEmpty) {
                  for (DocumentSnapshot followerRepost
                      in followerRepostDocuments.documents) {
                        Map<String, dynamic> followerRepostInfo = Map.from(followerRepost.data);
                        followerRepostInfo.addAll({"postRepostUserID": following});
                    followerReposts.add(followerRepostInfo);
                    if (followerReposts.length ==
                        followerRepostDocuments.documents.length) {
                      followerRepostsLoaded = true;
                      if (followerPostsLoaded && followerRepostsLoaded) {
                        followerTotalPosts = followerPosts + followerReposts;
                        _fetchUserPosts(followerTotalPosts);
                      }
                    }
                  }
                } else {
                  followerRepostsLoaded = true;
                  if (followerPostsLoaded && followerRepostsLoaded) {
                    followerTotalPosts = followerPosts + followerReposts;
                    _fetchUserPosts(followerTotalPosts);
                  }
                }
              });
              if (followerPostDocuments.documents.isNotEmpty) {
                for (DocumentSnapshot followerPost
                    in followerPostDocuments.documents) {
                      Map<String, dynamic> followerPostInfo = Map.from(followerPost.data);
                        followerPostInfo.addAll({"postRepostUserID": following});
                  followerPosts.add(followerPostInfo);
                  if (followerPosts.length ==
                      followerPostDocuments.documents.length) {
                    followerPostsLoaded = true;
                    if (followerPostsLoaded && followerRepostsLoaded) {
                      followerTotalPosts = followerPosts + followerReposts;
                      _fetchUserPosts(followerTotalPosts);
                    }
                  }
                }
              } else {
                followerPostsLoaded = true;
                if (followerPostsLoaded && followerRepostsLoaded) {
                  followerTotalPosts = followerPosts + followerReposts;
                  _fetchUserPosts(followerTotalPosts);
                }
              }
            });
          }
        } else {
          _fetchUserPosts(followerPosts);
        
        }
      });
    } catch (error) {
      print("Error $error");
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        centerTitle: true,
        title: new GestureDetector(
          child: new Container(
            color: Colors.transparent,
            child: new Image.asset(
              "assets/gglogo.png",
              width: 100.0,
              height: 28.0,
            ),
          ),
          onTap: () {
            if (postsLoaded) {
            postScrollController.animateTo(
                postScrollController.initialScrollOffset,
                duration: Duration(milliseconds: 200),
                curve: Curves.ease);
            }
            _fetchFollowerPosts();
          },
        ),
        leading: new Container(),
        elevation: 0.0,
        actions: <Widget>[
          new IconButton(
            icon: Icon(
              Icons.bug_report,
              color: Colors.white,
            ),
            onPressed: () {
              print("BUG");
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new ReportBugPage(),
                ),
              );
            },
          ),
          new IconButton(
            icon: new Icon(
              Icons.search,
              color: Colors.white,
              size: 25.0,
            ),
            onPressed: () {
              showSearch(context: context, delegate: SearchPage());
            },
          ),
          new IconButton(
            icon: new Icon(
              Icons.description,
              color: Colors.white,
              size: 25.0,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed("/PostPage");
            },
          ),
        ],
      ),
      body: postsLoaded != true
          ? new Center(
              child: postsEmpty
                  ? new Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Container(
                          margin: EdgeInsets.only(bottom: 10.0),
                          child: new Text(
                            "No Feed Yet",
                            style: TextStyle(
                              color: Color.fromRGBO(170, 170, 170, 1.0),
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        new GestureDetector(
                          child: new Text(
                            "Find other gamers",
                            style: TextStyle(
                                color: Color.fromRGBO(0, 150, 255, 1.0),
                                fontSize: 18.0,
                                fontFamily: "Century Gothic",
                                fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            showSearch(
                                context: context, delegate: SearchPage());
                          },
                        )
                      ],
                    )
                  : new CircularProgressIndicator(
                      backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                    ),
            )
          : new Container(
              child: new RefreshIndicator(
                child: new ListView.builder(
                  padding: EdgeInsets.only(top: 0.0, bottom: 10.0),
                  controller: postScrollController,
                  itemBuilder: (BuildContext context, int index) {
                    var post = posts[index];
                    return PostBox(
                      post: post,
                      currentUser: _currentUser,
                    );
                  },
                  itemCount: posts.length,
                ),
                backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
                onRefresh: () async {
                  _fetchFollowerPosts();
                  await Future.delayed(Duration(seconds: 2));
                  return null;
                },
              ),
            ),
    );
  }
}
