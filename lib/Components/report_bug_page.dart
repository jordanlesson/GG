import 'package:flutter/material.dart';
import 'package:gg/UI/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gg/globals.dart' as globals;

class ReportBugPage extends StatefulWidget {
  _ReportBugPage createState() => new _ReportBugPage();
}

class _ReportBugPage extends State<ReportBugPage> {

  TextEditingController bugTextController;

  void initState() { 
    super.initState();
    bugTextController = TextEditingController()..addListener(bug);
  }

  bug() {
    setState(() {
          
        });
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "Report a Bug",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold
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
                "Report",
                style: TextStyle(
                  color: bugTextController.text.isNotEmpty
                      ? Color.fromRGBO(0, 150, 255, 1.0)
                      : Color.fromRGBO(170, 170, 170, 1.0),
                  fontSize: 20.0,
                  fontFamily: "Century Gothic",
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              if (bugTextController.text.isNotEmpty) {
                Navigator.of(context).pop();
                Firestore.instance.collection("Bugs").add({
                  "bugUser": globals.currentUser,
                  "bugBody": bugTextController.text.trim()
                });
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
            height: 140.0,
            margin: EdgeInsets.only(left: 40.0, right: 40.0, top: 50.0),
            textFontSize: 15.0,
            contentPadding: EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 5.0),
            maxWidth: 350.0,
            maxLines: 6,
            autocorrect: true,
            autoFocus: true,
            controller: bugTextController,
            maxLength: 300,
            enabledBorderColor: bugTextController.text.isNotEmpty ? Color.fromRGBO(0, 150, 255, 1.0) : Color.fromRGBO(40, 40, 40, 1.0),
          ),
          new Container(
            margin: EdgeInsets.only(left: 40.0, right: 40.0, top: 25.0),
            constraints: BoxConstraints(maxWidth: 350.0),
            alignment: Alignment.center,
            child: new Text(
              "Please report any bugs you encounter in order to make your experience on GG better, thank you",
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
        )
      ),
    );
  }

}