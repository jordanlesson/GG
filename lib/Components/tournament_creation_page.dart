import 'package:flutter/material.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'package:gg/UI/number_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'master_page.dart';
import 'package:flutter/cupertino.dart';
import 'tournament_rules_page.dart';
import 'package:gg/UI/banner_dialog.dart';
import 'package:gg/UI/picture_dialog.dart';

class TournamentCreationPage extends StatefulWidget {
  _TournamentCreationPage createState() => new _TournamentCreationPage();

  final Map<dynamic, dynamic> tournamentInfo;
  final String tournamentID;
  final String pageType;

  TournamentCreationPage(
      {Key key,
      @required this.pageType,
      this.tournamentInfo,
      this.tournamentID})
      : super(key: key);
}

class _TournamentCreationPage extends State<TournamentCreationPage> {
  Map<dynamic, dynamic> tournamentInfo;
  TimeOfDay tournamentTime;
  TextEditingController tournamentNameController;
  TextEditingController tournamentRulesController;
  bool updateInProgress;

  void initState() {
    super.initState();
    tournamentInfo = new Map.from(widget.tournamentInfo);
    print(tournamentInfo["tournamentDate"].runtimeType);
    if (tournamentInfo["tournamentDate"] != null && tournamentInfo["tournamentDate"].runtimeType != DateTime) {
      print("SHIT!");
      tournamentInfo["tournamentDate"] = tournamentInfo["tournamentDate"].toDate();
      }
    if (widget.pageType != "Creation") {
      tournamentTime = TimeOfDay(
          minute: tournamentInfo["tournamentDate"].minute,
          hour: tournamentInfo["tournamentDate"].hour);
    } else {
      tournamentTime = null;
    }

    updateInProgress = false;

    tournamentNameController = TextEditingController();
    tournamentNameController.text = tournamentInfo["tournamentName"];
    tournamentNameController..addListener(tournamentName);

    tournamentRulesController = TextEditingController();
    tournamentRulesController.text = tournamentInfo["tournamentRules"];
    tournamentRulesController..addListener(tournamentRules);
  }

  tournamentName() {
    setState(() {
      tournamentInfo["tournamentName"] = tournamentNameController.text;
    });
  }

  tournamentRules() {
    setState(() {
      tournamentInfo["tournamentRules"] = tournamentRulesController.text;
    });
  }

  _handleTournamentUpdate(var tournamentDate, Map<dynamic, dynamic> tournamentInfo) {
    String pictureDownloadUrl;
    String bannerDownloadUrl;
    StorageReference pictureRef = FirebaseStorage.instance
        .ref()
        .child("Tournaments/${widget.tournamentID}/picture/picture.png");
    pictureRef
        .putFile(tournamentInfo["tournamentPicture"])
        .onComplete
        .then((_) async {
      pictureDownloadUrl = await pictureRef.getDownloadURL();
    }).then((_) {
      StorageReference bannerRef = FirebaseStorage.instance
          .ref()
          .child("Tournaments/${widget.tournamentID}/banner/banner.png");
      bannerRef
          .putFile(tournamentInfo["tournamentBanner"])
          .onComplete
          .then((_) async {
        bannerDownloadUrl = await bannerRef.getDownloadURL();
      }).then((_) {
        Firestore.instance
            .document("Tournaments/${widget.tournamentID}")
            .updateData({
          "tournamentName": tournamentInfo["tournamentName"],
          "tournamentDate": tournamentDate,
          "tournamentRegion": tournamentInfo["tournamentRegion"],
          "tournamentBracketSize": tournamentInfo["tournamentBracketSize"],
          "tournamentMinTeamSize": tournamentInfo["tournamentMinTeamSize"],
          "tournamentMaxTeamSize": tournamentInfo["tournamentMaxTeamSize"],
          "tournamentRules": tournamentInfo["tournamentRules"],
          "tournamentDoubleElimination": tournamentInfo["tournamentDoubleElimination"],
          "tournamentPrivate": tournamentInfo["tournamentPrivate"],
          "tournamentPicture": pictureDownloadUrl.toString(),
          "tournamentBanner": bannerDownloadUrl.toString()
        });
      }).whenComplete(() {
        setState(() {
          updateInProgress = false;
          Navigator.of(context).pop();
        });
      });
    });
  }

  fetchDate(DateTime date) {
    String month;
    String weekday;
    String suffix;
    switch (date.month) {
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
    switch (date.weekday) {
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

    String day = date.day.toString();

    if (day.endsWith("11") || day.endsWith("12") || day.endsWith("13")) {
      suffix = "th";
    } else if (day.endsWith("1")) {
      suffix = "st";
    } else if (day.endsWith("2")) {
      suffix = "nd";
    } else if (day.endsWith("3")) {
      suffix = "rd";
    } else {
      suffix = "th";
    }

    return "$month ${date.day}$suffix, ${date.year}";
  }

  _selectMedia(BuildContext context, String media) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return media == "Picture"
            ? PictureDialog(
                picture: tournamentInfo["tournamentPicture"])
            : new BannerDialog(
                banner: tournamentInfo["tournamentBanner"]);
      },
    ).then((mediaFile) {
      if (mediaFile != null) {
        setState(() {
          if (media == "Picture") {
            tournamentInfo["tournamentPicture"] = mediaFile;
          } else {
            tournamentInfo["tournamentBanner"] = mediaFile;
          }
        });
      }
    });
  }

  Future<Null> _selectDate(BuildContext context) async {
    DateTime current = DateTime.now();
    final datePicked = await showDatePicker(
      context: context,
      initialDate: tournamentInfo["tournamentDate"] != null
          ? tournamentInfo["tournamentDate"]
          : DateTime.now(),
      firstDate: DateTime(current.year, current.month, current.day),
      lastDate: new DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (datePicked != null) {
      setState(() {
        tournamentInfo["tournamentDate"] = datePicked;
      });
    }
  }

  Future<Null> _selectTime(BuildContext context) async {
    final timePicked = await showTimePicker(
      context: context,
      initialTime: tournamentTime != null ? tournamentTime : TimeOfDay.now(),
    );
    if (timePicked != null) {
      setState(() {
        tournamentTime = timePicked;
      });
    }
  }

  Future<Null> _selectRegion(BuildContext context) async {
    String selectedRegion = tournamentInfo["tournamentRegion"];

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new Center(
          child: new Container(
            height: 375.0,
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 40.0, right: 40.0),
            constraints: BoxConstraints(maxWidth: 350.0),
            decoration: BoxDecoration(
              color: Color.fromRGBO(23, 23, 23, 1.0),
              border: Border.all(
                width: 1.0,
                color: Color.fromRGBO(0, 150, 255, 1.0),
              ),
            ),
            child: new Material(
              type: MaterialType.transparency,
              child: new ListView.builder(
                shrinkWrap: true,
                itemBuilder: (BuildContext context, int index) {
                  List<String> regions = [
                    "Regions",
                    "North America East",
                    "North America West",
                    "Europe",
                    "Asia",
                    "Oceana",
                    "Brasil",
                    "Global",
                  ];

                  return new Material(
                    type: MaterialType.transparency,
                    child: new GestureDetector(
                      child: new Container(
                        alignment: index != 0
                            ? Alignment.centerLeft
                            : Alignment.center,
                        padding: EdgeInsets.only(
                            top: 10.0,
                            bottom: 10.0,
                            left: index != 0 ? 15.0 : 0.0),
                        child: new Text(
                          regions[index],
                          style: TextStyle(
                            color: regions[index] == selectedRegion
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : index != 0
                                    ? Color.fromRGBO(170, 170, 170, 1.0)
                                    : Colors.white,
                            fontSize: 20.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(23, 23, 23, 1.0),
                          border: index == 7
                              ? Border()
                              : Border(
                                  bottom: BorderSide(
                                    width: 1.0,
                                    color: Color.fromRGBO(40, 40, 40, 1.0),
                                  ),
                                ),
                        ),
                      ),
                      onTap: () {
                        if (index != 0) {
                          setState(() {
                            selectedRegion = regions[index];
                            Navigator.of(context, rootNavigator: true)
                                .pop([selectedRegion]);
                          });
                        }
                      },
                    ),
                  );
                },
                itemCount: 8,
              ),
            ),
          ),
        );
      },
    ).then((region) {
      setState(() {
        tournamentInfo["tournamentRegion"] = selectedRegion;
      });
    });
  }

  Future<Null> _selectBracketSize(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new TournamentBracketSizeDialog(
            tournamentBracketSize: tournamentInfo["tournamentBracketSize"]);
      },
    ).then((tournamentBracketSize) {
      if (tournamentBracketSize != null) {
        setState(() {
          tournamentInfo["tournamentBracketSize"] = tournamentBracketSize;
        });
      }
    });
  }

  Future<Null> _selectTeamSize(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return TournamentTeamSizeDialog(
            tournamentMinTeamSize: tournamentInfo["tournamentMinTeamSize"],
            tournamentMaxTeamSize: tournamentInfo["tournamentMaxTeamSize"],
          );
        }).then((tournamentTeamSize) {
      if (tournamentTeamSize[0] != null && tournamentTeamSize[1] != null) {
        setState(() {
          tournamentInfo["tournamentMinTeamSize"] = tournamentTeamSize[0];
          tournamentInfo["tournamentMaxTeamSize"] = tournamentTeamSize[1];
        });
      }
    });
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          widget.pageType == "Creation" ? "Create" : "Settings",
          style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontFamily: "Century Gothic",
              fontWeight: FontWeight.bold),
        ),
        leading: new IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: updateInProgress
                ? Color.fromRGBO(170, 170, 170, 1.0)
                : Color.fromRGBO(0, 150, 255, 1.0),
          ),
          onPressed: () {
            if (updateInProgress != true) {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: <Widget>[
          new GestureDetector(
            child: new Container(
              padding: EdgeInsets.only(right: 10.0),
              alignment: Alignment.center,
              color: Colors.transparent,
              child: new Text(
                widget.pageType == "Creation" ? "Next" : "Save",
                style: TextStyle(
                  color: tournamentInfo["tournamentName"] != "" &&
                          tournamentInfo["tournamentDate"] != null &&
                          tournamentTime != null &&
                          tournamentInfo["tournamentRegion"] != "" &&
                          tournamentInfo["tournamentBracketSize"] != null &&
                          tournamentInfo["tournamentMinTeamSize"] != null &&
                          tournamentInfo["tournamentMaxTeamSize"] != null &&
                          tournamentInfo["tournamentPicture"] != null &&
                          tournamentInfo["tournamentBanner"] != null
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
              var newDate = tournamentInfo["tournamentDate"].add(Duration(
                  hours: tournamentTime.hour, minutes: tournamentTime.minute));
              if (tournamentInfo["tournamentName"] != "" &&
                  tournamentInfo["tournamentDate"] != null &&
                  tournamentTime != null &&
                  tournamentInfo["tournamentRegion"] != "" &&
                  tournamentInfo["tournamentBracketSize"] != null &&
                  tournamentInfo["tournamentMinTeamSize"] != null &&
                  tournamentInfo["tournamentMaxTeamSize"] != null &&
                  tournamentInfo["tournamentPicture"] != null &&
                  tournamentInfo["tournamentBanner"] != null) {
                if (widget.pageType == "Creation") {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          new TournamentRulesPage(
                              tournamentInfo: tournamentInfo),
                    ),
                  );
                } else {
                  setState(() {
                    updateInProgress = true;
                    _handleTournamentUpdate(newDate, tournamentInfo);
                  });
                }
              }
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Stack(
        children: <Widget>[
          new GestureDetector(
            child: new ListView(
              shrinkWrap: true,
              children: <Widget>[
                new Container(
                  height: 160.0,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(50, 50, 50, 1.0),
                    image: tournamentInfo["tournamentBanner"] != null
                        ? DecorationImage(
                            image:
                                FileImage(tournamentInfo["tournamentBanner"]),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: new Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      new Container(
                        child: new Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            new GestureDetector(
                              child: new CircleAvatar(
                                radius: 50.0,
                                backgroundColor:
                                    Color.fromRGBO(0, 150, 255, 1.0),
                                child: new CircleAvatar(
                                  radius: 46.0,
                                  backgroundColor:
                                      Color.fromRGBO(50, 50, 50, 1.0),
                                  backgroundImage: tournamentInfo[
                                              "tournamentPicture"] !=
                                          null
                                      ? FileImage(
                                          tournamentInfo["tournamentPicture"])
                                      : null,
                                ),
                              ),
                              onTap: () {
                                _selectMedia(context, "Picture");
                              },
                            ),
                            new Container(
                              margin: EdgeInsets.only(top: 2.0, bottom: 3.0),
                              child: new Text(
                                tournamentInfo["tournamentName"],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  fontFamily: "Century Gothic",
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      new GestureDetector(
                        child: new Container(
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(left: 75.0, bottom: 30.0),
                          height: 25.0,
                          width: 25.0,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(0, 150, 255, 1.0),
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.5)),
                          ),
                          child: new Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20.0,
                          ),
                        ),
                        onTap: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _selectMedia(context, "Picture");
                        },
                      ),
                      new Align(
                        alignment: Alignment.topRight,
                        child: new GestureDetector(
                          child: new Container(
                            margin: EdgeInsets.only(top: 10.0, right: 10.0),
                            width: 30.0,
                            height: 25.0,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(0, 150, 255, 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2.0)),
                            ),
                            child: new Icon(
                              Icons.brush,
                              color: Colors.white,
                              size: 20.0,
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _selectMedia(context, "Banner");
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                new Container(
                  margin: EdgeInsets.only(top: 15.0, left: 45.0),
                  alignment: Alignment.topLeft,
                  constraints: BoxConstraints(
                    maxWidth: 350.0,
                  ),
                  child: new Text(
                    "Tournament Name",
                    style: TextStyle(
                      color: Color.fromRGBO(170, 170, 170, 1.0),
                      fontSize: 16.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                new CustomTextfield(
                  controller: tournamentNameController,
                  contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 6.0),
                  margin: EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 10.0),
                  maxWidth: 350.0,
                  height: 50.0,
                  textFontSize: 17.0,
                  autocorrect: false,
                  maxLength: 30,
                  textAlign: TextAlign.center,
                  enabledBorderColor: tournamentInfo["tournamentName"] != ""
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(40, 40, 40, 1.0),
                ),
                new Container(
                  margin: EdgeInsets.only(top: 15.0, left: 45.0),
                  alignment: Alignment.topLeft,
                  constraints: BoxConstraints(
                    maxWidth: 350.0,
                  ),
                  child: new Text(
                    "Tournament Begins",
                    style: TextStyle(
                      color: Color.fromRGBO(170, 170, 170, 1.0),
                      fontSize: 16.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                new Row(
                  children: <Widget>[
                    new GestureDetector(
                      child: new Container(
                        height: 35.0,
                        alignment: Alignment.center,
                        margin: EdgeInsets.fromLTRB(40.0, 10.0, 0.0, 20.0),
                        constraints: BoxConstraints(
                          maxWidth: 175.0,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(5, 5, 10, 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(2.0)),
                          border: Border.all(
                            color: tournamentInfo["tournamentDate"] != null
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                            width: 1.0,
                          ),
                        ),
                        child: new Text(
                          tournamentInfo["tournamentDate"] != null
                              ? fetchDate(tournamentInfo["tournamentDate"])
                              : "",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontFamily: "Avenir",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                        _selectDate(context);
                      },
                    ),
                    new Container(
                        height: 35.0,
                        alignment: Alignment.center,
                        padding: EdgeInsets.only(left: 10.0, right: 10.0),
                        margin: EdgeInsets.only(bottom: 10.0),
                        constraints: BoxConstraints(maxHeight: 50.0),
                        child: new Text(
                          "at",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 17.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                    new Expanded(
                      child: new GestureDetector(
                          child: new Container(
                            height: 35.0,
                            margin: EdgeInsets.fromLTRB(0.0, 10.0, 40.0, 20.0),
                            alignment: Alignment.center,
                            constraints: BoxConstraints(
                              maxWidth: 125.0,
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(5, 5, 10, 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2.0)),
                              border: Border.all(
                                color: tournamentTime != null
                                    ? Color.fromRGBO(0, 150, 255, 1.0)
                                    : Color.fromRGBO(40, 40, 40, 1.0),
                                width: 1.0,
                              ),
                            ),
                            child: new Text(
                              tournamentTime != null
                                  ? tournamentTime.format(context)
                                  : "",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  fontFamily: "Avenir",
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _selectTime(context);
                          }),
                    ),
                  ],
                ),
                new Container(
                  margin: EdgeInsets.only(top: 15.0, left: 45.0),
                  alignment: Alignment.topLeft,
                  constraints: BoxConstraints(
                    maxWidth: 350.0,
                  ),
                  child: new Text(
                    "Region",
                    style: TextStyle(
                      color: Color.fromRGBO(170, 170, 170, 1.0),
                      fontSize: 16.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                new GestureDetector(
                  child: new Container(
                    height: 35.0,
                    margin: EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 20.0),
                    constraints: BoxConstraints(maxWidth: 350.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(5, 5, 10, 1.0),
                      border: Border.all(
                        width: 1.0,
                        color: tournamentInfo["tournamentRegion"] != ""
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    child: new Text(
                      tournamentInfo["tournamentRegion"],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    _selectRegion(context);
                  },
                ),
                new Container(
                  margin: EdgeInsets.only(top: 15.0, left: 45.0),
                  alignment: Alignment.topLeft,
                  constraints: BoxConstraints(
                    maxWidth: 350.0,
                  ),
                  child: new Text(
                    "Bracket Size",
                    style: TextStyle(
                      color: Color.fromRGBO(170, 170, 170, 1.0),
                      fontSize: 16.0,
                      fontFamily: "Century Gothic",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                new GestureDetector(
                  child: new Container(
                    height: 35.0,
                    margin: EdgeInsets.fromLTRB(40.0, 10.0, 40.0, 20.0),
                    constraints: BoxConstraints(maxWidth: 350.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(5, 5, 10, 1.0),
                      border: Border.all(
                        width: 1.0,
                        color: tournamentInfo["tournamentBracketSize"] != null
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                    child: new Text(
                      tournamentInfo["tournamentBracketSize"] != null
                          ? "${tournamentInfo["tournamentBracketSize"].toString()} Teams"
                          : "",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    _selectBracketSize(context);
                  },
                ),
                new Container(
                  constraints: BoxConstraints(
                    maxWidth: 350.0,
                  ),
                  margin: EdgeInsets.only(
                      left: 40.0, right: 40.0, top: 10.0, bottom: 20.0),
                  child: new Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        child: new Text(
                          "Min",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 16.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      new GestureDetector(
                          child: new Container(
                            height: 35.0,
                            width: 60.0,
                            margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                            alignment: Alignment.center,
                            constraints: BoxConstraints(maxWidth: 60.0),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(5, 5, 10, 1.0),
                              border: Border.all(
                                width: 1.0,
                                color:
                                    tournamentInfo["tournamentMinTeamSize"] !=
                                            null
                                        ? Color.fromRGBO(0, 150, 255, 1.0)
                                        : Color.fromRGBO(40, 40, 40, 1.0),
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2.0)),
                            ),
                            child: new Text(
                              tournamentInfo["tournamentMinTeamSize"] != null
                                  ? tournamentInfo["tournamentMinTeamSize"]
                                      .toString()
                                  : "",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontFamily: "Avenir",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _selectTeamSize(context);
                          }),
                      new Container(
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                        child: new Text(
                          "Max",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 16.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      new GestureDetector(
                        child: new Container(
                          alignment: Alignment.center,
                          height: 35.0,
                          width: 60.0,
                          constraints: BoxConstraints(maxWidth: 60.0),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(5, 5, 10, 1.0),
                            border: Border.all(
                              width: 1.0,
                              color: tournamentInfo["tournamentMaxTeamSize"] !=
                                      null
                                  ? Color.fromRGBO(0, 150, 255, 1.0)
                                  : Color.fromRGBO(40, 40, 40, 1.0),
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(2.0)),
                          ),
                          child: new Text(
                            tournamentInfo["tournamentMaxTeamSize"] != null
                                ? tournamentInfo["tournamentMaxTeamSize"]
                                    .toString()
                                : "",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontFamily: "Avenir",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _selectTeamSize(context);
                        },
                      ),
                    ],
                  ),
                ),
                widget.pageType != "Creation"
                    ? new Container(
                        constraints: BoxConstraints(maxWidth: 350.0),
                        margin: EdgeInsets.only(
                            left: 40.0, right: 40.0, bottom: 20.0),
                        child: new Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            new Expanded(
                              child: new Container(
                                child: new Text(
                                  "Private Tournament",
                                  style: TextStyle(
                                    color: Color.fromRGBO(170, 170, 170, 1.0),
                                    fontSize: 16.0,
                                    fontFamily: "Century Gothic",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            new Container(
                              alignment: Alignment.center,
                              child: new CupertinoSwitch(
                                value: tournamentInfo["tournamentPrivate"],
                                activeColor: Color.fromRGBO(0, 150, 255, 1.0),
                                onChanged: (private) {
                                  setState(() {
                                    tournamentInfo["tournamentPrivate"] =
                                        private;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : new Container(),
                // widget.pageType != "Creation"
                //     ? new Container(
                //         constraints: BoxConstraints(maxWidth: 350.0),
                //         margin: EdgeInsets.only(
                //             left: 40.0, right: 40.0, bottom: 20.0),
                //         child: new Row(
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: <Widget>[
                //             new Expanded(
                //               child: new Container(
                //                 child: new Text(
                //                   "Double Elim",
                //                   style: TextStyle(
                //                     color: Color.fromRGBO(170, 170, 170, 1.0),
                //                     fontSize: 16.0,
                //                     fontFamily: "Century Gothic",
                //                     fontWeight: FontWeight.bold,
                //                   ),
                //                 ),
                //               ),
                //             ),
                //             new Container(
                //               alignment: Alignment.center,
                //               child: new CupertinoSwitch(
                //                 value: tournamentInfo[
                //                     "tournamentDoubleElimination"],
                //                 activeColor: Color.fromRGBO(0, 150, 255, 1.0),
                //                 onChanged: (doubleElim) {
                //                   setState(() {
                //                     tournamentInfo[
                //                             "tournamentDoubleElimination"] =
                //                         doubleElim;
                //                   });
                //                 },
                //               ),
                //             ),
                //           ],
                //         ),
                //       )
                //     : new Container(),
                widget.pageType != "Creation"
                    ? new Container(
                        margin: EdgeInsets.only(top: 0.0, left: 45.0),
                        alignment: Alignment.topLeft,
                        constraints: BoxConstraints(
                          maxWidth: 350.0,
                        ),
                        child: new Text(
                          "Tournament Rules",
                          style: TextStyle(
                            color: Color.fromRGBO(170, 170, 170, 1.0),
                            fontSize: 16.0,
                            fontFamily: "Century Gothic",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : new Container(),
                widget.pageType != "Creation"
                    ? new CustomTextfield(
                        height: 140.0,
                        margin:
                            EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
                        textFontSize: 15.0,
                        contentPadding:
                            EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
                        maxWidth: 350.0,
                        maxLines: 6,
                        autocorrect: true,
                        controller: tournamentRulesController,
                        maxLength: 300,
                        enabledBorderColor:
                            tournamentInfo["tournamentRules"] != ""
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(40, 40, 40, 1.0),
                      )
                    : new Container(),
              ],
            ),
          ),
          updateInProgress
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

class TournamentBracketSizeDialog extends StatefulWidget {
  _TournamentBracketSizeDialog createState() =>
      new _TournamentBracketSizeDialog();

  final int tournamentBracketSize;

  TournamentBracketSizeDialog({Key key, @required this.tournamentBracketSize})
      : super(key: key);
}

class _TournamentBracketSizeDialog extends State<TournamentBracketSizeDialog> {
  int tournamentBracketSize;

  void initState() {
    super.initState();
    if (widget.tournamentBracketSize != null) {
      tournamentBracketSize = widget.tournamentBracketSize;
    } else {
      tournamentBracketSize = 2;
    }
  }

  Widget build(BuildContext context) {
    NumberPicker bracketSizePicker = NumberPicker.integer(
      initialValue: tournamentBracketSize,
      minValue: 2,
      maxValue: 16,
      onChanged: (bracketSize) {
        setState(() {
          tournamentBracketSize = bracketSize;
        });
      },
    );

    return new Center(
      child: new Container(
        height: 200.0,
        margin: EdgeInsets.only(left: 40.0, right: 40.0),
        constraints: BoxConstraints(
          maxWidth: 350.0,
        ),
        decoration: BoxDecoration(
          color: Color.fromRGBO(23, 23, 23, 1.0),
          border: Border.all(
            width: 1.0,
            color: Color.fromRGBO(0, 150, 255, 1.0),
          ),
        ),
        child: new Material(
          child: new Column(
            children: <Widget>[
              new Container(
                alignment: Alignment.center,
                height: 50.0,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  border: Border(
                    bottom: BorderSide(
                      width: 1.0,
                      color: Color.fromRGBO(40, 40, 40, 1.0),
                    ),
                  ),
                ),
                child: new Text(
                  "Bracket Size",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontFamily: "Century Gothic",
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              new Expanded(
                child: new Container(
                  alignment: Alignment.center,
                  color: Color.fromRGBO(23, 23, 23, 1.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      new IconButton(
                        icon: Icon(Icons.arrow_left,
                            color: tournamentBracketSize != 2
                                ? Color.fromRGBO(0, 150, 255, 1.0)
                                : Color.fromRGBO(170, 170, 170, 1.0),
                            size: 35.0),
                        onPressed: () {
                          if (tournamentBracketSize != 2) {
                            setState(() {
                              bracketSizePicker
                                  .animateInt(tournamentBracketSize - 1);
                              tournamentBracketSize = tournamentBracketSize - 1;
                            });
                          }
                        },
                      ),
                      bracketSizePicker,
                      new IconButton(
                        icon: Icon(
                          Icons.arrow_right,
                          color: tournamentBracketSize != 16
                              ? Color.fromRGBO(0, 150, 255, 1.0)
                              : Color.fromRGBO(170, 170, 170, 1.0),
                          size: 35.0,
                        ),
                        onPressed: () {
                          if (tournamentBracketSize != 16) {
                            setState(() {
                              //tournamentBracketSize = tournamentBracketSize + 1;
                              bracketSizePicker
                                  .animateInt(tournamentBracketSize + 1);
                              tournamentBracketSize = tournamentBracketSize + 1;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              new Container(
                color: Color.fromRGBO(23, 23, 23, 1.0),
                child: new Row(
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
                        setState(() {
                          Navigator.of(context, rootNavigator: true)
                              .pop(tournamentBracketSize);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TournamentTeamSizeDialog extends StatefulWidget {
  _TournamentTeamSizeDialog createState() => new _TournamentTeamSizeDialog();

  final int tournamentMinTeamSize;
  final int tournamentMaxTeamSize;

  TournamentTeamSizeDialog(
      {Key key,
      @required this.tournamentMinTeamSize,
      @required this.tournamentMaxTeamSize})
      : super(key: key);
}

class _TournamentTeamSizeDialog extends State<TournamentTeamSizeDialog> {
  int tournamentMinTeamSize;
  int tournamentMaxTeamSize;
  bool teamSizeError;

  void initState() {
    super.initState();
    if (widget.tournamentMinTeamSize != null) {
      tournamentMinTeamSize = widget.tournamentMinTeamSize;
    } else {
      tournamentMinTeamSize = 1;
    }
    if (widget.tournamentMaxTeamSize != null) {
      tournamentMaxTeamSize = widget.tournamentMaxTeamSize;
    } else {
      tournamentMaxTeamSize = 1;
    }
    teamSizeError = false;
  }

  Widget build(BuildContext context) {
    NumberPicker minTeamSizePicker = NumberPicker.integer(
      initialValue: tournamentMinTeamSize,
      minValue: 1,
      maxValue: 10,
      itemExtent: 30.0,
      onChanged: (minTeamSize) {
        setState(() {
          tournamentMinTeamSize = minTeamSize;
        });
      },
    );

    NumberPicker maxTeamSizePicker = NumberPicker.integer(
      initialValue: tournamentMaxTeamSize,
      minValue: 1,
      maxValue: 10,
      itemExtent: 30.0,
      onChanged: (maxTeamSize) {
        setState(() {
          tournamentMaxTeamSize = maxTeamSize;
        });
      },
    );

    return new Center(
      child: new Container(
        height: 275.0,
        margin: EdgeInsets.only(left: 40.0, right: 40.0),
        constraints: BoxConstraints(maxWidth: 350.0),
        decoration: BoxDecoration(
          color: Color.fromRGBO(23, 23, 23, 1.0),
          border: Border.all(
            width: 1.0,
            color: Color.fromRGBO(0, 150, 255, 1.0),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: new Column(
            children: <Widget>[
              new Container(
                alignment: Alignment.center,
                height: 50.0,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1.0,
                      color: Color.fromRGBO(40, 40, 40, 1.0),
                    ),
                  ),
                ),
                child: new Text(
                  "Team Size",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontFamily: "Century Gothic",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              new Container(
                height: 75.0,
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                constraints: BoxConstraints(maxWidth: 250.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Container(
                      child: new Text(
                        "Min:",
                        style: TextStyle(
                          color: Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 20.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    new IconButton(
                      icon: Icon(
                        Icons.arrow_left,
                        color: tournamentMinTeamSize != 1
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(170, 170, 170, 1.0),
                        size: 35.0,
                      ),
                      onPressed: () {
                        if (tournamentMinTeamSize != 1) {
                          setState(() {
                            minTeamSizePicker
                                .animateInt(tournamentMinTeamSize - 1);
                            tournamentMinTeamSize = tournamentMinTeamSize - 1;
                          });
                        }
                      },
                    ),
                    minTeamSizePicker,
                    new IconButton(
                      icon: Icon(
                        Icons.arrow_right,
                        color: tournamentMinTeamSize != 10
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(170, 170, 170, 1.0),
                        size: 35.0,
                      ),
                      onPressed: () {
                        if (tournamentMinTeamSize != 10) {
                          setState(() {
                            minTeamSizePicker
                                .animateInt(tournamentMinTeamSize + 1);
                            tournamentMinTeamSize = tournamentMinTeamSize + 1;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              new Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.only(left: 10.0, right: 10.0),
                height: 75.0,
                constraints: BoxConstraints(maxWidth: 250.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Container(
                      child: new Text(
                        "Max:",
                        style: TextStyle(
                          color: Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 20.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    new IconButton(
                      icon: Icon(
                        Icons.arrow_left,
                        color: tournamentMaxTeamSize != 1
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(170, 170, 170, 1.0),
                        size: 35.0,
                      ),
                      onPressed: () {
                        if (tournamentMaxTeamSize != 1) {
                          setState(() {
                            maxTeamSizePicker
                                .animateInt(tournamentMaxTeamSize - 1);
                            tournamentMaxTeamSize = tournamentMaxTeamSize - 1;
                          });
                        }
                      },
                    ),
                    maxTeamSizePicker,
                    new IconButton(
                      icon: Icon(
                        Icons.arrow_right,
                        color: tournamentMaxTeamSize != 10
                            ? Color.fromRGBO(0, 150, 255, 1.0)
                            : Color.fromRGBO(170, 170, 170, 1.0),
                        size: 35.0,
                      ),
                      onPressed: () {
                        if (tournamentMaxTeamSize != 10) {
                          setState(() {
                            maxTeamSizePicker
                                .animateInt(tournamentMaxTeamSize + 1);
                            tournamentMaxTeamSize = tournamentMaxTeamSize + 1;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              new Expanded(
                child: new Offstage(
                  offstage: !teamSizeError,
                  child: new Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.all(10.0),
                    child: new Text(
                      "Max team size must be greater than or equal to min",
                      style: new TextStyle(
                        color: Colors.red,
                        fontSize: 10.0,
                        fontFamily: "Avenir",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              new Container(
                alignment: Alignment.bottomRight,
                color: Color.fromRGBO(23, 23, 23, 1.0),
                child: new Row(
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
                        teamSizeError = false;
                      },
                    ),
                    new GestureDetector(
                      child: new Container(
                          color: Colors.transparent,
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
                        if (tournamentMaxTeamSize >= tournamentMinTeamSize) {
                          setState(() {
                            Navigator.of(context, rootNavigator: true).pop(
                                [tournamentMinTeamSize, tournamentMaxTeamSize]);
                            teamSizeError = false;
                          });
                        } else {
                          setState(() {
                            teamSizeError = true;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
