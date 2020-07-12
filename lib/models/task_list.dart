import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:listapp/widgets/list.dart';
import 'package:listapp/widgets/task.dart';
import 'package:listapp/models/task_data.dart';
import 'package:listapp/utils/save_manager.dart';

typedef _GetTimeFunction = TimeOfDay Function(int index);

class TaskList implements IListData<TaskData>, ITaskList {

  SaveManager _saveManager;
  Future<void> _initialized;
  List<TaskData> _list;
  // By subtracting one from the length, we can use a spacer widget as the last
  // element of the list
  int get _listLength => _list.length - 1;
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
  Function _scrollTo;

  TaskList({int initialTaskId}) {
    _list = List();
    _listDate = DateTime.now();
    _timedHead = 0;
    _timedTail = 0;
    _numTasks = 0;
    _numCompletedTasks = 0;

    _initialized = _init(initialTaskId);
    _listWidget = ListWidget(this, _initialized, _key);
    // TODO: clean up print statements
  }

  Future<void> _init(int initialTaskId) async {
    _saveManager = await SaveManager.getManager();
    await _loadData().then((value) {
      // The callback might be null if the list widget has not already been
      // built. Calling this (if the list widget has already been built) allows
      // us to rebuild it with the correct number of initial tasks
      int initialIndex = 0;
      if (initialTaskId != null) {
        for (int i = 0; i < _listLength; i++) {
          if (_list[i].id == initialTaskId) {
            initialIndex = i;
          }
        }
      }
      _scrollTo(initialIndex);
      _refreshListWidget?.call();
    });
    // Now that the list model has completed initialization, refresh the list
    // widget
  }

  Future<void> _loadData() async {
    // TODO: fix issue where a repeating task that is deleted gets reloaded
    // TODO: add public reload method
    // Load task data from database
    String date = TaskData.dateToString(_listDate);
    List<TaskData> scheduledTasks = await _saveManager.loadScheduledTasks(date);
    List<TaskData> repeatTasks = await _saveManager.loadRepeatTasks(date,
        _listDate.weekday - 1);
    // We must check each repeating task in the list of scheduled tasks
    // against the list of repeating tasks in order to account for tasks that
    // have been set to no longer repeat on this day of the week. These tasks
    // must then be removed from the scheduled tasks list
    for (int i = 0; i < scheduledTasks.length; i++) {
      print(scheduledTasks[i].text);
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
        // If instead of else if is used in the line below because one task can
        // be both the head and the tail
        if (!scheduledTasks[i].isScheduled &&
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
    }print("----------------------------------------");
    // Compare each repeating task against list of scheduled tasks and insert
    // when necessary to avoid duplication
    _list = scheduledTasks; // Allows us to use the _addToList function
    _numTasks = _list.length;
    for (int i = 0; i < _list.length; i++) {
      print(_list[i].text);
    }
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
        print("----------------------------------------");
        print(repeatTasks[i].text);
        _numTasks++;
        _addToList(repeatTasks[i]);
      }
    }
    print("list length is ${_list.length}");
    // Add the spacer widget to the end of the list
    _list.add(null);
    // Update saved indices for each task in the newly constructed list
    _saveManager.updateIndices(date, _list, 0, _listLength - 1);
  }

  int _seek(TaskData data) {
    for (int i = 0; i < _listLength; i++) {
      if (_list[i].id == data.id) {
        return i;
      }
    }
    String text = data.text;
    throw Exception("Item '$text' not found in list");
  }

  void _addToList(TaskData data, {int prevPos}) {
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
      if (prevPos != null && prevPos != _listLength) {
        _list.insert(prevPos, data);
      }
      else {
        _list.insert(_numTasks - 1, data);
      }
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
    print("head $_timedHead");
    print("tail $_timedTail");
    for (int i = _timedHead; i <= _timedTail; i++) {
      // If the end of the list has been reached
      if (i == _timedTail) {
        _list.insert(_timedTail, data);
        _timedTail++;
        return;
      }
      // Perform normal sort
      else {
        print("object bruh");
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
    _list.insert(
        _list.length - 1,
        taskData ?? TaskData(id: DateTime.now().millisecondsSinceEpoch)
    );
    _scrollTo(_listLength);
    _listWidgetState.insertItem(_listLength - 1);
    print("length of the list when added is ${_list.length}");
  }

  @override
  void submitTaskEdit(TaskData taskData) async {
    // Add task data to list
    // We need to remove the previous version of this task from the list, and
    // then have the list reflect this change. However, this only applies if the
    // previous version of this task had actually been set and this is not just
    // a newly added task. Otherwise, the previous (unedited) task would fall
    // outside the range of the list where its removal would have any impact on
    // the timed head or tail, or the number of tasks in the list
    int prevPos = _seek(taskData);
    bool prevSet = _list[prevPos].isSet;
    if (prevSet) {
      _numTasks--;
      if (prevPos < _timedHead) {
        _timedHead--;
        _timedTail--;
      }
      // If this was the last scheduled task (head == tail) then neither head
      // nor tail should change
      else if (prevPos <= _timedTail && _timedHead != _timedTail) {
        _timedTail--;
      }
    }
    _list.removeAt(prevPos);
    // Now we can add the task to the list, but not if it is set to repeat on a
    // day other than today or scheduled for the future
    if ((taskData.repeatDays[_listDate.weekday - 1] ||
        !taskData.repeatDays.contains(true)) &&
        TaskData.dateToString(taskData.date) ==
            TaskData.dateToString(_listDate)) {
      // Increment the number of tasks because we are adding it to the list
      _numTasks++;
      _addToList(taskData);
    }
    else {
      // In this case, since the task isn't added/re-added to the list, the
      // task must also be removed from this list widget to avoid having the
      // widget's builder try to build an incorrect number of items
      _listWidgetState.removeItem(
          prevPos,
              (context, animation) => _removeItemCallback(
              Task(this, animation, taskData, UniqueKey())
          )
      );
    }
    _refreshListWidget.call();
    print("length");
    print(_listLength);
    print(_numTasks);

    // Add task data to database and update indices
    int index;
    try {
      index = _seek(taskData);
    }
    on Exception {
      index = null;
    }
    await _saveManager.saveTask(taskData, index: index);
    // If the task ends up being removed from today's list, then in addition to
    // updating the indices of the list that the task is being sent to, we must
    // also update the indices of today's list to account for its removal
    if (prevSet && TaskData.dateToString(taskData.date) !=
        TaskData.dateToString(_listDate)) {
      _saveManager.updateIndices(
          TaskData.dateToString(_listDate),
          _list,
          0,
          _numTasks - 1
      );
    }
    _saveManager.updateIndices( // TODO: improve selection
        TaskData.dateToString(taskData.date),
        _list,
        0,
        _numTasks - 1
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
    _list.removeAt(pos);
    _list.insert(0, data);
    _listWidgetState.insertItem(0);

    // Save changes to database
    _saveManager.updateIndices(
        TaskData.dateToString(_listDate),
        _list,
        0,
        _numTasks - 1
    );
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
    _list.removeAt(pos);
    _listWidgetState.removeItem(
        pos,
            (context, animation) => _removeItemCallback(
            Task(this, animation, data, UniqueKey())
        )
    );
    _list.insert(_numTasks - 1, data);
    _listWidgetState.insertItem(_numTasks - 1);

    // Save changes to database
    _saveManager.updateIndices(
        TaskData.dateToString(_listDate),
        _list,
        0,
        _numTasks - 1
    );
  }

  @override
  void removeTask(TaskData taskData) {
    int index = _seek(taskData);
    if (index < _timedHead) {
      _timedHead--;
      _timedTail--;
    }
    else if (index <= _timedTail && _timedHead != _timedTail) {
      _timedTail--;
    }
    _list.removeAt(index);
    if (taskData.isSet) {
      _numTasks--;
      // Save changes to database and update indices
      _saveManager.deleteTask(taskData);
      if (_listLength > 0) {
        _saveManager.updateIndices(
            TaskData.dateToString(_listDate),
            _list,
            index > 0 ? index - 1 : 0, // Ensures no negative index is passed
            _numTasks - 1
        );
      }
    }

    _listWidgetState.removeItem(
        index,
        (context, animation) => _removeItemCallback(
            Task(this, animation, taskData, UniqueKey())
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

  @override
  void setScrollTo(Function function) {
    this._scrollTo = function;
  }

  @override
  int getNumItems() {
    return _numTasks;
  }

  @override
  int getListLength() {
    return _list.length;
  }

  // Returns a Task object already loaded with the data that was added to the
  // list
  @override
  Widget getItemWidget(int index, Animation<double> animation) {
    if (_list[index] != null) {
      return Task(this, animation, _list[index], UniqueKey());
    }
    else {
      return SizedBox(height: 72, width: 30);
    }
  }

  Future<void> getInitFuture() {
    return _initialized;
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

  void scrollTo(int index) {
    _scrollTo(index);
  }

  void lockTasks() {
    // TODO: for when the day is done
  }

}