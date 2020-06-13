import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:listapp/models/task_list.dart';

class Task extends StatefulWidget {

  final TaskList listModel;
  final Animation<double> animation;
  final TaskData taskData;

  Task({this.listModel, this.animation, this.taskData, Key key})
      : super(key: key);

  @override
  TaskState createState() => TaskState(listModel, animation, taskData);
}

class TaskState extends State<Task> {

  TaskList _listModel;
  Animation<double> _animation;
  TaskData _data;
  bool _isActive;
  bool _isExpired;

  TaskState(this._listModel, this._animation, this._data);

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
              IconButton(icon: Icon(Icons.accessibility), onPressed: null)
            ],
          ),
        ),
      ),
    );
  }
}

class TaskData {

  int id;
  bool isDone;
  String text;
  TimeOfDay startTime;
  TimeOfDay endTime;

  TaskData({this.id, this.isDone, this.text, this.startTime, this.endTime});
}