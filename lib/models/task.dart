import 'package:flutter/material.dart';
import 'package:listapp/models/task_edit_dialog.dart';
import 'package:listapp/utils/utils.dart';
import 'package:listapp/widgets/list_item.dart';
import 'package:listapp/models/task_list.dart';
import 'package:listapp/models/task_data.dart';

enum MenuOptions {EDIT, TO_TOP, TO_BOTTOM}

class Task {
  final ListItemData listItemData;
  TaskList _taskList;
  TaskData _data;
  bool _isActive = false;
  bool _isExpired = false;
  bool _isLocked = false;

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

  Task(this.listItemData, this._taskList, this._data) {
    // Initialize this object
    // Initialize _listItemData values
    listItemData.text = _data.text;
    listItemData.textDecoration = _isExpired ? TextDecoration.lineThrough :
        TextDecoration.none;
    listItemData.bottomText = _timeDisplay;
    listItemData.isHighlighted = _isActive;
    listItemData.highlightColor = Colors.blue;
    // Populate widget with checkbox and buttons
    listItemData.leftAction = (BuildContext context) {
      return Checkbox(
        value: _data.isDone,
        onChanged: _data.isSet && !_isExpired && !_isLocked ?
            (bool newValue) => _onCheck(newValue) : null
      );
    };
    listItemData.rightAction = (BuildContext context) {
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
                    _taskList.moveToTop(this);
                    break;
                  case MenuOptions.TO_BOTTOM:
                    _taskList.moveToBottom(this);
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
              _taskList.removeTask(this);
              // TODO: cancel notifications
            }
          )
        ]
      );
    };
    // Update widget
    listItemData.updateWidget();
  }

  void _updateStatus() {
    // TODO: implement
  }

  void _onCheck(bool newValue) {
    // TODO: notify list
    if (!_data.isDone && newValue) {

    }
    _data.isDone = newValue;
    // TODO: save data
    listItemData.isHighlighted = _isActive && !newValue;
    listItemData.updateWidget();
  }

  void _showEditDialog(BuildContext context) async {
    TaskData newData = await showDialog<TaskData>(
      context: context,
      builder: (BuildContext context) => TaskEditDialog(_data)
    );
    if (newData.isSet) {
      // TODO: set notifications
      _data = newData;
      _updateStatus();
      // TODO: submit task edit to list
      listItemData.text = newData.text;
      listItemData.updateWidget();
    }
  }
}