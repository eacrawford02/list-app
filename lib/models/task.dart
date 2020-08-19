import 'dart:async';
import 'package:flutter/material.dart';
import 'package:listapp/utils/notification_scheduler.dart';
import 'package:listapp/utils/utils.dart';
import 'package:listapp/widgets/list_item.dart';
import 'package:listapp/models/task_list.dart';
import 'package:listapp/models/task_data.dart';
import 'package:listapp/models/task_edit_dialog.dart';

enum MenuOptions {EDIT, TO_TOP, TO_BOTTOM}

class Task {
  final ListItemData _listItemData;
  TaskList _taskList;
  TaskData _data;
  bool _isActive = false;
  bool _isExpired = false;
  bool _isLocked = false;
  Timer _updateStatusStartTimer;
  Timer _updateStatusEndTimer;

  String get _timeDisplay {
    if (_data.startTime != null && _data.endTime != null) {
      String start = Utils.timeToString(_data.startTime);
      String end = Utils.timeToString(_data.endTime);
      return "$start - $end";
    }
    else if (_data.startTime != null) {
      String start = Utils.timeToString(_data.startTime);
      return "$start";
    }
    else if (_data.endTime != null) {
      String end = Utils.timeToString(_data.endTime);
      return "Until $end";
    }
    else {
      return "";
    }
  }

  Task(this._listItemData, this._taskList, this._data) {
    // Initialize this object
    _updateStatus();
    cancelNotifications(_data);
    _scheduleNotifications(_data);
    // Initialize _listItemData values
    _listItemData.text = _data.text;
    _listItemData.textDecoration = _isExpired ? TextDecoration.lineThrough :
        TextDecoration.none;
    _listItemData.bottomText = _timeDisplay;
    _listItemData.isHighlighted = _isActive;
    _listItemData.highlightColor = Colors.blue;
    // Populate widget with checkbox and buttons
    _listItemData.leftAction = (BuildContext context) {
      return Checkbox(
        value: _data.isDone,
        onChanged: _data.isSet && !_isExpired && !_isLocked ?
            (bool newValue) => _onCheck(newValue) : null
      );
    };
    _listItemData.rightAction = (BuildContext context) {
      return Row(
        children: <Widget>[
          Container(
            child: _data.isSet ? PopupMenuButton<MenuOptions>(
              icon: Icon(Icons.more_vert),
              onSelected: (MenuOptions result) {
                switch (result) {
                  case MenuOptions.EDIT:
                    _showEditDialog(context);
                    break;
                  case MenuOptions.TO_TOP:
                    _taskList.moveToTop(_data);
                    break;
                  case MenuOptions.TO_BOTTOM:
                    _taskList.moveToBottom(_data);
                    break;
                }
              },
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<MenuOptions>>[
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
                    ) : null
                  ]
            ) : IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _showEditDialog(context)
            )
          ),
          IconButton(
            icon: Icon(Icons.delete),
            highlightColor: Colors.redAccent,
            splashColor: Color.fromRGBO(255, 0, 0, 0.5),
            onPressed: () {
              _taskList.removeTask(_data);
              cancelNotifications(_data);
            }
          )
        ]
      );
    };
    // Update widget
    _listItemData.updateWidget();
  }

  void _updateStatus() {
    if (_data.isScheduled) {
      TimeOfDay timeRef = TimeOfDay.now();
      int currentTime = Utils.createTimeStamp(timeRef.hour, timeRef.minute);
      int startTime = _data.startTime != null ? Utils.createTimeStamp(
          _data.startTime.hour, _data.startTime.minute) : null;
      int endTime = _data.endTime != null ? Utils.createTimeStamp(
          _data.endTime.hour, _data.endTime.minute) : null;
      // Determine whether or not the task is active or expired
      if (_data.startTime != null && _data.endTime != null) {
        if (currentTime >= startTime && currentTime < endTime) {
          _isActive = true;
          _isExpired = false;
        }
        else if (currentTime >= endTime) {
          _isActive = false;
          _isExpired = true;
        }
      }
      else if (_data.startTime != null) {
        if (currentTime >= startTime) {
          _isActive = true;
        }
        else {
          _isActive = false;
        }
      }
      else if (_data.endTime != null) {
        if (currentTime >= endTime) {
          _isActive = false;
          _isExpired = true;
        }
        else {
          _isActive = true;
        }
      }
    }
    _listItemData.textDecoration = _isExpired ? TextDecoration.lineThrough :
    TextDecoration.none;
    _listItemData.isHighlighted = _isActive;
    _listItemData.updateWidget();
  }

  void _scheduleNotifications(TaskData data) {
    DateTime currentTime = DateTime.now();
    // Only schedule if task was set for today
    if (Utils.dateToString(data.date) != Utils.dateToString(currentTime))
      return;
    if (data.startTime != null) {
      // Schedule local notification
      DateTime newStartTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          data.startTime.hour,
          data.startTime.minute
      );
      if (newStartTime.isAfter(currentTime)) {
        NotificationScheduler.scheduleNotification(
            data.id,
            "To-Do:",
            data.text,
            newStartTime
        );
        // Schedule start timer
        Duration countdown = currentTime.difference(newStartTime).abs();
        _updateStatusStartTimer = Timer(
          countdown,
          () {
            _updateStatus();
          }
        );
      }
    }
    if (data.endTime != null) {
      // Schedule end timer
      DateTime newEndTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          data.endTime.hour,
          data.endTime.minute
      );
      if (newEndTime.isAfter(currentTime)) {
        // Add a minute to properly trigger expiry as the then current time
        // must be greater than the task's end time
        Duration countdown = currentTime.difference(
            newEndTime.add(Duration(minutes: 1))
        ).abs();
        _updateStatusEndTimer = Timer(
          countdown,
          () {
            _updateStatus();
          }
        );
      }
    }
  }

  void cancelNotifications(TaskData data) {
    DateTime currentTime = DateTime.now();
    // Only cancel if task has been set for today (to ensure that we don't
    // cancel notifications that don't exist)
    if (Utils.dateToString(data.date) != Utils.dateToString(currentTime))
      return;
    if (data.startTime != null) {
      DateTime startTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          data.startTime.hour,
          data.startTime.minute
      );
      // If startTime is in the future
      if (startTime.isAfter(currentTime)) {
        NotificationScheduler.cancelNotification(data.id);
        // Cancel start timer
        _updateStatusStartTimer?.cancel();
      }
    }
    if (data.endTime != null) {
      DateTime endTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          data.endTime.hour,
          data.endTime.minute
      );
      // If endTime is in the future
      if (endTime.isAfter(currentTime)) {
        _updateStatusEndTimer?.cancel();
      }
    }
  }

  void _onCheck(bool newValue) {
    bool prev = _data.isDone;
    _data.isDone = newValue;
    if (prev && !newValue) { // Unchecked
      // We don't have to cancel notifications first here because the checkbox
      // can't be unchecked before it has been checked
      _scheduleNotifications(_data);
    }
    else if (!prev && newValue) { // Checked
      cancelNotifications(_data);
    }
    _taskList.onTaskCheckEvent(_data, prev, newValue);
    _listItemData.isHighlighted = _isActive && !newValue;
    _listItemData.updateWidget();
  }

  void _showEditDialog(BuildContext context) async {
    TaskData newData = await showDialog<TaskData>(
      context: context,
      builder: (BuildContext context) => TaskEditDialog(_data)
    );
    if (newData.isSet) {
      cancelNotifications(_data);
      _scheduleNotifications(newData);
      _data = newData;
      _updateStatus();
      _taskList.onTaskEditEvent(newData);
      _listItemData.text = newData.text;
      _listItemData.bottomText = _timeDisplay;
      _listItemData.updateWidget();
    }
  }
}