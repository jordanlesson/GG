import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class UserAgreementPage extends StatefulWidget {
  UserAgreementPage({Key key}) : super(key: key);

  _UserAgreementPage createState() => _UserAgreementPage();
}

class _UserAgreementPage extends State<UserAgreementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(23, 23, 23, 1.0),
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(40, 40, 40, 1.0),
        title: new Text(
          "User Agreement",
          style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontFamily: "Century Gothic",
              fontWeight: FontWeight.bold),
        ),
        leading: new BackButton(
          color: Color.fromRGBO(0, 122, 255, 1.0),
        ),
        elevation: 0.0,
      ),
      body: new Container(
        child: new Scrollbar(
          child: new ListView(
            padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
            children: <Widget>[
              new Padding(
                padding: EdgeInsets.only(bottom: 20.0),
              child: new Text(
                'Last updated: (April 6th, 2019)\n\nPlease read this End-User License Agreement ("Agreement") carefully before clicking the "I Agree" button, downloading or using GG ("Application").\n\nBy clicking the \"I Agree\" button, downloading or using the Application, you are agreeing to be bound by the terms and conditions of this Agreement.\nIf you do not agree to the terms of this Agreement, do not click on the \"I Agree\" button and do not download or use the Application.\n\nLicense\n\nGG grants you a revocable, non-exclusive, non-transferable, limited license to download, install and use the Application solely for your personal, non-commercial purposes strictly in accordance with the terms of this Agreement.\n\nRestrictions\n\nYou agree not to, and you will not permit others to:\na) license, sell, rent, lease, assign, distribute, transmit, host, outsource, disclose or otherwise commercially exploit the Application or make the Application available to any third party.\n\nModifications to Application\n\nGG reserves the right to modify, suspend or discontinue, temporarily or permanently, the Application or any service to which it connects, with or without notice and without liability to you.\nTerm and Termination\n\nThis Agreement shall remain in effect until terminated by you or GG.\n\nGG may, in its sole discretion, at any time and for any or no reason, suspend or terminate this Agreement with or without prior notice.\n\nThis Agreement will terminate immediately, without prior notice from GG, in the event that you fail to comply with any provision of this Agreement. You may also terminate this Agreement by deleting the Application and all copies thereof from your mobile device or from your desktop.\n\nUpon termination of this Agreement, you shall cease all use of the Application and delete all copies of the Application from your mobile device or from your desktop.\n\nSeverability\n\nIf any provision of this Agreement is held to be unenforceable or invalid, such provision will be changed and interpreted to accomplish the objectives of such provision to the greatest extent possible under applicable law and the remaining provisions will continue in full force and effect.\n\nAmendments to this Agreement\n\nGG reserves the right, at its sole discretion, to modify or replace this Agreement at any time. If a revision is material we will provide at least 30 days\' notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.\n\nContact Information\n\nIf you have any questions about this Agreement, please contact us.',
                style: TextStyle(
                  color: Color.fromRGBO(170, 170, 170, 1.0),
                  fontFamily: "Avenir",
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ),
              new GestureDetector(
                child: new Container(
                  height: 60.0,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Color.fromRGBO(0, 122, 255, 1.0),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(2.0),
                        topRight: Radius.circular(2.0),
                      ),
                  ),
                      child: new Text(
                        "I Agree",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontFamily: "Century Gothic",
                          fontWeight: FontWeight.bold
                        ),
                      )
                ),
                onTap: () {
                  Navigator.of(context).pop(true);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
