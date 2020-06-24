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
    TimeOfDay timeRef = TimeOfDay.now();
    int currentTime = _data.createTimeStamp(timeRef.hour, timeRef.minute);
    int startTime = _data.createTimeStamp(_data.startTimeH, _data.startTimeM);
    int endTime = _data.createTimeStamp(_data.endTimeH, _data.endTimeM);
    // Determine whether or not the task is active or expired
    if (_data.isScheduled && currentTime >= startTime) {
      _isActive = true;
      if (currentTime >= endTime) {
        _isActive = false;
        _isExpired = true;
      }
    }
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
  int startTimeH;
  int startTimeM;
  int endTimeH;
  int endTimeM;

  TaskData({
    @required this.id,
    this.isDone : false,
    this.text : "Edit Task",
    this.isScheduled : false,
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