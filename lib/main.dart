import 'package:flutter/material.dart';
import 'package:listapp/pages/home_page.dart';
import 'package:listapp/utils/notification_scheduler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(ListApp());
}

class ListApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);
    NotificationScheduler.initializeScheduler(context);

    return MaterialApp (
      title: "List",
      home: HomePage(),
    );
  }
}