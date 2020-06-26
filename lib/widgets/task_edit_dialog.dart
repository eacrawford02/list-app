import 'package:flutter/material.dart';
import 'package:listapp/widgets/task.dart';

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

  void _saveData() {
    if (_text == null)
      return;

    _taskData.isSet = true;
    if (_startTime != null || _endTime != null) {
      _taskData.isScheduled = true;
    }

    _taskData.text = _text;
    _taskData.startTime = _startTime;
    _taskData.endTime = _endTime;
    _taskData.repeatDays = _repeatDays;
    _taskData.date = _date;
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
                      maxLines: null,
                      onSubmitted: (String value) {
                        print(value);
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
                  _startTime == null ? "Not Set" : _taskData.timeToString(_startTime)
              ),
              onPressed: () async {
                _startTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now()
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
                    _endTime == null ? "Not Set" : _taskData.timeToString(_endTime)
                ),
                onPressed: () async {
                  _endTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now()
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
                      _date == null ? "Not Set" : _taskData.dateToString(_date)
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
            _saveData();
            Navigator.of(context).pop();
          }
        )
      ],
    );
  }

}