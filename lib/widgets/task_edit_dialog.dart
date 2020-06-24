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

  TaskEditDialogState(this._taskData);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Edit Task",
        textAlign: TextAlign.center
      ),
      content: Column(
        children: <Widget>[
          Divider(),
          Text("hi")
        ],
      ),
      actions: <Widget>[

      ],
    );
  }

}