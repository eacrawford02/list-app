import 'package:flutter/material.dart';
import 'package:listapp/models/task_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SaveManager {

  Future<Database> _database;

  Future<void> init() async {
    // Open the database and store the reference
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
      },
    );
  }

  Future<Map<String, dynamic>> loadListData(DateTime listDate) async {
    // Get a reference to the database
    final Database db = await _database;
    // Query the table for the list data
    List<Map<String, dynamic>> maps;
    try {
      maps = await db.query("taskListData");
    }
    on DatabaseException {
      maps = List();
    }
    // Find the correct list data
    for (int i = 0; i < maps.length; i++) {
      if (maps[i]["date"] == TaskData.dateToString(listDate)) {
        Map<String, dynamic> map = Map();
        map["date"] = maps[i]["date"];
        map["isLocked"] = maps[i]["isLocked"] == 1 ? true : false;
        return map;
      }
    }
    return null;
  }

  // Note that these tasks must be sorted after the list is loaded
  Future<List<TaskData>> loadScheduledTasks(String date) async {
    // Get a reference to the database
    final Database db = await _database;
    // Get the IDs of tasks scheduled for this day
    List<Map<String, dynamic>> scheduledTasks;
    try {
      scheduledTasks = await db.query(
          "scheduledTasks_$date"
      );
    }
    on DatabaseException {
      scheduledTasks = List(0);
    }
    // Convert to TaskData objects
    // We must use a fixed length list in order to insert tasks at the correct
    // index, because insertions at an index exceeding the length of a growable
    // list are not possible
    List<TaskData> taskList = List(scheduledTasks.length);
    int numTasks = 0;
    for (int i = 0; i < scheduledTasks.length; i++) {
      print("scheduled tasks length ${scheduledTasks.length}");
      // Get the task data associated with this ID
      int id = scheduledTasks[i]["taskId"];
      int index = scheduledTasks[i]["taskIndex"];
      final List<Map<String, dynamic>> savedTask = await db.query(
          "tasks",
          where: "id = ?",
          whereArgs: [id]
      );
      print("${savedTask[0]["text"]}");
      if (savedTask.length == 0)
        throw Exception("Task '$id' does not exist in database");
      TaskData taskData = TaskData(
          id: id,
          isSet: true,
          isDone: savedTask[0]["isDone"] == 0 ? false : true,
          text: savedTask[0]["text"],
          isScheduled: savedTask[0]["isScheduled"] == 0 ? false : true,
          startTime: (savedTask[0]["startTimeH"] == null ||
              savedTask[0]["startTimeM"] == null) ? null :
            TimeOfDay(
              hour: savedTask[0]["startTimeH"],
              minute: savedTask[0]["startTimeM"]
            ),
          endTime: (savedTask[0]["endTimeH"] == null ||
              savedTask[0]["endTimeM"] == null) ? null :
            TimeOfDay(
              hour: savedTask[0]["endTimeH"],
              minute: savedTask[0]["endTimeM"]
            ),
          date: DateTime.parse(date.replaceAll(RegExp(r"_"), "-"))
      );
      for (int i = 0; i < 7; i++) {
        List<Map<String, dynamic>> check;
        try {
          check = await db.query(
              "repeatDay_$i",
              where: "taskId = ?",
              whereArgs: [taskData.id]
          );
        }
        on DatabaseException {
          check = List(0);
        }
        if (check.length == 1) {
          taskData.repeatDays[i] = true;
        }
      }
      if (index != null) {
        print("object bruh moment $index");
        taskList[index] = taskData;
      }
      else {
        // Simply add the data on to the end of this list
        taskList[numTasks] = taskData;
      }
      numTasks++;
    }
    // Simply convert the fixed-length task list to a growable one
    List<TaskData> temp = List();
    for (int i = 0; i < taskList.length; i++) {
      temp.add(taskList[i]);
    }
    return temp;
  }

  // Note that these tasks must be sorted after the list is loaded
  Future<List<TaskData>> loadRepeatTasks(String date, int dayOfWeek) async {
    // Get a reference to the database
    final Database db = await _database;
    // Get the IDs of tasks set to repeat on this day
    List<Map<String, dynamic>> repeatTasks;
    try {
      repeatTasks = await db.query(
          "repeatDay_$dayOfWeek"
      );
    }
    on DatabaseException {
      repeatTasks = List(0);
    }
    // Convert to TaskData objects
    List<TaskData> taskList = List();
    for (int i = 0; i < repeatTasks.length; i++) {
      // Get the task data associated with this ID
      int id = repeatTasks[i]["taskId"];
      final List<Map<String, dynamic>> savedTask = await db.query(
        "tasks",
        where: "id = ?",
        whereArgs: [id]
      );
      if (savedTask.length == 0)
        throw Exception("Task '$id' does not exist in database");
      TaskData taskData = TaskData(
        id: id,
        isSet: true,
        isDone: savedTask[0]["isDone"] == 0 ? false : true,
        text: savedTask[0]["text"],
        isScheduled: savedTask[0]["isScheduled"] == 0 ? false : true,
        startTime: (savedTask[0]["startTimeH"] == null ||
            savedTask[0]["startTimeM"] == null) ? null :
          TimeOfDay(
            hour: savedTask[0]["startTimeH"],
            minute: savedTask[0]["startTimeM"]
          ),
        endTime: (savedTask[0]["endTimeH"] == null ||
            savedTask[0]["endTimeM"] == null) ? null :
          TimeOfDay(
            hour: savedTask[0]["endTimeH"],
            minute: savedTask[0]["endTimeM"]
          ),
        date: DateTime.parse(date.replaceAll(RegExp(r"_"), "-"))
      );
      for (int i = 0; i < 7; i++) {
        List<Map<String, dynamic>> check;
        try {
          check = await db.query(
              "repeatDay_$i",
              where: "taskId = ?",
              whereArgs: [taskData.id]
          );
        }
        on DatabaseException {
          check = List(0);
        }
        if (check.length == 1) {
          taskData.repeatDays[i] = true;
        }
      }
      taskList.add(taskData);
    }
    return taskList;
  }

  // TODO: this
  List<TaskData> _convertData(String date, String tableQuery) {}

  Future<void> saveListData(DateTime listDate, bool locked) async {
    String date = TaskData.dateToString(listDate);
    final Database db = await _database;
    final List<Map<String, dynamic>> prevData = await db.query(
        "taskListData",
        where: "date = ?",
        whereArgs: [date]
    );
    if (prevData.length != 0) {
      await db.delete(
        "taskListData",
        where: "date = ?",
        whereArgs: [date]
      );
    }
    await db.insert(
      "taskListData",
      {
        "date" : date,
        "isLocked" : locked ? 1 : 0
      }
    );
  }

  // Note that index defaults to null
  Future<void> saveTask(TaskData taskData, {int index}) async {
    String date = TaskData.dateToString(taskData.date);
    // Check if task already exists in the task table and, if so, retain its
    // previously set date. The new data is inserted into the table, replacing
    // any previously saved data under that ID
    final Database db = await _database;
    final List<Map<String, dynamic>> prevData = await db.query(
        "tasks",
        where: "id = ?",
        whereArgs: [taskData.id]
    );
    String prevDate = prevData.length != 0 ? prevData[0]["date"] : null;
    // Make sure to delete the old copy, if there is one
    if (prevData.length != 0) {
      await db.delete(
        "tasks",
        where: "id = ?",
        whereArgs: [taskData.id]
      );
    }
    await db.insert(
      "tasks",
      {
        "id" : taskData.id,
        "isSet" : 1,
        "isDone" : taskData.isDone ? 1 : 0,
        "text" : taskData.text,
        "isScheduled" : taskData.isScheduled ? 1 : 0,
        "startTimeH" : taskData.startTime != null ? taskData.startTime.hour :
            null,
        "startTimeM" : taskData.startTime != null ? taskData.startTime.minute :
            null,
        "endTimeH" : taskData.endTime != null ? taskData.endTime.hour : null,
        "endTimeM" : taskData.endTime != null ? taskData.endTime.minute : null,
        "date" : date
      },
    );
    // Scan through each day of the week to see if this task has already been
    // set to repeat
    for (int i = 0; i < 7; i++) {
      // Check if the task being saved is set to repeat on this day
      final List<Map<String, dynamic>> check = await db.query(
          "repeatDay_$i",
          where: "taskId = ?",
          whereArgs: [taskData.id]
      );
      // Only these two conditions necessitate a change in the underlying data
      // structure
      if (check.length == 1 && taskData.repeatDays[i] == false) {
        // Delete data from table
        await db.delete(
          "repeatDay_$i",
          where: "taskId = ?",
          whereArgs: [taskData.id]
        );
      }
      else if (check.length == 0 && taskData.repeatDays[i] == true) {
        // Add data to table
        await db.insert(
          "repeatDay_$i",
          {"taskId" : taskData.id}
        );
      }
      // For all other conditions, just continue on to check the next day
    }
    // A today date indicates that this is a task only designated for today,
    // while a difference between the previously set date and the new date
    // indicates that a change has occurred and the saved data must be updated
    if (date == TaskData.dateToString(DateTime.now()) || prevDate != date) {
      if (prevDate != null) {
        // If a date change occurs and the previous date was set, then the data
        // must be removed from the previous date's table
        await db.delete(
          "scheduledTasks_$prevDate",
          where: "taskId = ?",
          whereArgs: [taskData.id]
        );
      }
      List<Map<String, dynamic>> scheduledTasks;
      try {
        scheduledTasks = await db.query(
            "scheduledTasks_$date"
        );
      }
      on DatabaseException {
        scheduledTasks = List(0);
      }
      // If the new date's (or today's date's) table doesn't exist, create it
      if (scheduledTasks.length == 0) {
        try {
          await db.execute(
              "CREATE TABLE scheduledTasks_$date("
                  "taskId INTEGER PRIMARY KEY, taskIndex INTEGER)"
          );
        } catch (e) {}
      }
      // Add to the new date's table. In the case of the task being assigned
      // today's date, its previous data in that table may need to be replaced
      // if it was set
      final List<Map<String, dynamic>> prevScheduledData = await db.query(
          "scheduledTasks_$date",
          where: "taskId = ?",
          whereArgs: [taskData.id]
      );
      // Make sure to delete the old copy, if there is one
      if (prevScheduledData.length != 0) {
        await db.delete(
            "scheduledTasks_$date",
            where: "taskId = ?",
            whereArgs: [taskData.id]
        );
      }
      await db.insert(
          "scheduledTasks_$date",
          {
            "taskId" : taskData.id,
            "taskIndex" : index
          },
      );
    }
  }

  void deleteTask(TaskData taskData) async {
    final Database db = await _database;
    // Remove task from tasks table only if task isn't set to repeat
    if (!taskData.repeatDays.contains(true)) {
      db.delete(
          "tasks",
          where: "id = ?",
          whereArgs: [taskData.id]
      );
    }
    // Remove task from appropriate scheduledTasks table
    await db.delete(
        "scheduledTasks_${TaskData.dateToString(taskData.date)}",
        where: "taskId = ?",
        whereArgs: [taskData.id]
    );
  }

  // Head and tail are inclusive
  void updateIndices(String date, List<TaskData> taskData, int head,
      int tail) async {
    final Database db = await _database;
    for (int i = 0; i <= tail - head; i++) {
      int index = head + i;
      // We can use update because this method should only ever be called on a
      // list that has either been loaded from saved storage or following a
      // change made to a task that has been saved. In both cases, the task
      // being updated will already exist in the scheduled tasks table for that
      // date
      final List<Map<String, dynamic>> prevScheduledData = await db.query(
          "scheduledTasks_$date",
          where: "taskId = ?",
          whereArgs: [taskData[i].id]
      );
      // Make sure to delete the old copy, if there is one
      if (prevScheduledData.length != 0) {
        await db.delete(
            "scheduledTasks_$date",
            where: "taskId = ?",
            whereArgs: [taskData[i].id]
        );
      }
      await db.insert(
        "scheduledTasks_$date",
        {
          "taskId" : taskData[i].id,
          "taskIndex" : index
        },
      );
    }
  }

}