import 'package:flutter/material.dart';
import 'package:flutter_gram/Pages/home.dart';

void main() {
  //Firestore.instance.settings();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        accentColor: Colors.teal,
      ),
      title: 'FlutterGram',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
