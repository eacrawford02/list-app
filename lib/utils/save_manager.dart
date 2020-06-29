import 'package:flutter/material.dart';
import 'package:listapp/models/task_data.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SaveManager {

  SaveManager _instance;
  Future<Database> _database;

  _SaveManager() => _init();

  void _init() async {
    // Open the database and store the reference
    _database = openDatabase(
      // Set the path to the database
      join(await getDatabasesPath(), "app_database"),
      // When the database is first created, create each table needed to store
      // the list's data
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE taskListData(date STRING PRIMARY KEY,"
            " timedHead INTEGER, timedTail INTEGER, numTasks INTEGER,"
            " numCompletedTasks INTEGER)"
        );
        await db.execute("CREATE TABLE tasks(id INTEGER PRIMARY KEY,"
            " index INTEGER, isSet INTEGER, isDone INTEGER, text TEXT,"
            " isScheduled INTEGER, startTimeH INTEGER, startTimeM INTEGER,"
            " endTimeH INTEGER, endTimeM INTEGER)"
        );
        for (int i = 0; i <= 7; i++) {
          // Each table here functions as an array
          // We can use the DatTime day constants to "look up" each table
          await db.execute("CREATE TABLE repeatDay_$i(taskId INTEGER)");
        }
      },
    );
  }

  SaveManager getManager() {
    if (_instance == null) {
      _instance = _SaveManager();
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
  Future<List<TaskData>> loadTasks(String date) async {
    
  }

  void saveTask(String date, int index, TaskData taskData) {

  }

}