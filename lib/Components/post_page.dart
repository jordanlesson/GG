import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gg/globals.dart' as globals;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:flutter/cupertino.dart';
import 'master_page.dart';
import 'media_page.dart';

class PostPage extends StatefulWidget {
  _PostPage createState() => new _PostPage();
}

class _PostPage extends State<PostPage> {
  final postTextController = new TextEditingController();
  int postTextLength;
  File postMedia;
  File previousPostMedia;
  String postMediaType;
  String postPreviousMediaType;
  bool postInProgress;
  bool postMediaLoaded;
  VideoPlayerController postVideoController;
  FocusNode postFocusNode;

  @override
  void initState() {
    super.initState();
    postTextController.addListener(post);
    postTextLength = 0;
    postMediaLoaded = false;
    postInProgress = false;
    postFocusNode = new FocusNode();
  }

  post() {
    setState(() {
      postTextLength = postTextController.text.length;
    });
  }

  _fetchCamera(String media) async {
    previousPostMedia = postMedia;
    if (media == "Image") {
      postMedia = await ImagePicker.pickImage(source: ImageSource.camera);
    } else {
      postMedia = await ImagePicker.pickVideo(source: ImageSource.camera);
    }
    if (postMedia != null) {
      setState(() {
        print(postMedia);
        postMediaType = media;
        postMediaLoaded = true;
      });
      if (postMediaType == "Video") {
        postVideoController = VideoPlayerController.file(postMedia)
          ..initialize().then((_) {
            setState(() {});
          });
      }
    } else {
      setState(() {
        postMedia = previousPostMedia;
        if (postMediaType == "Video") {
          postVideoController = VideoPlayerController.file(postMedia)
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    }
  }

  _fetchMediaLibrary(String media) async {
    previousPostMedia = postMedia;
    if (media == "Image") {
      postMedia = await ImagePicker.pickImage(source: ImageSource.gallery);
    } else {
      postMedia = await ImagePicker.pickVideo(source: ImageSource.gallery);
    }
    if (postMedia != null) {
      setState(() {
        print(postMedia);
        postMediaType = media;
        postMediaLoaded = true;
        if (postMediaType == "Video") {
          postVideoController = VideoPlayerController.file(postMedia)
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    } else {
      setState(() {
        postMedia = previousPostMedia;
        if (postMediaType == "Video") {
          postVideoController = VideoPlayerController.file(postMedia)
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

  _handlePost(String currentUser, String postBody, bool postMediaExists,
      String postMediaType, File postMedia) async {
    setState(() {
      postInProgress = true;
    });
    await Firestore.instance.collection("Posts").add({
      "postBody": postBody,
      "postDate": DateTime.now().toUtc(),
      "postLikes": [],
      "postReposts": [],
      "postUserID": currentUser,
      "postID": "",
      "postPicture": "",
      "postVideo": ""
    }).then((postInfo) async {
      if (postMediaExists) {
        dynamic pictureDownloadUrl = "";
        dynamic videoDownloadUrl = "";
        StorageReference mediaRef;
        if (postMediaType == "Image") {
          mediaRef = FirebaseStorage.instance
              .ref()
              .child("Posts/${postInfo.documentID}/media.png");
        } else {
          mediaRef = FirebaseStorage.instance
              .ref()
              .child("Posts/${postInfo.documentID}/media.mov");
        }

        mediaRef.putFile(postMedia).onComplete.then((_) async {
          if (postMediaType == "Image") {
            pictureDownloadUrl = await mediaRef.getDownloadURL();
          } else {
            videoDownloadUrl = await mediaRef.getDownloadURL();
          }
        }).then((_) {
          Firestore.instance
              .document("Posts/${postInfo.documentID}")
              .updateData({
            "postPicture": pictureDownloadUrl.toString(),
            "postVideo": videoDownloadUrl.toString(),
            "postID": postInfo.documentID,
          }).then((_) {
            setState(() {
              postInProgress = false;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new MasterPage(
                        currentIndex: 0,
                      ),
                ),
              );
            });
          });
        });
      } else {
        Firestore.instance
              .document("Posts/${postInfo.documentID}")
              .updateData({
            "postID": postInfo.documentID,
          }).then((_) {
            setState(() {
              postInProgress = false;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new MasterPage(
                        currentIndex: 0,
                      ),
                ),
              );
            });
          }).then((_) {
            setState(() {
              postInProgress = false;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => new MasterPage(
                        currentIndex: 0,
                      ),
                ),
              );
            });
          });
        
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: postInProgress
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
              padding: EdgeInsets.only(right: 10.0),
              color: Colors.transparent,
              alignment: Alignment.center,
              child: new Text(
                "Publish",
                style: TextStyle(
                  color: postTextLength > 0 && postTextLength <= 200 ||
                          postMedia != null
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              if (postTextLength > 0 && postTextLength <= 200 ||
                  postMedia != null && !postInProgress) {
                print("PUBLISH");
                _handlePost(globals.currentUser, postTextController.text,
                    postMediaLoaded, postMediaType, postMedia);
              }
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new Column(
            children: <Widget>[
              new Expanded(
                child: new Container(
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: new Scrollbar(
                    child: new TextFormField(
                      autofocus: true,
                      //focusNode: postFocusNode,
                      autocorrect: true,
                      controller: postTextController,
                      maxLines: null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10.0),
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 25.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold),
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              postMediaLoaded
                  ? new Expanded(
                      child: new Container(
                        constraints: BoxConstraints(maxWidth: 350.0),
                        margin: EdgeInsets.symmetric(horizontal: 15.0),
                        padding: EdgeInsets.only(bottom: 20.0),
                        alignment: Alignment.bottomCenter,
                        child: new AspectRatio(
                          aspectRatio: 16.0 / 9.0,
                          child: new GestureDetector(
                            child: new Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 1.0,
                                  color: Color.fromRGBO(40, 40, 40, 1.0),
                                ),
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              child: new Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  postMediaType == "Image"
                                      ? new Image.file(
                                          postMedia,
                                          fit: BoxFit.cover,
                                        )
                                      : new RotatedBox(
                                          quarterTurns: 1,
                                          child: new VideoPlayer(
                                              postVideoController),
                                        ),
                                  new Align(
                                    alignment: Alignment.topRight,
                                    child: new Container(
                                      color: Color.fromRGBO(0, 150, 255, 1.0),
                                      child: new IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            postMedia = null;
                                            postMediaLoaded = false;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  postMediaType == "Video"
                                      ? new Center(
                                          child: new Container(
                                            height: 50.0,
                                            width: 50.0,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(
                                                  40, 40, 40, 0.7),
                                              borderRadius:
                                                  BorderRadius.circular(25.0),
                                            ),
                                            child: new Icon(
                                              Icons.play_arrow,
                                              color: Color.fromRGBO(
                                                  255, 255, 255, 0.7),
                                              size: 40.0,
                                            ),
                                          ),
                                        )
                                      : new Container(),
                                ],
                              ),
                            ),
                            onTap: () {
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (BuildContext context) {
                                  return new MediaPage(
                                    postMedia: postMedia,
                                    postMediaType: postMediaType,
                                    postMediaObject: "File",
                                    postVideoController: postVideoController,
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  : new Container(),
              new SafeArea(
                top: false,
                child: new Container(
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
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      new GestureDetector(
                        child: new Container(
                          alignment: Alignment.center,
                          color: Colors.transparent,
                          height: 30.0,
                          width: 30.0,
                          margin: EdgeInsets.only(left: 10.0, right: 20.0),
                          child: new Icon(
                            Icons.camera_alt,
                            size: 30.0,
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                          ),
                        ),
                        onTap: () {
                          print("MEDIA");
                          FocusScope.of(context).requestFocus(new FocusNode());
                          _mediaPicker(context, "Image");
                        },
                      ),
                      new Expanded(
                      child: new Container(
                      alignment: Alignment.centerLeft,
                      child: new GestureDetector(
                        child: new Container(
                          alignment: Alignment.center,
                          color: Colors.transparent,
                          height: 30.0,
                          width: 30.0,
                          margin: EdgeInsets.only(right: 10.0),
                          child: new Icon(
                            Icons.video_library,
                            size: 30.0,
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                          ),
                        ),
                        onTap: () {
                          print("MEDIA");
                          FocusScope.of(context).requestFocus(new FocusNode());
                          _mediaPicker(context, "Video");
                        },
                      ),
                  ),
                  ),
                      new Container(
                        margin: EdgeInsets.only(right: 10.0),
                        child: new Text(
                          "${postTextLength.toString()}/200",
                          style: TextStyle(
                              color: postTextLength <= 200
                                  ? Color.fromRGBO(170, 170, 170, 1.0)
                                  : Colors.red,
                              fontSize: 20.0,
                              fontFamily: "Century Gothic",
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          postInProgress
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