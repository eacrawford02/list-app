import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:listapp/widgets/list.dart';
import 'package:listapp/widgets/task.dart';
import 'package:listapp/models/task_data.dart';

typedef _GetTimeFunction = TimeOfDay Function(int index);

class TaskList implements IListData<TaskData>, ITaskList {

  List<TaskData> _list;
  int _timedHead;
  int _timedTail;
  int _numTasks;
  int _numCompletedTasks;
  // TODO: _wastedTime;
  Widget _listWidget;
  GlobalKey<AnimatedListState> _key;
  // Why is this a getter method? Because if we were to set _listWidgetState to
  // equal _key.currentState right after constructing _listWidget (which should
  // work), for some reason _key is a null value, even though it is set via a
  // callback in the ListWidgetState class. My guess is that there's some async
  // bs going on behind the scenes
  AnimatedListState get _listWidgetState => _key.currentState;
  dynamic _removeItemCallback;
  Function _refreshListWidget;

  TaskList() {
    _list = List();
    _timedHead = 0;
    _timedTail = 0;
    _numTasks = 0;
    _numCompletedTasks = 0;

    _listWidget = ListWidget(this, _key, _loadData());
  }

  int _loadData() {
    // TODO: load task data from database


    return _numTasks;
  }

  int _seek(TaskData data) {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].id == data.id) {
        return i;
      }
    }
    String text = data.text;
    throw Exception("Item '$text' not found in list");
  }

  void _timeSort(TaskData data, TimeOfDay taskTime, _GetTimeFunction getTime) {
    int timeStamp = TaskData.createTimeStamp(taskTime.hour, taskTime.minute);
    // If first scheduled task in the list
    if (_timedHead == _timedTail) {
      _list.insert(_timedHead, data);
      _timedTail++;
      return;
    }
    for (int i = _timedHead; i <= _timedTail; i++) {
      // If the end of the list has been reached
      if (i == _timedTail) {
        _list.insert(_timedTail, data);
        _timedTail++;
        return;
      }
      // Perform normal sort
      else {
        int indexTimeStamp = TaskData.createTimeStamp(
            getTime(i).hour,
            getTime(i).minute
        );
        if (timeStamp < indexTimeStamp) {
          _list.insert(i, data);
          _timedTail++;
          return;
        }
      }
    }
  }

  void addNewTask({TaskData taskData}) {
    _list.add(taskData ?? TaskData(id: DateTime.now().millisecondsSinceEpoch));
    _listWidgetState.insertItem(_list.length - 1);
  }

  @override
  void submitTaskEdit(TaskData taskData) {
    // Add task data to list
    // We need to remove the previous version of this task from the list, and
    // then have the list reflect this change. However, this only applies if the
    // previous version of this task had actually been set and this is not just
    // a newly added task. Otherwise, the previous (unedited) task would fall
    // outside the range of the list where its removal would have any impact on
    // the timed head or tail, or the number of tasks in the list
    int prevPos = _seek(taskData);
    if (_list[prevPos].isSet) {
      _numTasks++;
      if (prevPos < _timedHead) {
        _timedHead--;
        _timedTail--;
      }
      else if (prevPos <= _timedTail) {
        _timedTail--;
      }
    }
    // If, however, this is a newly edited task, then we must increment the
    // number of tasks
    else {
      _numTasks++;
    }
    _list.removeAt(prevPos);
    // Now we can sort and insert the new task
    if (taskData.isScheduled) {
      // If the task is given a start time, then sort it based on that
      if (taskData.startTime != null) {
        _timeSort(taskData, taskData.startTime, (index) {
          return _list[index].startTime;
        });
      }
      // If not (only given an end time), then sort it based on the end time
      else {
        _timeSort(taskData, taskData.endTime, (index) {
          return _list[index].endTime;
        });
      }
    }
    else {
      _list.insert(_numTasks - 1, taskData);
    }
    _refreshListWidget.call();
    print("length");
    print(_list.length);
    print(_numTasks);

    // TODO: add task data to database
  }

  @override
  void moveToTop(TaskData data) {
    int pos = _seek(data);
    if (pos >= _timedHead && pos < _timedTail) {
      throw Exception("Can't move scheduled task to the top");
    }
    else if (pos >= _timedTail) {
      _timedHead++;
      _timedTail++;
    }
    // TODO: fix
    _list.removeAt(pos);
    _list.insert(0, data);
    _listWidgetState.insertItem(0);

    // TODO: Save changes to database
  }

  @override
  void moveToBottom(TaskData data) {
    int pos = _seek(data);
    if (pos >= _timedHead && pos < _timedTail) {
      throw Exception("Can't move scheduled task to the bottom");
    }
    else if (pos < _timedHead) {
      _timedHead--;
      _timedTail--;
    }
    // TODO: fix
    _list.removeAt(pos);
    _listWidgetState.removeItem(
        pos,
            (context, animation) => _removeItemCallback(
            Task(this, animation, data, UniqueKey())
        )
    );
    _list.insert(_numTasks - 1, data);
    _listWidgetState.insertItem(0);

    // TODO: Save changes to database
  }

  @override
  void removeTask(TaskData data) {
    int index = _seek(data);
    _list.removeAt(index);
    if (data.isSet) {
      _numTasks--;
    }

    _listWidgetState.removeItem(
        index,
        (context, animation) => _removeItemCallback(
            Task(this, animation, data, UniqueKey())
        )
    );
  }

  @override
  void setKey(GlobalKey<AnimatedListState> key) {
    this._key = key;
  }

  @override
  void setItemRemover(Function function) {
    this._removeItemCallback = function;
  }

  @override
  void setRefreshCallback(Function function) {
    this._refreshListWidget = function;
  }

  // Returns a Task object already loaded with the data that was added to the
  // list
  @override
  Widget getItemWidget(int index, Animation<double> animation) {
    return Task(this, animation, _list[index], UniqueKey());
  }

  int getNumTasks() {
    return _numTasks;
  }

  int getNumCompletedTasks() {
    return _numCompletedTasks;
  }

  Widget getLayout() {
    return _listWidget;
  }

}