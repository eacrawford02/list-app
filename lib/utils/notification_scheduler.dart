import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:listapp/pages/home_page.dart';

class NotificationScheduler {

  static void initializeScheduler(BuildContext context) async {
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

  static void scheduleNotification(int id, String title, String text,
      DateTime time) async {
    DateTime today = DateTime.now();
    var androidChannel = AndroidNotificationDetails(
      "0",
      "To-Do List Notifications",
      "Displays notifications for any tasks scheduled for the present day",
      importance: Importance.Max,
      priority: Priority.Max,
      groupKey: "1" // This shit doesn't work
    );
    var iosChannel = IOSNotificationDetails();
    var platformChannels = NotificationDetails(androidChannel, iosChannel);
    await FlutterLocalNotificationsPlugin().schedule(
        (id - 1) ~/ 1000, // Plugin only accepts ints of 2^31 - 1
        "$title",
        "$text",
        time,
        platformChannels,
        payload: "$id",
        androidAllowWhileIdle: true
    );
  }

  static void cancelNotification(int id) async {
    await FlutterLocalNotificationsPlugin().cancel((id - 1) ~/ 1000);
  }

  static void cancelAllNotifications() async {
    await FlutterLocalNotificationsPlugin().cancelAll();
  }

}