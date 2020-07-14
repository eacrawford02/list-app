import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:listapp/pages/home_page.dart';
import 'package:listapp/utils/notification_scheduler.dart';

void main() {
  runApp(ListApp());
}

class ListApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    NotificationScheduler.initializeScheduler(context);

    return MaterialApp (
      title: "List",
      home: HomePage(),
    );
  }
}