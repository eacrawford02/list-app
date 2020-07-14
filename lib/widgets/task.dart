import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:listapp/utils/notification_scheduler.dart';
import 'package:listapp/widgets/task_edit_dialog.dart';
import 'package:listapp/models/task_data.dart';

class Task extends StatefulWidget {

  final ITaskList listModel;
  final Animation<double> animation;
  final TaskData taskData;

  Task(this.listModel, this.animation, this.taskData, Key key)
      : super(key: key);

  @override
  TaskState createState() => TaskState(listModel, animation, taskData);
}

enum MenuOptions {EDIT, TO_TOP, TO_BOTTOM}

class TaskState extends State<Task> { // TODO: implement theme data

  ITaskList _listModel;
  Animation<double> _animation;
  TaskData _data;
  bool _isActive = false;
  bool _isExpired = false;
  bool _isLocked;
  Timer _updateStatusStartTimer;
  Timer _updateStatusEndTimer;

  TaskState(this._listModel, this._animation, this._data) {
    _isLocked = _listModel.isLocked();
    _updateStatus();
  }

  void _updateStatus() {
    if (_data.isScheduled) {
      TimeOfDay timeRef = TimeOfDay.now();
      int currentTime = TaskData.createTimeStamp(timeRef.hour, timeRef.minute);
      // Determine whether or not the task is active or expired
      if (_data.startTime != null) {
        int startTime = TaskData.createTimeStamp(
            _data.startTime.hour, _data.startTime.minute);
        if (currentTime >= startTime) {
          _isActive = true;
        }
        else {
          _isActive = false;
        }
      }
      if (_data.endTime != null) {
        int endTime = TaskData.createTimeStamp(
            _data.endTime.hour, _data.endTime.minute);
        if (currentTime >= endTime) {
          _isActive = false;
          _isExpired = true;
        }
        else {
          _isActive = true;
          _isExpired = false;
        }
      }
    }
  }

  void _setNotifications(TaskData newData) {
    // Schedule start time notifications and timers
    DateTime currentTime = DateTime.now();
    if (_data.startTime != newData.startTime) { // Change in start time
      // If the start time has been set for today
      if (newData.startTime != null &&
          TaskData.dateToString(newData.date) ==
              TaskData.dateToString(currentTime)) {
        // Cancel previous local notification and start timer
        if (_data.startTime != null && TaskData.dateToString(_data.date) ==
            TaskData.dateToString(currentTime)) {
          NotificationScheduler.cancelNotification(_data.id);
          _updateStatusStartTimer.cancel();
        }
        // Schedule local notification
        DateTime newStartTime = DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day,
            newData.startTime.hour,
            newData.startTime.minute
        );
        if (newStartTime.isAfter(currentTime)) {
          NotificationScheduler.scheduleNotification(
              newData.id,
              "To-Do:",
              newData.text,
              newStartTime
          );
          // Schedule start timer
          Duration countdown = currentTime.difference(newStartTime);
          _updateStatusStartTimer = Timer(
              countdown,
              () {
                if (this.mounted) {
                  setState(() {
                    _updateStatus();
                  });
                }
              }
          );
        }
      }
      else if (TaskData.dateToString(_data.date) ==
          TaskData.dateToString(currentTime)) {
        // Cancel local notification
        DateTime prevStartTime = DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day,
            _data.startTime.hour,
            _data.startTime.minute
        );
        if (prevStartTime.isAfter(currentTime)) {
          NotificationScheduler.cancelNotification(newData.id);
          // Cancel start timer
          _updateStatusStartTimer.cancel();
        }
      }
    }
    // Schedule end time timers
    if (_data.endTime != newData.endTime) { // Change in end time
      // If the end time has been set for today
      if (newData.endTime != null &&
          TaskData.dateToString(newData.date) ==
              TaskData.dateToString(currentTime)) {
        // Cancel previous end timer
        if (_data.endTime != null && TaskData.dateToString(_data.date) ==
            TaskData.dateToString(currentTime)) {
          _updateStatusEndTimer.cancel();
        }
        // Schedule end timer
        DateTime newEndTime = DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day,
            _data.endTime.hour,
            _data.endTime.minute
        );
        if (newEndTime.isAfter(currentTime)) {
          // Add a minute to properly trigger expiry as the then current time
          // must be greater than the task's end time
          Duration countdown = currentTime.difference(
              newEndTime.add(Duration(minutes: 1))
          );
          _updateStatusEndTimer = Timer(
              countdown,
              () {
                if (this.mounted) {
                  setState(() {
                    _updateStatus();
                  });
                }
              }
          );
        }
      }
      else if (TaskData.dateToString(_data.date) ==
          TaskData.dateToString(currentTime)) {
        // Cancel end timer
        _updateStatusEndTimer.cancel();
      }
    }
  }

  void _onChecked(bool) {
    setState(() {
      _data.isDone = bool;
      _listModel.submitTaskEdit(_data);
    });
  }

  void showEditDialog(BuildContext context) async {
    TaskData newData = await showDialog<TaskData>(
      context: context,
      builder: (BuildContext context) => TaskEditDialog(_data)
    );
    if (newData.isSet) {
      _setNotifications(newData);

      setState(() {
        _data = newData;
        _updateStatus();
        _listModel.submitTaskEdit(newData);
      });
    }
  }

  String get _displayTime {
    if (_data.startTime != null && _data.endTime != null) {
      String start = TaskData.timeToString(_data.startTime);
      String end = TaskData.timeToString(_data.endTime);
      return "$start - $end";
    }
    else if (_data.startTime != null) {
      String start = TaskData.timeToString(_data.startTime);
      return "$start";
    }
    else if (_data.endTime != null) {
      String end = TaskData.timeToString(_data.endTime);
      return "Until $end";
    }
    else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 8
      ),
      child: SizeTransition(
        axis: Axis.vertical,
        sizeFactor: _animation,
        child: Card(
          shape: Border(
            bottom: _isActive ? BorderSide(color: Colors.blue) : BorderSide.none
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 2,
              bottom: 2,
            ),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: Checkbox(
                      value: _data.isDone,
                      onChanged: _data.isSet && !_isExpired ? _onChecked : null,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(""),
                      Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 8,
                          ),
                          child: Text(
                            _data.text,
                            style: TextStyle(
                              fontSize: 18,
                              decoration: _isExpired ?
                                TextDecoration.lineThrough : TextDecoration.none
                            ),
                          )
                      ),
                      Text("$_displayTime")
                    ],
                  ),
                ),
                Container(
                  child: _data.isSet ?
                    PopupMenuButton<MenuOptions>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (MenuOptions result) {
                        switch (result) {
                          case MenuOptions.EDIT:
                            showEditDialog(context);
                            break;
                          case MenuOptions.TO_TOP:
                            _listModel.moveToTop(_data);
                            break;
                          case MenuOptions.TO_BOTTOM:
                            _listModel.moveToBottom(_data);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<MenuOptions>> [
                            const PopupMenuItem<MenuOptions>(
                              value: MenuOptions.EDIT,
                              child: Text("Edit Task"),
                            ),
                            !_data.isScheduled ?
                            const PopupMenuItem<MenuOptions>(
                              value: MenuOptions.TO_TOP,
                              child: Text("Move To Top"),
                            ) : null,
                            !_data.isScheduled ?
                            const PopupMenuItem<MenuOptions>(
                              value: MenuOptions.TO_BOTTOM,
                              child: Text("Move To Bottom"),
                            ) : null,
                          ]
                    ) :
                    IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => showEditDialog(context)
                    ),
                ),
                IconButton(
                    icon: Icon(Icons.delete),
                    highlightColor: Colors.redAccent,
                    splashColor: Color.fromRGBO(255, 0, 0, 0.5),
                    onPressed: () {
                      _listModel.removeTask(_data);
                      NotificationScheduler.cancelNotification(_data.id);
                    }
                ),
              ],
            ),
          )
        ),
      ),
    );
  }
}

abstract class ITaskList {
  bool isLocked();

  void submitTaskEdit(TaskData data);

  void moveToTop(TaskData data);

  void moveToBottom(TaskData data);

  void removeTask(TaskData data);
}