import 'package:flutter/material.dart';

class AnswerButton extends StatelessWidget {
  final answer;
  VoidCallback _onTap;

  AnswerButton(this.answer);

    @override
    Widget build(BuildContext context) {
     return  new Expanded ( //true button
          child: new Material( 
            color: answer == true ? Colors.greenAccent : Colors.redAccent,
            child: new InkWell(
              onTap: () => _onTap(),
              child: new Center(
                child: new Container(
                  child: new Text(answer == true ? "True" : "False"))
              ),
            )
          )
        );
    }
}