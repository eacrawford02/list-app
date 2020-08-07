import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ListApp());
}

class ListApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp (
      title: "List"
    );
  }
}