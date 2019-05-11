import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class BannerDialog extends StatefulWidget {
  _BannerDialog createState() => new _BannerDialog();

  final File banner;

  BannerDialog({Key key, @required this.banner})
      : super(key: key);
}

class _BannerDialog extends State<BannerDialog> {
  File tournamentBanner;
  int selectedBanner;

  void initState() {
    super.initState();
    tournamentBanner = widget.banner;
  }

  Future<Null> _mediaPicker(BuildContext context) async {
    _fetchCamera() async {
      File mediaBanner =
          await ImagePicker.pickImage(source: ImageSource.camera);
      if (mediaBanner != null) {
        setState(() {
          tournamentBanner = mediaBanner;
        });
      }
    }

    _fetchMediaLibrary() async {
      File mediaBanner =
          await ImagePicker.pickImage(source: ImageSource.gallery);
      if (mediaBanner != null) {
        setState(() {
          tournamentBanner = mediaBanner;
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
                        "Pick Banner From...",
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
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
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

  Future<Null> _setBanner(String filePath) async {
    ByteData bytes = await rootBundle.load(filePath);
    Directory tempDir = Directory.systemTemp;
    String fileName = "$selectedBanner.png";
    File file = File("${tempDir.path}/$fileName");
    file.writeAsBytes(bytes.buffer.asUint8List(), mode: FileMode.write);

    setState(() {
      tournamentBanner = file;
    });
  }

  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        height: 460.0,
        margin: EdgeInsets.only(left: 40.0, right: 40.0),
        constraints: BoxConstraints(
          maxWidth: 350.0,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.fromRGBO(23, 23, 23, 1.0),
          border:
              Border.all(width: 1.0, color: Color.fromRGBO(0, 150, 255, 1.0)),
        ),
        child: new Material(
          type: MaterialType.transparency,
          child: new Container(
            alignment: Alignment.centerLeft,
            child: new Column(
              children: <Widget>[
                new Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(50, 50, 50, 1.0),
                    image: tournamentBanner != null
                        ? DecorationImage(
                            image: FileImage(tournamentBanner),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  height: 120.0,
                  margin: EdgeInsets.only(bottom: 20.0, top: 20.0),
                  alignment: Alignment.center,
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
                      "Upload a Banner",
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
                      itemCount: 9,
                      cacheExtent: 20.0,
                      itemBuilder: (BuildContext context, int index) {
                        return new GestureDetector(
                            child: new Container(
                              child: new Stack(
                                overflow: Overflow.clip,
                                children: <Widget>[
                                  new Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        image: DecorationImage(
                                            image: Image.asset(
                                                    "assets/theme/theme$index.png")
                                                .image,
                                            fit: BoxFit.fill)),
                                  ),
                                  new Opacity(
                                    opacity:
                                        selectedBanner == index ? 1.0 : 0.0,
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
                              setState(() {
                                if (selectedBanner != index) {
                                  selectedBanner = index;
                                  _setBanner(
                                      "assets/theme/theme$selectedBanner.png");
                                }
                              });
                            });
                      },
                    ),
                  ),
                ),
                new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    new GestureDetector(
                      child: new Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                          margin: EdgeInsets.only(bottom: 10.0, right: 5.0),
                          child: new Text(
                            "CANCEL",
                            style: TextStyle(
                              color: Color.fromRGBO(0, 150, 255, 1.0),
                              fontSize: 15.0,
                              fontFamily: "Avenir Next",
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                      },
                    ),
                    new GestureDetector(
                      child: new Container(
                          color: Colors.transparent,
                          alignment: Alignment.center,
                          padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                          margin: EdgeInsets.only(bottom: 10.0, right: 20.0),
                          child: new Text(
                            "OK",
                            style: TextStyle(
                              color: Color.fromRGBO(0, 150, 255, 1.0),
                              fontSize: 15.0,
                              fontFamily: "Avenir Next",
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                      onTap: () {
                        Navigator.of(context, rootNavigator: true)
                            .pop(tournamentBanner);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}