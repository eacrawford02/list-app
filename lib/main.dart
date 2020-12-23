import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listapp/utils/notification_scheduler.dart';
import 'package:listapp/pages/home_page.dart';

void main() {
  runApp(ListApp());
}

class ListApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    NotificationScheduler.initializeScheduler(context);

    return MaterialApp (
      title: "List",
      theme: ThemeData(
        primaryColor: Colors.white,
        accentColor: Color.fromRGBO(235, 173, 209, 1),
        disabledColor: Colors.black38,
        textTheme: TextTheme(bodyText2: TextStyle(color: Colors.black))
      ),
      home: HomePage()
    );
  }
}