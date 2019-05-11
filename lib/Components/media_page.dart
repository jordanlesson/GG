import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

class MediaPage extends StatefulWidget {
  _MediaPage createState() => new _MediaPage();

  final String postMediaType;
  final dynamic postMedia;
  final VideoPlayerController postVideoController;
  final String postMediaObject;

  MediaPage(
      {Key key,
      @required this.postMedia,
      @required this.postMediaType,
      @required this.postMediaObject,
      this.postVideoController})
      : super(key: key);
}

class _MediaPage extends State<MediaPage> {
  VideoPlayerController postVideoController;
  Duration postVideoTotalDuration;
  bool mediaMenuVisible;

  @override
  void initState() {
    super.initState();
    mediaMenuVisible = true;
    postVideoTotalDuration = Duration(seconds: 1);
    if (widget.postMediaType == "Video") {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      if (widget.postMediaObject == "File") {
        postVideoController = VideoPlayerController.file(widget.postMedia)
          ..initialize().then((_) {
            setState(() {
              postVideoTotalDuration = postVideoController.value.duration;
              print(postVideoTotalDuration);
              postVideoController.addListener(() {
                if (postVideoController.value.isPlaying) {
                  setState(() {});
                }
              });
            });
            if (mounted) {
              return;
            }
          })
          ..setVolume(0.5)
          ..play();
      } else {
        postVideoController = VideoPlayerController.network(widget.postMedia)
          ..initialize().then((_) {
            setState(() {
              postVideoTotalDuration = postVideoController.value.duration;
              print(postVideoTotalDuration);
              postVideoController.addListener(() {
                if (postVideoController.value.isPlaying) {
                  setState(() {});
                }
              });
            });
            if (mounted) {
              return;
            }
          })
          ..setVolume(0.5)
          ..play();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.postMediaType == "Video") {
      postVideoController.dispose();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  String _fetchVideoPosition(Duration currentDuration) {
    String seconds;
    if (currentDuration.inSeconds - (currentDuration.inMinutes * 60) < 10) {
      seconds = "0${(currentDuration.inMilliseconds / 1000).ceil()}";
    } else {
      seconds = (currentDuration.inMilliseconds / 1000).ceil().toString();
    }
    if (currentDuration.inMinutes < 1) {
      return "00:$seconds";
    } else if (currentDuration.inMinutes < 10) {
      return "0${currentDuration.inMinutes}:$seconds";
    } else {
      return "${currentDuration.inMinutes}:$seconds";
    }
  }

  String _fetchVideoTotalDuration(Duration totalDuration) {
    String seconds;
    String minutes;
    if (totalDuration.inSeconds - (totalDuration.inMinutes * 60) < 10) {
      seconds = "0${(totalDuration.inMilliseconds / 1000).ceil()}";
    } else {
      seconds = (totalDuration.inMilliseconds / 1000).ceil().toString();
    }
    if (totalDuration.inMinutes < 10) {
      minutes = "0${totalDuration.inMinutes}";
    } else {
      minutes = totalDuration.inMinutes.toString();
    }
    return "$minutes:$seconds";
  }

  Widget build(BuildContext context) {
    return widget.postMediaType == "Image"
        ? new GestureDetector(
            child: new Scaffold(
              backgroundColor: Colors.black,
              body: new Stack(
                children: <Widget>[
                  new Container(
                    alignment: Alignment.center,
                    child: widget.postMediaObject == "File"
                        ? new Image.file(
                            widget.postMedia,
                            fit: BoxFit.cover,
                          )
                        : new Image.network(
                            widget.postMedia,
                            fit: BoxFit.cover,
                          ),
                  ),
                  new Visibility(
                    visible: mediaMenuVisible,
                    child: new Container(
                      height: 75.0,
                      child: new AppBar(
                        backgroundColor: Colors.transparent,
                        leading: 
                        new Container(
                          width: 50.0,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(23, 23, 23, 0.9),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: new IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        elevation: 0.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              setState(() {
                mediaMenuVisible = !mediaMenuVisible;
              });
            })
        : new OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
             return 
             //orientation == Orientation.portrait ?
                 new Scaffold(
                    backgroundColor: Colors.black,
                    body: new GestureDetector(
                      child: new Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          new Center(
                            child: new AspectRatio(
                              aspectRatio:
                                  widget.postVideoController.value.aspectRatio,
                              child: new RotatedBox(
                                quarterTurns: 1,
                                child: new VideoPlayer(postVideoController),
                              ),
                            ),
                          ),
                          new Visibility(
                            visible: mediaMenuVisible,
                            child: new AppBar(
                              backgroundColor: Colors.transparent,
                              leading: new Container(
                                width: 50.0,
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(23, 23, 23, 0.9),
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: new IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              actions: <Widget>[
                                new Container(
                                  width: 220.0,
                                  margin: EdgeInsets.only(right: 10.0),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 10.0),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(23, 23, 23, 0.9),
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                  child: new Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      new Icon(
                                        Icons.volume_up,
                                        color: Colors.white,
                                      ),
                                      new CupertinoSlider(
                                        min: 0.0,
                                        max: 1.0,
                                        value: postVideoController.value.volume,
                                        activeColor:
                                            Color.fromRGBO(0, 150, 255, 1.0),
                                        onChanged: (videoVolume) {
                                          setState(() {
                                            postVideoController
                                                .setVolume(videoVolume);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          new Visibility(
                            visible: mediaMenuVisible,
                            child: new Container(
                              alignment: Alignment.bottomCenter,
                              margin:
                                  EdgeInsets.fromLTRB(15.0, 0.0, 15.0, 20.0),
                              constraints: BoxConstraints(maxWidth: 350.0),
                              child: new Material(
                                type: MaterialType.transparency,
                                child: new Container(
                                  alignment: Alignment.center,
                                  height: 100.0,
                                  decoration: BoxDecoration(
                                      color: Color.fromRGBO(23, 23, 23, 0.9),
                                      borderRadius:
                                          BorderRadius.circular(30.0)),
                                  child: new Column(
                                    children: <Widget>[
                                      new Expanded(
                                        child: new Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            new GestureDetector(
                                              child: new Container(
                                                alignment: Alignment.center,
                                                height: 50.0,
                                                child: new Icon(
                                                  Icons.skip_previous,
                                                  color: Colors.white,
                                                  size: 40.0,
                                                ),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  postVideoController
                                                    ..seekTo(
                                                        Duration(seconds: 0))
                                                    ..play();
                                                });
                                              },
                                            ),
                                            new GestureDetector(
                                              child: new Container(
                                                alignment: Alignment.center,
                                                height: 50.0,
                                                child: new Icon(
                                                  postVideoController
                                                          .value.isPlaying
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 40.0,
                                                ),
                                              ),
                                              onTap: () {
                                                if (postVideoController
                                                    .value.isPlaying) {
                                                  setState(() {
                                                    postVideoController.pause();
                                                  });
                                                } else if ((postVideoController
                                                                .value
                                                                .position
                                                                .inMilliseconds /
                                                            1000)
                                                        .ceilToDouble() ==
                                                    (postVideoTotalDuration
                                                                .inMilliseconds /
                                                            1000)
                                                        .ceilToDouble()) {
                                                  setState(() {
                                                    postVideoController
                                                      ..seekTo(
                                                          Duration(seconds: 0))
                                                      ..play();
                                                  });
                                                } else {
                                                  setState(() {
                                                    postVideoController.play();
                                                  });
                                                }
                                              },
                                            ),
                                            new GestureDetector(
                                              child: new Container(
                                                alignment: Alignment.center,
                                                height: 50.0,
                                                child: new Icon(
                                                  Icons.skip_next,
                                                  color: Colors.white,
                                                  size: 40.0,
                                                ),
                                              ),
                                              onTap: () {
                                                if ((postVideoController
                                                                .value
                                                                .position
                                                                .inMilliseconds /
                                                            1000)
                                                        .ceilToDouble() !=
                                                    (postVideoTotalDuration
                                                                .inMilliseconds /
                                                            1000)
                                                        .ceilToDouble()) {
                                                  setState(() {
                                                    postVideoController.seekTo(
                                                        postVideoController
                                                            .value.duration);
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      // new Expanded(
                                      //   child: new Row(
                                      //     mainAxisAlignment:
                                      //         MainAxisAlignment.center,
                                      //     children: <Widget>[
                                      //       new Text(
                                      //         _fetchVideoPosition(
                                      //             postVideoController
                                      //                 .value.position),
                                      //         style: TextStyle(
                                      //             color: Color.fromRGBO(
                                      //                 170, 170, 170, 1.0),
                                      //             fontSize: 13.0,
                                      //             fontFamily: "Avenir",
                                      //             fontWeight: FontWeight.bold),
                                      //       ),
                                      //       new Align(
                                      //         alignment: Alignment.center,
                                      //         child: new CupertinoSlider(
                                      //           min: 0.0,
                                      //           max: (postVideoTotalDuration
                                      //                       .inMilliseconds /
                                      //                   1000)
                                      //               .ceilToDouble(),
                                      //           onChanged: (videoDuration) {
                                      //             setState(() {
                                      //               postVideoController.seekTo(
                                      //                   Duration(
                                      //                       seconds: videoDuration
                                      //                           .toInt()));
                                      //               print(postVideoController
                                      //                   .value.position.inSeconds
                                      //                   .toDouble());
                                      //             });
                                      //           },
                                      //           activeColor: Color.fromRGBO(
                                      //               0, 150, 255, 1.0),
                                      //           value:
                                      //               // (postVideoController.value.position.inMilliseconds / 1000).toDouble() > (postVideoTotalDuration.inMilliseconds / 1000).ceilToDouble() ?
                                      //               // (postVideoTotalDuration.inMilliseconds / 1000).toDouble() :
                                      //               (postVideoController
                                      //                           .value
                                      //                           .position
                                      //                           .inMilliseconds /
                                      //                       1000)
                                      //                   .ceilToDouble(),
                                      //         ),
                                      //       ),
                                      //       new Text(
                                      //         _fetchVideoTotalDuration(
                                      //             postVideoTotalDuration),
                                      //         style: TextStyle(
                                      //             color: Color.fromRGBO(
                                      //                 170, 170, 170, 1.0),
                                      //             fontSize: 13.0,
                                      //             fontFamily: "Avenir",
                                      //             fontWeight: FontWeight.bold),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          mediaMenuVisible = !mediaMenuVisible;
                        });
                      },
                    ),
                  );
                // : new Container(
                //     color: Colors.white,
                //   );
          });
  }
}
