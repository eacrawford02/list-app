import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Utils {
  static Future<Database> _database;

  static Future<Database> getDatabase() async {
    if (_database == null) {
      _database = openDatabase(
        // Set the path to the database
        join(await getDatabasesPath(), "app_database"),
        version: 1,
        // When the database is first created, create each table needed to store
        // the list's data
        onCreate: (db, version) async {
          await db.execute("CREATE TABLE taskListData(date TEXT PRIMARY KEY,"
              " isLocked INTEGER)"
          );
          await db.execute("CREATE TABLE tasks(id INTEGER PRIMARY KEY,"
              " isSet INTEGER, isDone INTEGER, text TEXT,"
              " isScheduled INTEGER, startTimeH INTEGER, startTimeM INTEGER,"
              " endTimeH INTEGER, endTimeM INTEGER, date TEXT)"
          );
          for (int i = 0; i < 7; i++) {
            // Each table here functions as an array
            // We can use the DatTime day constants to "look up" each table
            await db.execute("CREATE TABLE repeatDay_$i(taskId INTEGER)");
          }
        }
      );
    }
    return _database;
  }

  static int createTimeStamp(int hour, int minute) {
    return (hour * 100) + minute;
  }

  static String timeToString(TimeOfDay timeOfDay) {
    int hour = timeOfDay.hour;
    int minute = timeOfDay.minute;
    String mm = "$minute";
    if (minute < 10) {
      mm = "0$minute";
    }
    if (hour == 0) {
      return "12:$mm AM";
    }
    else if (hour < 12) {
      return "$hour:$mm AM";
    }
    else if (hour == 12) {
      return "12:$mm PM";
    }
    else {
      int h = hour - 12;
      return "$h:$mm PM";
    }
  }

  static String dateToString(DateTime date) {
    int year = date.year;
    int month = date.month;
    int day = date.day;
    String mm = "$month";
    String dd = "$day";
    if (month < 10) {
      mm = "0$month";
    }
    if (day < 10) {
      dd = "0$day";
    }
    return "${year}_${mm}_$dd";
  }
}