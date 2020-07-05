import 'package:flutter/material.dart';

class TaskData {

  final int id;
  bool isSet;
  bool isDone;
  String text;
  bool isScheduled;
  TimeOfDay startTime;
  TimeOfDay endTime;
  List<bool> repeatDays = List.filled(7, false);
  DateTime date;

  TaskData({
    @required this.id,
    this.isSet : false,
    this.isDone : false,
    this.text : "Edit Task",
    this.isScheduled : false,
    this.startTime,
    this.endTime,
    this.date
  });

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