import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:listapp/widgets/list.dart';
import 'package:listapp/widgets/task.dart';
import 'package:listapp/models/task_data.dart';
import 'package:listapp/utils/save_manager.dart';

typedef _GetTimeFunction = TimeOfDay Function(int index);

class TaskList implements IListData<TaskData>, ITaskList {

  SaveManager _saveManager;
  List<TaskData> _list;
  DateTime _listDate;
  int _timedHead; // Inclusive
  int _timedTail; // Inclusive
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
    _listDate = DateTime.now();
    _timedHead = 0;
    _timedTail = 0;
    _numTasks = 0;
    _numCompletedTasks = 0;
  }

  Future<void> init() async {
    _saveManager = await SaveManager.getManager();
    Future<void> initialized = _loadData();
    _listWidget = ListWidget(this, _key, initialized, _numTasks);
    // Now that the list model has completed initialization, refresh the list
    // widget
    initialized.then((value) => _refreshListWidget.call());
  }

  Future<void> _loadData() async {
    // Load task data from database
    String date = TaskData.dateToString(_listDate);
    List<TaskData> scheduledTasks = await _saveManager.loadScheduledTasks(date);
    List<TaskData> repeatTasks = await _saveManager.loadRepeatTasks(date,
        _listDate.weekday);
    // We must check each repeating task in the list of scheduled tasks
    // against the list of repeating tasks in order to account for tasks that
    // have been set to no longer repeat on this day of the week. These tasks
    // must then be removed from the scheduled tasks list
    for (int i = 0; i < scheduledTasks.length; i++) {
      // Update number of completed tasks with each step in the list
      bool taskComplete = scheduledTasks[i].isDone;
      if (taskComplete) {
        _numCompletedTasks++;
      }
      // Set head and tail values prior to modifying list
      if (i != 0) {
        if (scheduledTasks[i].isScheduled &&
            !scheduledTasks[i - 1].isScheduled) {
          _timedHead = i;
        }
        else if (!scheduledTasks[i].isScheduled &&
            scheduledTasks[i - 1].isScheduled) {
          _timedTail = i - 1;
        }
        else if (i == scheduledTasks.length - 1 &&
            scheduledTasks[i].isScheduled) {
          _timedTail = i;
        }
      }
      // Otherwise just leave the default values of 0 and 0
      // Perform check
      if (scheduledTasks[i].repeatDays.contains(true)) {
        int id = scheduledTasks[i].id;
        bool present = false;
        for (int n = 0; n < repeatTasks.length; n++) {
          if (repeatTasks[n].id == id) {
            present = true;
            break;
          }
        }
        if (!present) {
          if (taskComplete) {
            _numCompletedTasks--;
          }
          scheduledTasks.removeAt(i);
          if (i < _timedHead) {
            _timedHead--;
            _timedTail--;
          }
          else if (i <= _timedTail) {
            _timedTail--;
          }
        }
      }
    }
    // Compare each repeating task against list of scheduled tasks and insert
    // when necessary to avoid duplication
    _list = scheduledTasks; // Allows us to use the _addToList function
    for (int i = 0; i < repeatTasks.length; i++) {
      int id = repeatTasks[i].id;
      bool present = false;
      for (int n = 0; n < scheduledTasks.length; n++) {
        if (scheduledTasks[n].id == id) {
          present = true;
          break;
        }
      }
      if (!present) {
        _addToList(repeatTasks[i]);
      }
    }
    _numTasks = _list.length;
    // Update saved indices for each task in the newly constructed list
    _saveManager.updateIndices(date, _list, 0, _list.length - 1);
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

  void _addToList(TaskData data) {
    // Sort and insert the task data
    if (data.isScheduled) {
      // If the task is given a start time, then sort it based on that
      if (data.startTime != null) {
        _timeSort(data, data.startTime, (index) {
          return _list[index].startTime;
        });
      }
      // If not (only given an end time), then sort it based on the end time
      else {
        _timeSort(data, data.endTime, (index) {
          return _list[index].endTime;
        });
      }
    }
    else {
      _list.insert(_numTasks - 1, data);
    }
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
    // Now we can add the task to the list, but not if it is set to repeat on a
    // day other than today
    if (taskData.repeatDays[_listDate.weekday]) {
      _addToList(taskData);
    }
    _refreshListWidget.call();
    print("length");
    print(_list.length);
    print(_numTasks);

    // Add task data to database and update indices
    _saveManager.saveTask(taskData, index: _seek(taskData));
    _saveManager.updateIndices( // TODO: improve selection
        TaskData.dateToString(_listDate),
        _list,
        0,
        _list.length - 1
    );
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
  void removeTask(TaskData taskData) {
    int index = _seek(taskData);
    _list.removeAt(index);
    if (taskData.isSet) {
      _numTasks--;
    }

    _listWidgetState.removeItem(
        index,
        (context, animation) => _removeItemCallback(
            Task(this, animation, taskData, UniqueKey())
        )
    );

    // Save changes to database and update indices
    _saveManager.deleteTask(taskData);
    _saveManager.updateIndices(
        TaskData.dateToString(_listDate),
        _list,
        index,
        _list.length - 1
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