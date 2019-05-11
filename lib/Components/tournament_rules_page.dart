import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'dart:io';
import 'package:gg/Components/tournament_overview_page.dart';

class TournamentRulesPage extends StatefulWidget {
  _TournamentRulesPage createState() => new _TournamentRulesPage();

  final Map<dynamic, dynamic> tournamentInfo;

  TournamentRulesPage(
      {Key key,
      @required this.tournamentInfo,
      })
      : super(key: key);
}

class _TournamentRulesPage extends State<TournamentRulesPage> {
  String tournamentRules;
  bool privateTournament;
  bool doubleElimination;
  bool formFilled;
  final tournamentRulesController = new TextEditingController();
  Map<dynamic, dynamic> tournamentInfo;

  @override
  void initState() {
    super.initState();
    tournamentInfo = Map.from(widget.tournamentInfo);
    privateTournament = false;
    doubleElimination = false;
    formFilled = false;
    tournamentRulesController.addListener(rules);
  }

  rules() {
    setState(() {
      tournamentInfo["tournamentRules"] = tournamentRulesController.text;
      if (tournamentRules == "") {
        formFilled = false;
      } else {
        formFilled = true;
      }
    });
  }

  Color textFieldFocus() {
    if (tournamentInfo["tournamentRules"] != "") {
      return Color.fromRGBO(0, 150, 255, 1.0);
    } else {
      return Color.fromRGBO(40, 40, 40, 1.0);
    }
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      resizeToAvoidBottomPadding: false,
      appBar: new AppBar(
        leading: new BackButton(
          color: Color.fromRGBO(0, 150, 255, 1.0),
        ),
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "More",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          new GestureDetector(
              child: new Container(
                padding: EdgeInsets.only(right: 10.0),
                alignment: Alignment.center,
                child: new Text(
                  "Done",
                  style: TextStyle(
                    color: formFilled
                        ? Color.fromRGBO(0, 150, 255, 1.0)
                        : Color.fromRGBO(170, 170, 170, 1.0),
                    fontSize: 20.0,
                    fontFamily: "Century Gothic",
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                if (formFilled) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) =>
                          new TournamentOverviewPage(
                            tournamentInfo: tournamentInfo,
                          ),
                    ),
                  );
                }
              }),
        ],
        elevation: 0.0,
      ),
      body: new Column(
        children: <Widget>[
          new Container(
            height: 60.0,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1.0,
                  color: Color.fromRGBO(40, 40, 40, 1.0),
                ),
              ),
            ),
            child: new Container(
              margin: EdgeInsets.only(left: 40.0, right: 40.0),
              constraints: BoxConstraints(maxWidth: 350.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  new Expanded(
                    child: new Container(
                      child: new Text(
                        "Private Tournament",
                        style: TextStyle(
                          color: Color.fromRGBO(170, 170, 170, 1.0),
                          fontSize: 18.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  new Container(
                    child: new CupertinoSwitch(
                      value: tournamentInfo["tournamentPrivate"],
                      activeColor: Color.fromRGBO(0, 150, 255, 1.0),
                      onChanged: (value) {
                        setState(() {
                          tournamentInfo["tournamentPrivate"] = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          new CustomTextfield(
            height: 140.0,
            margin: EdgeInsets.only(left: 40.0, right: 40.0, top: 25.0),
            textFontSize: 15.0,
            contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
            maxWidth: 350.0,
            maxLines: 6,
            autocorrect: true,
            autoFocus: true,
            controller: tournamentRulesController,
            maxLength: 300,
            enabledBorderColor: textFieldFocus(),
          ),
          new Container(
            margin: EdgeInsets.only(left: 40.0, right: 40.0, top: 10.0),
            constraints: BoxConstraints(maxWidth: 350.0),
            alignment: Alignment.center,
            child: new Text(
              "Set any rules or guidelines that the players of the tournament must follow",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromRGBO(170, 170, 170, 1.0),
                fontSize: 15.0,
                fontFamily: "Avenir",
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
