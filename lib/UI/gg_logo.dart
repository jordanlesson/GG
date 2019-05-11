import "package:flutter/material.dart";

class GGLogo extends StatelessWidget {
  Widget build(BuildContext context) {
    return new Container(
        padding: EdgeInsets.fromLTRB(0.0, 125.0, 0.0, 0.0),
        child: new Center(
            child: new Image.asset(
          "assets/gglogo.png",
          width: 200.0,
          height: 56.0,
        )));
  }
}
