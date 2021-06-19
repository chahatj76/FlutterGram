import 'package:flutter/material.dart';

AppBar header(context,
    {isAppTitle = false, String titleText, bool removeBackButton = true}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton,
    title: Text(
      isAppTitle ? 'FlutterGram' : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? 'Signatra' : '',
        fontSize: isAppTitle ? 50 : 22,
      ),
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
