import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextfield extends StatefulWidget {
  _CustomTextfield createState() => new _CustomTextfield();

  final double height;
  final EdgeInsets margin;
  final double maxWidth;
  final String hintText;
  final double hintFontSize;
  final EdgeInsets contentPadding;
  final TextEditingController controller;
  final bool autocorrect;
  final double textFontSize;
  final int maxLength;
  final TextAlign textAlign;
  final Color enabledBorderColor;
  final TextInputType keyboardType;
  final FocusNode focusNode;
  final bool autoFocus;
  final int maxLines;
  final List<TextInputFormatter> inputFormatters;
  final TextCapitalization textCapitalization;
  final bool password;
  final FormFieldValidator<String> validator;
  final bool autovalidate;

  CustomTextfield({
    Key key,
    @required this.height,
    @required this.margin,
    @required this.contentPadding,
    @required this.textFontSize,
    @required this.maxWidth,
    this.controller,
    this.hintText,
    this.hintFontSize,
    this.autocorrect,
    this.maxLength,
    this.textAlign,
    this.enabledBorderColor,
    this.keyboardType,
    this.focusNode,
    this.autoFocus,
    this.maxLines,
    this.inputFormatters,
    this.textCapitalization,
    this.password,
    this.validator,
    this.autovalidate,
  }) : super(key: key);
}

class _CustomTextfield extends State<CustomTextfield> {
  bool obscureText;

  @override
  void initState() {
    super.initState();
    if (widget.password != true) {
      obscureText = false;
    } else {
      obscureText = true;
    }
  }

  Widget build(BuildContext context) {
    return new Container(
      height: widget.height != null ? widget.height : 60.0,
      margin: widget.margin,
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
      ),
      child: new TextFormField(
        enabled: true,
        keyboardType: widget.keyboardType != null
            ? widget.keyboardType
            : TextInputType.text,
        maxLength: widget.maxLength,
        maxLines: widget.maxLines != null ? widget.maxLines : 1,
        maxLengthEnforced: widget.maxLength == null ? false : true,
        autofocus: widget.autoFocus != null ? widget.autoFocus : false,
        focusNode: widget.focusNode != null ? widget.focusNode : null,
        obscureText: obscureText,
        textCapitalization: widget.textCapitalization != null
            ? widget.textCapitalization
            : TextCapitalization.none,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.textFontSize,
          fontFamily: "Avenir",
          fontWeight: FontWeight.bold,
        ),
        inputFormatters:
            widget.inputFormatters != null ? widget.inputFormatters : [],
        autocorrect: widget.autocorrect != null ? widget.autocorrect : false,
        controller: widget.controller != null ? widget.controller : null,
        autovalidate: widget.autovalidate != null ? widget.autovalidate : false,
        validator: widget.validator != null ? widget.validator : (text) {},       
        decoration: InputDecoration(
          suffix: widget.password == true
              ? new GestureDetector(
                  child: new Container(
                    color: Colors.transparent,
                    child: new Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  })
              : null,
          contentPadding: widget.contentPadding,
          filled: true,
          fillColor: Color.fromRGBO(5, 5, 10, 1.0),
          hintText: widget.hintText != null ? widget.hintText : "",
          hintStyle: TextStyle(
            color: Color.fromRGBO(170, 170, 170, 1.0),
            fontSize: widget.hintFontSize != null ? widget.hintFontSize : 20.0,
            fontFamily: "Century Gothic",
            fontWeight: FontWeight.bold,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
            borderSide: BorderSide(
              color: widget.enabledBorderColor != null
                  ? widget.enabledBorderColor
                  : Color.fromRGBO(40, 40, 40, 1.0),
              width: 1.0,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
            borderSide: BorderSide(
              color: Color.fromRGBO(40, 40, 40, 1.0),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
            borderSide: BorderSide(
              color: Color.fromRGBO(0, 150, 255, 1.0),
              width: 1.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
            borderSide: BorderSide(
              color: Color.fromRGBO(0, 150, 255, 1.0),
              // Color.fromRGBO(78, 105, 204, 1.0),
              width: 1.0,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
            borderSide: BorderSide(
              color: Color.fromRGBO(0, 150, 255, 1.0),
              // Color.fromRGBO(78, 105, 204, 1.0),
              width: 1.0,
            ),
          ),
           errorStyle: TextStyle(
             color: Colors.red,
             fontSize: 10.0,
             fontFamily: "Avenir",
             fontWeight: FontWeight.bold
           ),
          helperStyle: TextStyle(
            color: Color.fromRGBO(170, 170, 170, 1.0),
            fontSize: 10.0,
            fontFamily: "Avenir",
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }
}
