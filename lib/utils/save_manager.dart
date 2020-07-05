import 'package:flutter/material.dart';
import 'package:listapp/models/task_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SaveManager {

  static SaveManager _instance;
  Future<Database> _database;

  SaveManager._();

  Future<void> _init() async {
    // Open the database and store the reference
    _database = openDatabase(
      // Set the path to the database
      join(await getDatabasesPath(), "app_database"),
      version: 1,
      // When the database is first created, create each table needed to store
      // the list's data
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE taskListData(date TEXT PRIMARY KEY,"
            " timedHead INTEGER, timedTail INTEGER, numTasks INTEGER,"
            " numCompletedTasks INTEGER)"
        );
        await db.execute("CREATE TABLE tasks(id INTEGER PRIMARY KEY,"
            " isSet INTEGER, isDone INTEGER, text TEXT,"
            " isScheduled INTEGER, startTimeH INTEGER, startTimeM INTEGER,"
            " endTimeH INTEGER, endTimeM INTEGER, date TEXT)"
        );
        for (int i = 1; i <= 7; i++) {
          // Each table here functions as an array
          // We can use the DatTime day constants to "look up" each table
          await db.execute("CREATE TABLE repeatDay_$i(taskId INTEGER)");
        }
      },
    );
  }

  static Future<SaveManager> getManager() async {
    if (_instance == null) {
      _instance = SaveManager._();
      await _instance._init();
      return _instance;
    }
    else {
      return _instance;
    }
  }

  Future<Map<String, dynamic>> loadListData(String date) async {
    // Get a reference to the database
    final Database db = await _database;

    // Query the table for the list data
    final List<Map<String, dynamic>> maps = await db.query("taskListData");
    // Find the correct list data
    for (int i = 0; i < maps.length; i++) {
      if (maps[i]["date"] == date) {
        return maps[i];
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
    List<TaskData> taskList = List();
    for (int i = 0; i < scheduledTasks.length; i++) {
      // Get the task data associated with this ID
      int id = scheduledTasks[i]["taskId"];
      final List<Map<String, dynamic>> savedTask = await db.query(
          "tasks",
          where: "id = ?",
          whereArgs: [id]
      );
      if (savedTask.length == 0)
        throw Exception("Task '$id' does not exist in database");
      TaskData taskData = TaskData(
          id: null,
          isSet: true,
          isDone: savedTask[0]["isDone"] == 0 ? false : true,
          text: savedTask[0]["text"],
          isScheduled: savedTask[0]["isScheduled"] == 0 ? false : true,
          startTime: TimeOfDay(
              hour: savedTask[0]["startTimeH"],
              minute: savedTask[0]["startTimeM"]
          ),
          endTime: TimeOfDay(
              hour: savedTask[0]["endTimeH"],
              minute: savedTask[0]["endTimeM"]
          ),
          date: DateTime.parse(date)
      );
      for (int i = 1; i <= 7; i++) {
        final List<Map<String, dynamic>> check = await db.query(
            "repeatDay_$i",
            where: "taskId = ?",
            whereArgs: [taskData.id]
        );
        if (check.length == 1) {
          taskData.repeatDays[i] = true;
        }
      }
      if (savedTask[0]["index"] != null) {
        taskList.insert(savedTask[0]["index"], taskData);
      }
      else {
        taskList.add(taskData);
      }
    }
    return taskList;
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
        id: null,
        isSet: true,
        isDone: savedTask[0]["isDone"] == 0 ? false : true,
        text: savedTask[0]["text"],
        isScheduled: savedTask[0]["isScheduled"] == 0 ? false : true,
        startTime: TimeOfDay(
            hour: savedTask[0]["startTimeH"],
            minute: savedTask[0]["startTimeM"]
        ),
        endTime: TimeOfDay(
          hour: savedTask[0]["endTimeH"],
          minute: savedTask[0]["endTimeM"]
        ),
        date: DateTime.parse(date)
      );
      for (int i = 1; i <= 7; i++) {
        final List<Map<String, dynamic>> check = await db.query(
            "repeatDay_$i",
            where: "taskId = ?",
            whereArgs: [taskData.id]
        );
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

  // Note that index defaults to null
  void saveTask(TaskData taskData, {int index}) async {
    String date = taskData.date != null ? TaskData.dateToString(taskData.date)
        : null;
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
    await db.insert(
      "tasks",
      {
        "id" : taskData.id,
        "isSet" : true,
        "isDone" : taskData.isDone,
        "text" : taskData.text,
        "isScheduled" : taskData.isScheduled,
        "startTimeH" : taskData.startTime.hour,
        "startTimeM" : taskData.startTime.minute,
        "endTimeH" : taskData.endTime.hour,
        "endTimeM" : taskData.endTime.minute,
        "date" : date
      },
      conflictAlgorithm: ConflictAlgorithm.replace
    );
    // Scan through each day of the week to see if this task has already been
    // set to repeat
    for (int i = 1; i <= 7; i++) {
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
    // A null date indicates that this is a task only designated for today,
    // while a difference between the previously set date and the new date
    // indicates that a change has occurred and the saved data must be updated
    if (date == null || prevDate != date) {
      if (prevDate != null) {
        // If a date change occurs and the previous date was set, then the data
        // must be removed from the previous date's table
        await db.delete(
          "scheduledTasks_$prevDate",
          where: "taskId = ?",
          whereArgs: [taskData.id]
        );
      }
      String dateKey;
      if (date == null) {
        // If the task has an unset date, then save to today's task table
        dateKey = TaskData.dateToString(DateTime.now());
      }
      else {
        dateKey = date;
      }
      List<Map<String, dynamic>> scheduledTasks;
      try {
        scheduledTasks = await db.query(
            "scheduledTasks_$dateKey"
        );
      }
      on DatabaseException {
        scheduledTasks = List(0);
      }
      // If the new date's (or today's date's) table doesn't exist, create it
      if (scheduledTasks.length == 0) {
        await db.execute(
            "CREATE TABLE scheduledTasks_$dateKey("
                "taskId INTEGER PRIMARY KEY, index INTEGER)"
        );
      }
      // Add to the new date's table. In the case of the task being assigned
      // today's date, its previous data in that table may need to be replaced
      // if it was set
      await db.insert(
          "scheduledTasks_$dateKey",
          {
            "taskId" : taskData.id,
            "index" : index
          },
          conflictAlgorithm: ConflictAlgorithm.replace
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
    String date;
    if (taskData.date != null) {
      date = TaskData.dateToString(taskData.date);
    }
    else {
      date = TaskData.dateToString(DateTime.now());
    }
    await db.delete(
        "scheduledTasks_$date",
        where: "taskId = ?",
        whereArgs: [taskData.id]
    );
  }

  // Head and tail are inclusive
  void updateIndices(String date, List<TaskData> taskData, int head,
      int tail) async {
    final Database db = await _database;
    final Batch batch = db.batch();
    for (int i = 0; i <= tail - head; i++) {
      int index = head + i;
      // We use insert so that this method can be used on a task list loaded for
      // the first time, whose sorting and indices have not been set
      batch.insert(
        "scheduledTasks_$date",
        {
          "taskId" : taskData[i].id,
          "index" : index
        },
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    batch.commit();
  }

}