import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScheduler {

  static void scheduleNotification(int id, String title, String text,
      DateTime time) async {
    DateTime today = DateTime.now();
    var androidChannel = AndroidNotificationDetails(
      "0",
      "To-Do List Notifications",
      "Displays notifications for any tasks scheduled for the present day",
      importance: Importance.Max,
      priority: Priority.Max,
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