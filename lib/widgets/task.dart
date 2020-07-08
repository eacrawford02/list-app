import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class TaskState extends State<Task> { // TODO: add dropdown menu

  ITaskList _listModel;
  Animation<double> _animation;
  TaskData _data;
  bool _isActive = false;
  bool _isExpired = false;

  TaskState(this._listModel, this._animation, this._data) {
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

  void onChecked(bool) {
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

  void lock() {
    // TODO: for when the day is done
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
                      onChanged: _data.isSet && !_isExpired ? onChecked : null,
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
                IconButton(
                    icon: Icon(_data.isSet ? Icons.more_vert : Icons.edit),
                    onPressed: () => showEditDialog(context)
                ),
                IconButton(
                    icon: Icon(Icons.delete),
                    highlightColor: Colors.redAccent,
                    splashColor: Color.fromRGBO(255, 0, 0, 0.5),
                    onPressed: () {
                      _listModel.removeTask(_data);
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
  void submitTaskEdit(TaskData data);

  void moveToTop(TaskData data);

  void moveToBottom(TaskData data);

  void removeTask(TaskData data);
}