import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:listapp/pages/home_page.dart';

void main() {
  runApp(ListApp());
}

class ListApp extends StatelessWidget {

  void init(BuildContext context) async {
    // Initialize local notifications
    FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
    var initSettingsAndroid = AndroidInitializationSettings("ic_launcher");
    var initSettingsIOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(
        initSettingsAndroid,
        initSettingsIOS
    );
    await notificationsPlugin.initialize(
        initSettings,
        onSelectNotification: (String payload) async {
          await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return MaterialApp(
                    title: "List",
                    home: HomePage(notificationTaskId: payload)
                );
              })
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    init(context);

    return MaterialApp (
      title: "List",
      home: HomePage(),
    );
  }
}