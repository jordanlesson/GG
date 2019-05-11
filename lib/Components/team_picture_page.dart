import 'package:flutter/material.dart';
import 'package:gg/UI/picture_dialog.dart';
import 'package:flutter/scheduler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'team_overview_page.dart';

class TeamPicturePage extends StatefulWidget {
  final Map<String, dynamic> team;

  TeamPicturePage({Key key, @required this.team}) : super(key: key);

  _TeamPicturePage createState() => _TeamPicturePage();
}

class _TeamPicturePage extends State<TeamPicturePage> {
  Map<String, dynamic> team;
  int selectedPicture;

  @override
  void initState() {
    super.initState();
    team = Map.from(widget.team);

  }

  Future<Null> _mediaPicker(BuildContext context) async {
    _fetchCamera() async {
      File mediaPicture =
          await ImagePicker.pickImage(source: ImageSource.camera);
      if (mediaPicture != null) {
        setState(() {
          team["teamPicture"] = mediaPicture;
        });
      }
    }

    _fetchMediaLibrary() async {
      File mediaPicture =
          await ImagePicker.pickImage(source: ImageSource.gallery);
      if (mediaPicture != null) {
        setState(() {
          team["teamPicture"] = mediaPicture;
        });
      }
    }

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
                        "Pick Picture From...",
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
                                _fetchCamera();
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
                                      _fetchMediaLibrary();
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

  Future<Null> _setPicture(String filePath) async {
    ByteData bytes = await rootBundle.load(filePath);
    Directory tempDir = Directory.systemTemp;
    String fileName = "$selectedPicture.png";
    File file = File("${tempDir.path}/$fileName");
    file.writeAsBytes(bytes.buffer.asUint8List(), mode: FileMode.write);

    setState(() {
      team["teamPicture"] = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Team Picture",
          style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontFamily: "Century Gothic",
              fontWeight: FontWeight.bold),
        ),
        leading: new BackButton(
          color: Color.fromRGBO(0, 150, 255, 1.0),
        ),
        actions: <Widget>[
          new GestureDetector(
            child: new Container(
              padding: EdgeInsets.only(right: 10.0),
              color: Colors.transparent,
              alignment: Alignment.center,
              child: new Text(
                "Next",
                style: TextStyle(
                  color: team["teamPicture"] != null
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              if (team["teamPicture"] != null) {
                print(team);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        new TeamOverviewPage(team: team),
                  ),
                );
              }
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Column(
              children: <Widget>[
                new Container(
                  margin: EdgeInsets.only(bottom: 20.0, top: 20.0),
                  alignment: Alignment.center,
                  child: new CircleAvatar(
                    backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
                    radius: 50.0,
                    child: new CircleAvatar(
                      backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
                      radius: 46.0,
                      backgroundImage: team["teamPicture"] != null
                          ? Image.file(team["teamPicture"]).image
                          : null,
                    ),
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(left: 20.0, right: 20.0),
                  constraints: BoxConstraints(
                    maxWidth: 350.0,
                  ),
                  height: 50.0,
                  child: new FlatButton(
                    color: Color.fromRGBO(0, 150, 255, 1.0),
                    child: new Text(
                      "Upload an Image",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontFamily: "Century Gothic",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      _mediaPicker(context);
                    },
                  ),
                ),
                new Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: new Text(
                    "or",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                new Expanded(
                  child: new Container(
                    margin:
                        EdgeInsets.only(right: 20.0, left: 20.0, bottom: 20.0),
                    constraints: BoxConstraints(
                      maxWidth: 350.0,
                    ),
                    child: new GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                      ),
                      itemCount: 38,
                      cacheExtent: 20.0,
                      itemBuilder: (BuildContext context, int index) {
                        return new GestureDetector(
                          child: new Container(
                            child: new Stack(
                              children: <Widget>[
                                new Container(
                                  color: Colors.white,
                                  child: new Image.asset(
                                    "assets/default/default$index.png",
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                new Opacity(
                                  opacity: selectedPicture == index ? 1.0 : 0.0,
                                  child: new Container(
                                    alignment: Alignment.center,
                                    color: Color.fromRGBO(255, 255, 255, 0.5),
                                    child: new Icon(
                                      Icons.check_circle,
                                      color: Color.fromRGBO(0, 150, 255, 1.0),
                                      size: 25.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            if (selectedPicture != index) {
                              selectedPicture = index;
                              print(index);
                              _setPicture(
                                  "assets/default/default$selectedPicture.png");
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      // new Container(
      //   padding: EdgeInsets.only(top: 50.0),
      //   alignment: Alignment.topCenter,
      //   child: new Stack(
      //     alignment: Alignment.bottomCenter,
      //     children: <Widget>[
      //       new GestureDetector(
      //         child: new CircleAvatar(
      //           radius: 50.0,
      //           backgroundColor: Color.fromRGBO(0, 150, 255, 1.0),
      //           child: new CircleAvatar(
      //             radius: 46.0,
      //             backgroundColor: Color.fromRGBO(50, 50, 50, 1.0),
      //             backgroundImage: team["teamPicture"] != null
      //                 ? FileImage(team["teamPicture"])
      //                 : null,
      //           ),
      //         ),
      //         onTap: () {
      //           _selectMedia(context, "Picture");
      //         },
      //       ),
      //       new GestureDetector(
      //                   child: new Container(
      //                     alignment: Alignment.center,
      //                     margin: EdgeInsets.only(left: 75.0, bottom: 10.0),
      //                     height: 25.0,
      //                     width: 25.0,
      //                     decoration: BoxDecoration(
      //                       color: Color.fromRGBO(0, 150, 255, 1.0),
      //                       borderRadius:
      //                           BorderRadius.all(Radius.circular(12.5)),
      //                     ),
      //                     child: new Icon(
      //                       Icons.add,
      //                       color: Colors.white,
      //                       size: 20.0,
      //                     ),
      //                   ),
      //                   onTap: () {
      //                     _selectMedia(context, "Picture");
      //                   },
      //                 ),
      //     ],
      //   ),
      // ),
    );
  }
}
