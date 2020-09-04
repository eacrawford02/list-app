import 'package:flutter/material.dart';
import 'package:listapp/models/task_list.dart';
import 'package:listapp/widgets/list_item.dart';
import 'package:sqflite/sqflite.dart';
import 'package:listapp/utils/utils.dart';
import 'package:listapp/models/task_data.dart';

class TaskListData {
  final DateTime _listDate;
  bool isLocked = false; // TODO: set to true

  TaskListData(this._listDate);

  Future<void> loadListData() async {
    // Get a reference to the database
    final Database db = await Utils.getDatabase();
    // Query the table for the list data
    List<Map<String, dynamic>> maps;
    try {
      maps = await db.query("taskListData"); // TODO: use where argument
    }
    on DatabaseException {
      maps = List(0);
    }
    // Find the correct list data
    for (int i = 0; i < maps.length; i++) {
      if (maps[i]["date"] == Utils.dateToString(_listDate)) {
        isLocked = maps[i]["isLocked"] == 1 ? true : false;
      }
    }
  }

  // Returns a list of unsorted TaskData objects for the current date
  // Note that indices will need to be updated after calling this method
  Future<List<TaskListItem>> loadTasks() async {
    List<TaskListItem> taskList;
    List<Map<String, dynamic>> scheduledTaskTable =
        await _loadTaskTable("scheduledTasks_${Utils.dateToString(_listDate)}");
    List<Map<String, dynamic>> repeatTaskTable =
        await _loadTaskTable("repeatDay_${_listDate.weekday - 1}");
    List<TaskListItem> repeatTasks = List();
    // Sort scheduled tasks based on index
    List<TaskListItem> temp = List(scheduledTaskTable.length);
    int nonIndexedTail = 0;
    for (int i = 0; i < scheduledTaskTable.length; i++) {
      int id = scheduledTaskTable[i]["taskId"];
      int index = scheduledTaskTable[i]["taskIndex"];
      bool isDeleted = scheduledTaskTable[i]["isDeleted"] == 1 ? true : false;
      bool isDone = scheduledTaskTable[i]["isDone"] == 1 ? true : false;
      // Load TaskListItem objects
      TaskListItem item = TaskListItem(
        data: TaskData(id: id, date: _listDate, isDone: isDone),
        listItemData: ListItemData(),
        isDeleted: isDeleted
      );
      await item.data.loadData();
      if (index != null && temp[index] == null) {
        temp[index] = item;
      }
      else if (index != null && temp[index] != null) {
        // Scan the list for an empty element and assign the "blocking" task to
        // that element
        int emptyIndex = nonIndexedTail;
        for (int n = 0; n < temp.length; n++) {
          if (temp[n] == null) {
            emptyIndex = n;
          }
        }
        temp[emptyIndex] = temp[index];
        temp[index] = item;
      }
      else {
        // Simply add the item on to the end of this list
        temp[nonIndexedTail] = item;
      }
      nonIndexedTail++;
    }
    // Load repeat TaskListItem objects
    for (int i = 0; i < repeatTaskTable.length; i++) {
      int id = repeatTaskTable[i]["taskId"];
      TaskListItem item = TaskListItem(
        data: TaskData(id: id, date: _listDate),
        listItemData: ListItemData()
      );
      await item.data.loadData(); // await to prevent rewrite of isDone
      item.data.isDone = false;
      repeatTasks.add(item);
    }
    // Copy sorted tasks over to final, returned list (growable)
    taskList = List.of(temp, growable: true);
    // We must check each repeating task in the list of scheduled tasks
    // against the list of repeating tasks in order to account for tasks that
    // have been set to no longer repeat on this day of the week. These tasks
    // must then be removed from the scheduled tasks list
    for (int i = 0; i < taskList.length; i++) {
      // Perform check
      if (taskList[i].data.repeatDays.contains(true)) {
        int id = taskList[i].data.id;
        bool present = false;
        for (int n = 0; n < repeatTasks.length; n++) {
          if (repeatTasks[n].data.id == id) {
            present = true;
            break;
          }
        }
        if (!present) {
          taskList.removeAt(i);
        }
      }
    }
    // Compare each repeating task against list of scheduled tasks and insert
    // when necessary to avoid duplication
    for (int i = 0; i < repeatTasks.length; i++) {
      int id = repeatTasks[i].data.id;
      bool present = false;
      for (int n = 0; n < taskList.length; n++) {
        if (taskList[n].data.id == id) {
          present = true;
          break;
        }
      }
      if (!present) {
        taskList.add(repeatTasks[i]);
      }
    }
    return taskList;
  }

  Future<List<Map<String, dynamic>>> _loadTaskTable(String tableId) async {
    // Get a reference to the database
    final Database db = await Utils.getDatabase();
    // Get the IDs of tasks scheduled for this day
    List<Map<String, dynamic>> taskTable;
    try {
      taskTable = await db.query(
          "$tableId"
      );
    }
    on DatabaseException {
      taskTable = List(0);
    }
    return taskTable;
  }

  Future<void> saveListData(DateTime listDate) async {
    String date = Utils.dateToString(listDate);
    final Database db = await Utils.getDatabase();
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
          "isLocked" : isLocked ? 1 : 0
        }
    );
  }

  // Note that index defaults to null
  Future<void> saveTask(TaskListItem task, {int index}) async {
    String date = Utils.dateToString(task.data.date);
    final Database db = await Utils.getDatabase();
    // Check if task already exists in the task table and, if so, retain its
    // previously set date. The new data is inserted into the table, replacing
    // any previously saved data under that ID
    List<Map<String, dynamic>> prevData;
    try {
      prevData = await db.query(
          "tasks",
          where: "id = ?",
          whereArgs: [task.data.id]
      );
    }
    on DatabaseException {
      prevData = List(0);
    }
    String prevDate = prevData.length != 0 ? prevData[0]["date"] : null;
    // Scan through each day of the week to see if this task has already been
    // set to repeat
    for (int i = 0; i < 7; i++) {
      // Check if the task being saved is already set to repeat on this day
      final List<Map<String, dynamic>> check = await db.query(
          "repeatDay_$i",
          where: "taskId = ?",
          whereArgs: [task.data.id]
      );
      // Only these two conditions necessitate a change in the underlying data
      // structure
      if (check.length == 1 && task.data.repeatDays[i] == false) {
        // Delete data from table
        await db.delete(
            "repeatDay_$i",
            where: "taskId = ?",
            whereArgs: [task.data.id]
        );
      }
      else if (check.length == 0 && task.data.repeatDays[i] == true) {
        // Add data to table
        await db.insert(
            "repeatDay_$i",
            {"taskId" : task.data.id}
        );
      }
      // For all other conditions, just continue on to check the next day
    }
    // A today date indicates that this is a task only designated for today,
    // while a difference between the previously set date and the new date
    // indicates that a change has occurred and the saved data must be updated
    if (date == Utils.dateToString(DateTime.now()) || prevDate != date) {
      if (prevDate != null && !task.data.repeatDays.contains(true)) {
        // If a date change occurs and the previous date was set, then the data
        // must be removed from the previous date's table. However, we only
        // want to delete the previous data if the task was transferred from
        // one date to another, NOT if it persists across multiple dates
        await db.delete(
            "scheduledTasks_$prevDate",
            where: "taskId = ?",
            whereArgs: [task.data.id]
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
                  "taskId INTEGER PRIMARY KEY, "
                  "taskIndex INTEGER, "
                  "isDeleted INTEGER,"
                  "isDone INTEGER)"
          );
        } catch (e) {}
      }
      // Add to the new date's table. In the case of the task being assigned
      // today's date, its previous data in that table may need to be replaced
      // if it was set
      final List<Map<String, dynamic>> prevScheduledData = await db.query(
          "scheduledTasks_$date",
          where: "taskId = ?",
          whereArgs: [task.data.id]
      );
      // Make sure to delete the old copy, if there is one
      if (prevScheduledData.length != 0) {
        await db.delete(
            "scheduledTasks_$date",
            where: "taskId = ?",
            whereArgs: [task.data.id]
        );
      }
      await db.insert(
        "scheduledTasks_$date",
        {
          "taskId" : task.data.id,
          "taskIndex" : index,
          "isDeleted" : task.isDeleted ? 1 : 0,
          "isDone" : task.data.isDone ? 1 : 0
        },
      );
    }
    task.data.saveData();
  }

  void deleteTask(TaskListItem task) async {
    if (!task.data.isSet)
      return;
    final Database db = await Utils.getDatabase();
    String date = Utils.dateToString(task.data.date);
    // Remove task from appropriate scheduledTasks table
    await db.delete(
        "scheduledTasks_$date",
        where: "taskId = ?",
        whereArgs: [task.data.id]
    );
    // Remove task from tasks table only if task isn't set to repeat
    if (!task.data.repeatDays.contains(true)) {
      // TODO: replace with task.data.unsave
      await db.delete(
          "tasks",
          where: "id = ?",
          whereArgs: [task.data.id]
      );
    }
    else {
      // In the case that this task is set to repeat, mark it as deleted so
      // that it's not reloaded in the given date's list
      await db.insert(
        "scheduledTasks_$date",
        {
          "taskId" : task.data.id,
          "taskIndex" : null,
          "isDeleted" : 1,
          "isDone" : task.data.isDone ? 1 : 0
        },
      );
    }
  }

  void updateIndices(String date, List<TaskListItem> tasks, int length) async {
    final Database db = await Utils.getDatabase();
    for (int i = 0; i < length; i++) {
      if (!tasks[i].data.isSet)
        continue;
      List<Map<String, dynamic>> prevScheduledData;
      try {
        prevScheduledData = await db.query(
          "scheduledTasks_$date",
          where: "taskId = ?",
          whereArgs: [tasks[i].data.id]
        );
      }
      on DatabaseException {
        prevScheduledData = List(0);
      }
      // If the new date's (or today's date's) table doesn't exist, create it
      if (prevScheduledData.length == 0) {
        try {
          await db.execute(
            "CREATE TABLE scheduledTasks_$date("
                "taskId INTEGER PRIMARY KEY, "
                "taskIndex INTEGER, "
                "isDeleted INTEGER,"
                "isDone INTEGER)"
          );
        } catch (e) {}
      }
      // Make sure to delete the old copy, if there is one
      if (prevScheduledData.length != 0) {
        await db.delete(
            "scheduledTasks_$date",
            where: "taskId = ?",
            whereArgs: [tasks[i].data.id]
        );
      }
      await db.insert(
        "scheduledTasks_$date",
        {
          "taskId" : tasks[i].data.id,
          "taskIndex" : i,
          "isDeleted" : tasks[i].isDeleted ? 1 : 0,
          "isDone" : tasks[i].data.isDone ? 1 : 0
        },
      );
    }
  }
}