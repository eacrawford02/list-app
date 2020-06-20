import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:listapp/models/task_list.dart';

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
    TimeOfDay timeRef = TimeOfDay.now();
    int currentTime = _data.createTimeStamp(timeRef.hour, timeRef.minute);
    int startTime = _data.createTimeStamp(_data.startTimeH, _data.startTimeM);
    int endTime = _data.createTimeStamp(_data.endTimeH, _data.endTimeM);
    // Determine whether or not the task is active or expired
    if (currentTime >= startTime) {
      _isActive = true;
      if (currentTime >= endTime) {
        _isActive = false;
        _isExpired = true;
      }
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
          child: Row(
            children: <Widget>[
              Checkbox(value: false, onChanged: null),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(""),
                    Text(
                      "bruh",
                      style: TextStyle(fontSize: 18),
                    ),
                    Text("time")
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.accessibility), onPressed: null),
              IconButton(icon: Icon(Icons.accessibility), onPressed: () {
                _listModel.removeTask(_data);
              })
            ],
          ),
        ),
      ),
    );
  }
}

class TaskData {

  final int id;
  bool isDone;
  String text;
  bool isScheduled;
  int startTimeH;
  int startTimeM;
  int endTimeH;
  int endTimeM;

  TaskData({
    @required this.id,
    this.isDone : false,
    this.text : "Edit Task",
    this.isScheduled,
    this.startTimeH : 0,
    this.startTimeM : 0,
    this.endTimeH : 0,
    this.endTimeM : 0
  });

  int createTimeStamp(int hour, int minute) {
    return (hour * 100) + minute;
  }
}

abstract class ITaskList {
  void submitTaskEdit(TaskData data);

  void moveToTop(TaskData data);

  void moveToBottom(TaskData data);

  void removeTask(TaskData data);
}