import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: new Opacity(
            opacity: 0.25,
            child: new Image.asset(
              "assets/background.png",
              fit: BoxFit.cover,
              height: 250.0,
            )));
  }
}
