import 'package:flutter/material.dart';
import 'package:listapp/models/task_data.dart';

class TaskEditDialog extends StatefulWidget {

  final TaskData _taskData;

  TaskEditDialog(this._taskData);

  @override
  TaskEditDialogState createState() => TaskEditDialogState(_taskData);

}

class TaskEditDialogState extends State<TaskEditDialog> {

  final TaskData _taskData;
  TextEditingController _textController = TextEditingController();
  String _text;
  TimeOfDay _startTime;
  TimeOfDay _endTime;
  List<bool> _repeatDays;
  DateTime _date;

  TaskEditDialogState(this._taskData) {
    _startTime = _taskData.startTime;
    _endTime = _taskData.endTime;
    _repeatDays = _taskData.repeatDays;
    _date = _taskData.date;

    if (_taskData.isSet) {
      _text = _taskData.text;
      _textController.text = _text;
    }
  }

  TaskData _saveData() {
    if (_text == null)
      return _taskData;

    TaskData newData = TaskData(id: _taskData.id);

    newData.isSet = true;
    if (_startTime != null || _endTime != null) {
      newData.isScheduled = true;
    }

    newData.text = _text;
    newData.startTime = _startTime;
    newData.endTime = _endTime;
    newData.repeatDays = _repeatDays;
    newData.date = _date;
    return newData;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Edit Task",
        textAlign: TextAlign.center
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 16
            ),
            child: Row(children: <Widget>[
              Expanded(
                  child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                          hintText: _taskData.isSet ? "" : "E.g. Go for a run"
                      ),
                      onSubmitted: (String value) {
                        _text = value;
                      }
                  )
              ),
              IconButton(
                  icon: Icon(Icons.cancel),
                  iconSize: 24,
                  onPressed: () {
                    _textController.text = "";
                  }
              )
            ]),
          ),
          Row(children: <Widget>[
            Expanded(
              child: Text("Set Start Time:"),
            ),
            OutlineButton(
              child: Text(
                  _startTime == null ? "Not Set" : TaskData.timeToString(_startTime)
              ),
              onPressed: () async {
                _startTime = await showTimePicker(
                  context: context,
                  initialTime: _startTime != null ? _startTime : TimeOfDay.now()
                );
                setState(() {});
              }
            )
          ]),
          Row(children: <Widget>[
            Expanded(
              child: Text("Set End Time:"),
            ),
            OutlineButton(
                child: Text(
                    _endTime == null ? "Not Set" : TaskData.timeToString(_endTime)
                ),
                onPressed: () async {
                  _endTime = await showTimePicker(
                      context: context,
                      initialTime: _endTime != null ? _endTime : TimeOfDay.now()
                  );
                  setState(() {});
                }
            )
          ]),
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 16
            ),
            child: Text("Repeat On:", textAlign: TextAlign.left)
          ),
          ToggleButtons(
            children: <Widget>[
              Text("M"), Text("T"), Text("W"), Text("T"), Text("F"), Text("S"),
              Text("S")
            ],
            constraints: BoxConstraints.expand(width: 30, height: 30),
            borderRadius: BorderRadius.circular(2),
            onPressed: (int index) {
              setState(() {
                _repeatDays[index] = !_repeatDays[index];
              });
            },
            isSelected: _repeatDays
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(children: <Widget>[
              Expanded(
                child: Text("Schedule Date:"),
              ),
              OutlineButton(
                  child: Text(
                      _date == null ? "Not Set" : TaskData.dateToString(_date)
                  ),
                  onPressed: () async {
                    _date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 36500))
                    );
                    setState(() {});
                  }
              )
            ])
          )
        ],
      ),
      actions: <Widget>[
        FlatButton(
          child: Text("Cancel"),
          onPressed: () => Navigator.of(context).pop()
        ),
        FlatButton(
          child: Text("Save"),
          onPressed: () {
            Navigator.of(context).pop(_saveData());
          }
        )
      ],
    );
  }

}