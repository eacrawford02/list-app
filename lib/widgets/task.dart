import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:listapp/widgets/task_edit_dialog.dart';

class Task extends StatefulWidget {

  final ITaskList listModel;
  final Animation<double> animation;
  final TaskData taskData;

  Task(this.listModel, this.animation, this.taskData, Key key)
      : super(key: key);

  @override
  TaskState createState() => TaskState(listModel, animation, taskData);
}

class TaskState extends State<Task> {

  ITaskList _listModel;
  Animation<double> _animation;
  TaskData _data;
  bool _isActive = false;
  bool _isExpired = false;

  TaskState(this._listModel, this._animation, this._data) {
    if (_data.isScheduled) {
      TimeOfDay timeRef = TimeOfDay.now();
      int currentTime = _data.createTimeStamp(timeRef.hour, timeRef.minute);
      // Determine whether or not the task is active or expired
      if (_data.startTime != null) {
        int startTime = _data.createTimeStamp(
            _data.startTime.hour, _data.startTime.minute);
        if (currentTime >= startTime) {
          _isActive = true;
        }
      }
      if (_data.endTime != null) {
        int endTime = _data.createTimeStamp(
            _data.endTime.hour, _data.endTime.minute);
        if (currentTime >= endTime) {
          _isActive = false;
          _isExpired = true;
        }
      }
    }
  }

  void updateStatus() {

  }

  void onChecked(bool) {
    setState(() {
      _data.isDone = bool;
    });
  }

  void showEditDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => TaskEditDialog(_data)
    );
    if (_data.isSet) {
      setState(() {
        // TODO: check if status has changed (active/expired)
        _listModel.submitTaskEdit(_data);
      });
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
                      onChanged: _data.isSet || _isExpired ? onChecked : null,
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
                            style: TextStyle(fontSize: 18),
                          )
                      ),
                      Text("time")
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

class TaskData {

  final int id;
  bool isSet = false;
  bool isDone;
  String text;
  bool isScheduled;
  TimeOfDay startTime;
  TimeOfDay endTime;
  List<bool> repeatDays = List.filled(7, false);
  DateTime date;

  TaskData({
    @required this.id,
    this.isDone : false,
    this.text : "Edit Task",
    this.isScheduled : false,
    this.startTime,
    this.endTime,
    this.date
  });

  int createTimeStamp(int hour, int minute) {
    return (hour * 100) + minute;
  }

  String timeToString(TimeOfDay timeOfDay) {
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

  String dateToString(DateTime date) {
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
    return "$year-$mm-$dd";
  }
}

abstract class ITaskList {
  void submitTaskEdit(TaskData data);

  void moveToTop(TaskData data);

  void moveToBottom(TaskData data);

  void removeTask(TaskData data);
}