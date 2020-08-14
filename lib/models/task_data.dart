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
    DateTime date
  }) : this.date = date ?? DateTime.now() {
    // TODO: load saved data
  }

  void saveData() {
    // TODO: implement
  }
}