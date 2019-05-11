import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:gg/UI/picture_dialog.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'package:gg/Components/team_picture_page.dart';

class TeamNamePage extends StatefulWidget {
  final List team;

  TeamNamePage({Key key, @required this.team}) : super(key: key);

  _TeamNamePage createState() => _TeamNamePage();
}

class _TeamNamePage extends State<TeamNamePage> {
  Map<String, dynamic> team;

  TextEditingController teamNameController;

  void initState() {
    super.initState();
    team = Map.from({
      "teamName": "",
      "teamUsers": widget.team,
      "teamPicture": null,
    });

    teamNameController = TextEditingController()
      ..addListener(() {
        setState(() {
          team["teamName"] = teamNameController.text;
        });
      });
  }

  textFieldFocus() {
    if (teamNameController.text.isNotEmpty) {
      return Color.fromRGBO(0, 150, 255, 1.0);
    }
    return Color.fromRGBO(40, 40, 40, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Team Name",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
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
                  color: team["teamName"] != ""
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              if (team["teamName"] != "") {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        new TeamPicturePage(team: team),
                  ),
                );
              }
            },
          ),
        ],
        elevation: 0.0,
      ),
      body: new Container(
        child: new Column(
          children: <Widget>[
            new CustomTextfield(
              height: 50.0,
              margin: EdgeInsets.only(left: 40.0, right: 40.0, top: 25.0),
              textFontSize: 20.0,
              contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
              maxWidth: 350.0,
              maxLines: 1,
              autoFocus: true,
              controller: teamNameController,
              maxLength: 15,
              enabledBorderColor: textFieldFocus(),
              hintText: "Team Name",
              hintFontSize: 20.0,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
