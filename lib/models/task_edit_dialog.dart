import 'package:flutter/material.dart';
import 'package:listapp/utils/utils.dart';
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
  String _error = "";
  bool _isDone;
  String _text;
  TimeOfDay _startTime;
  TimeOfDay _endTime;
  List<bool> _repeatDays;
  DateTime _date;

  TaskEditDialogState(this._taskData) {
    _isDone = _taskData.isDone;
    _startTime = _taskData.startTime;
    _endTime = _taskData.endTime;
    _repeatDays = _taskData.repeatDays;
    _date = _taskData.date;

    if (_taskData.isSet) {
      _text = _taskData.text;
      _textController.text = _text;
    }
  }

  TaskData _saveData(bool saveSuccess) {
    if (_text == null || !saveSuccess)
      return _taskData;

    TaskData newData = TaskData(id: _taskData.id);

    newData.isSet = true;
    if (_startTime != null || _endTime != null) {
      newData.isScheduled = true;
    }

    newData.isDone = _isDone;
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
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                          hintText: _taskData.isSet ? "" : "E.g. Go for a run"
                      ),
                      onSubmitted: (String value) {
                        if (_textController.text != "") {
                          _text = value;
                        }
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
                    _startTime == null ? "Not Set" :
                        Utils.timeToString(_startTime)
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
                    _endTime == null ? "Not Set" : Utils.timeToString(_endTime)
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
                        Utils.dateToString(_date) ==
                            Utils.dateToString(DateTime.now()) ?
                        "Today" :
                        Utils.dateToString(_date).replaceAll(RegExp(r"_"), "-")
                    ),
                    // TODO: date cannot be set if task is set to repeat
                    onPressed: () async {
                      _date = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: _date,
                          lastDate: _date.add(Duration(days: 36500))
                      ) ?? _date;
                      setState(() {});
                    }
                )
              ])
          ),
          Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(top: 32),
              child: Text(
                _error,
                style: TextStyle(fontSize: 10, color: Colors.red),
              )
          )
        ],
      ),
      actions: <Widget>[
        FlatButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(_saveData(false))
        ),
        FlatButton(
            child: Text("Save"),
            onPressed: () {
              if (_textController.text != "") {
                _text = _textController.text;
              }
              int start;
              int end;
              if (_startTime != null && _endTime != null) {
                start =
                    Utils.createTimeStamp(_startTime.hour, _startTime.minute);
                end = Utils.createTimeStamp(_endTime.hour, _endTime.minute);
              }
              else {
                start = 0;
                end = 0;
              }
              if (start > end) {
                setState(() {
                  _error = "Error: The task can't end before it starts!";
                });
              }
              else {
                Navigator.of(context).pop(_saveData(true));
              }
            }
        )
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();

    _textController.dispose();
  }

}