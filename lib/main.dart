import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listapp/pages/home_page.dart';

void main() {
  runApp(ListApp());
}

class ListApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MaterialApp (
      title: "List",
      home: HomePage()
    );
  }
}