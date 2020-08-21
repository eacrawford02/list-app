import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:listapp/utils/utils.dart';

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
  }) : this.date = date ?? DateTime.now();

  // We don't have to somehow await this method because it's called from the
  // "_initialized" future in the task list
  Future<void> loadData() async {
    final Database db = await Utils.getDatabase();
    String dateString = Utils.dateToString(date);
    List<Map<String, dynamic>> savedTask;
    try {
      savedTask = await db.query(
          "tasks",
          where: "id = ?",
          whereArgs: [id]
      );
    }
    on DatabaseException {
      savedTask = List(0);
    }
    if (savedTask.length == 0) {
      print("Task '$id' does not exist in database");
      return;
    }
    isSet = true;
    text = savedTask[0]["text"];
    isScheduled = savedTask[0]["isScheduled"] == 0 ? false : true;
    startTime = (savedTask[0]["startTimeH"] == null ||
        savedTask[0]["startTimeM"] == null) ? null :
    TimeOfDay(
        hour: savedTask[0]["startTimeH"],
        minute: savedTask[0]["startTimeM"]
    );
    endTime = (savedTask[0]["endTimeH"] == null ||
        savedTask[0]["endTimeM"] == null) ? null :
    TimeOfDay(
        hour: savedTask[0]["endTimeH"],
        minute: savedTask[0]["endTimeM"]
    );
    date = DateTime.parse(dateString.replaceAll(RegExp(r"_"), "-"));
    for (int i = 0; i < 7; i++) {
      List<Map<String, dynamic>> check;
      try {
        check = await db.query(
            "repeatDay_$i",
            where: "taskId = ?",
            whereArgs: [id]
        );
      }
      on DatabaseException {
        check = List(0);
      }
      if (check.length == 1) {
        repeatDays[i] = true;
      }
    }
  }

  // A task can't save its own data because doing so would overwrite the
  // prevDate field used in the TaskList's save method
  void saveData() async {
    final Database db = await Utils.getDatabase();
    List<Map<String, dynamic>> prevData;
    try {
      prevData = await db.query(
          "tasks",
          where: "id = ?",
          whereArgs: [id]
      );
    }
    on DatabaseException {
      prevData = List(0);
    }
    // Make sure to delete the old copy, if there is one
    if (prevData.length != 0) {
      await db.delete(
          "tasks",
          where: "id = ?",
          whereArgs: [id]
      );
    }
    await db.insert(
      "tasks",
      {
        "id" : id,
        "isSet" : 1,
        "text" : text,
        "isScheduled" : isScheduled ? 1 : 0,
        "startTimeH" : startTime != null ? startTime.hour : null,
        "startTimeM" : startTime != null ? startTime.minute : null,
        "endTimeH" : endTime != null ? endTime.hour : null,
        "endTimeM" : endTime != null ? endTime.minute : null,
        "date" : Utils.dateToString(date)
      },
    );
  }

  void unsaveData() async {
    final Database db = await Utils.getDatabase();
    // Remove task from tasks table only if task isn't set to repeat
    if (!repeatDays.contains(true)) {
      db.delete(
          "tasks",
          where: "id = ?",
          whereArgs: [id]
      );
    }
  }
}