import 'package:flutter/material.dart';
import 'package:listapp/utils/utils.dart';
import 'package:listapp/widgets/item_list.dart';
import 'package:listapp/widgets/list_item.dart';
import 'package:listapp/pages/home_page.dart';
import 'package:listapp/models/task_list_data.dart';
import 'package:listapp/models/task.dart';
import 'package:listapp/models/task_data.dart';

typedef _GetTimeFunction = TimeOfDay Function(int index);

class TaskList extends IListModel<Data> {
  TaskListData _data;
  Future<void> _initialized;
  ValueChanged<bool> _onHomeDataChangeCb;
  AnimatedListState get _listWidgetState => key.currentState;
  List<TaskListItem> _list;
  int get _listLength => _list.length - 1;
  DateTime _listDate;
  int _timedHead = 0; // Inclusive
  int _timedTail = 0; // Inclusive
  int _numTasks = 0;
  int _numCompletedTasks = 0;

  TaskList(this._listDate, this._onHomeDataChangeCb,
      {int initialTaskId, GlobalKey<AnimatedListState> key, Data pageData})
      : super(key: key, pageData: pageData) {
    _data = TaskListData(_listDate);
    _list = List();
    _initialized = _init(initialTaskId);
  }

  Future<void> _init(int initialTaskId) async {
    _timedHead = 0;
    _timedTail = 0;
    _numTasks = 0;
    _numCompletedTasks = 0;
    await _data.loadListData();
    _list = await _data.loadTasks();
    // Set fields and organize list such that all scheduled tasks are in
    // sequence
    bool isHeadFound = false;
    for (int i = 0; i < _list.length; i++) {
      TaskListItem item = _list[i];
      if (item.isDeleted) {
        _list.removeAt(i);
        i--;
        continue;
      }
      Task(item.listItemData, this, item.data); // Create Task object
      _numTasks++;
      if (item.data.isDone) {
        _numCompletedTasks++;
      }
      // Set head and tail values
      if (i != 0) {
        TaskListItem prevItem = _list[i - 1];
        if (item.data.isScheduled && !prevItem.data.isScheduled &&
            !isHeadFound) {
          // Set initial head and tail values
          _timedHead = i;
          _timedTail = i;
          isHeadFound = true;
        }
        else if (item.data.isScheduled && isHeadFound) {
          // By using the _addToList method, each scheduled task found in the
          // list is automatically sorted
          _list.removeAt(i);
          _addToList(item);
        }
      }
      // Otherwise just leave the default values of 0 and 0
    }
    // Add the spacer widget to the end of the list
    _list.add(null);
    // Update saved indices for each task in the newly constructed list
    _data.updateIndices(Utils.dateToString(_listDate), _list, _listLength);
    // Scroll to the initial task
    pageData.scrollIndex = _seek(null, taskId: initialTaskId);
    pageData.shouldScroll = true;
    _onHomeDataChangeCb(true);
  }

  void _addToList(TaskListItem item, {int prevPos}) {
    // Sort and insert the task data
    if (item.data.isScheduled) {
      // If the task is given a start time, then sort it based on that
      if (item.data.startTime != null) {
        _timeSort(item, item.data.startTime, (index) {
          return _list[index].data.startTime;
        });
      }
      // If not (only given an end time), then sort it based on the end time
      else {
        _timeSort(item, item.data.endTime, (index) {
          return _list[index].data.endTime;
        });
      }
    }
    else {
      if (prevPos != null && prevPos != _listLength) {
        _list.insert(prevPos, item);
      }
      else {
        _list.insert(_numTasks - 1, item);
      }
    }
  }

  void _timeSort(TaskListItem item, TimeOfDay taskTime,
      _GetTimeFunction getTime) {
    int timeStamp = Utils.createTimeStamp(taskTime.hour, taskTime.minute);
    // If first scheduled task in the list
    if (_timedHead == _timedTail && !(_list[_timedHead]?.data?.isScheduled ?? false)) {
      _list.insert(_timedHead, item);
      return;
    }
    for (int i = _timedHead; i <= _timedTail; i++) {
      // Perform sort
      int indexTimeStamp = Utils.createTimeStamp(
          getTime(i).hour,
          getTime(i).minute
      );
      if (timeStamp < indexTimeStamp) {
        _list.insert(i, item);
        _timedTail++;
        return;
      }
    }
    // If the end of the list has been reach, insert at the last element. Note
    // that it's only possible to insert at _timedTail + 1 because of the
    // presence of an empty element at the end of the list
    _list.insert(_timedTail + 1, item);
    _timedTail++;
    return;
  }

  int _seek(TaskData data, {int taskId}) {
    if (data == null && taskId == null)
      return 0;
    for (int i = 0; i < _listLength; i++) {
      if (_list[i].data.id == data?.id ?? taskId) {
        return i;
      }
    }
    String text = data?.text ?? taskId;
    throw Exception("Item '$text' not found in list");
  }

  void reload({DateTime newDate}) {
    if (newDate != null) {
      _listDate = newDate;
      _data = TaskListData(newDate);
    }
    _initialized = _init(null);
    pageData.scrollIndex = 0;
    pageData.shouldScroll  = true;
    _onHomeDataChangeCb(true);
  }

  void addTask() {
    TaskData data = TaskData(
      id: DateTime.now().millisecondsSinceEpoch,
      date: _listDate
    );
    ListItemData listItemData = ListItemData();
    Task(listItemData, this, data);

    _list.insert(
        _listLength,
        TaskListItem(
          data: data,
          listItemData: listItemData
        )
    );
    _listWidgetState.insertItem(_listLength - 1);
    pageData.scrollIndex = _listLength;
    pageData.shouldScroll = true;
    _onHomeDataChangeCb(true);
  }

  void onTaskEditEvent(TaskData taskData) async {
    // Add task data to list
    // We need to remove the previous version of this task from the list, and
    // then have the list reflect this change. However, this only applies if the
    // previous version of this task had actually been set and this is not just
    // a newly added task. Otherwise, the previous (unedited) task would fall
    // outside the range of the list where its removal would have any impact on
    // the timed head or tail, or the number of tasks in the list
    int prevPos = _seek(taskData);
    TaskListItem prevItem = _list[prevPos];
    bool prevSet = prevItem.data.isSet;
    DateTime prevDate = prevItem.data.date;
    prevItem.data = taskData;
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
        Utils.dateToString(taskData.date) ==
            Utils.dateToString(_listDate)) {
      // Increment the number of tasks because we are adding it to the list
      _numTasks++;
      _addToList(prevItem, prevPos: prevPos);
    }
    else {
      // In this case, since the task isn't added/re-added to the list, the
      // task must also be removed from this list widget to avoid having the
      // widget's builder try to build an incorrect number of items
      _listWidgetState.removeItem(
        prevPos,
        (context, animation) =>
            ListItem(UniqueKey(), prevItem.listItemData, animation)
      );
    }

    // Add task data to database and update indices
    int index;
    try {
      // Only get the index for a task still scheduled for the same day; we
      // don't want to provide an index that is out of bounds for a future date
      index = Utils.dateToString(taskData.date) ==
          Utils.dateToString(prevDate) ? _seek(taskData) : null;
    }
    on Exception {
      index = null;
    }
    await _data.saveTask(prevItem, index: index);
    // If the task ends up being removed from today's list, then in addition to
    // updating the indices of the list that the task is being sent to, we must
    // also update the indices of today's list to account for its removal
    if (prevSet && Utils.dateToString(taskData.date) !=
        Utils.dateToString(_listDate)) {
      _data.updateIndices(Utils.dateToString(_listDate), _list, _numTasks);
    }
    // Notify parent class of edit
    _onHomeDataChangeCb(true);
  }

  void onTaskCheckEvent(TaskData taskData, bool prevValue, bool newValue) {
    if (!prevValue && newValue) {
      _numCompletedTasks++;
    }
    else if (prevValue && !newValue) {
      _numCompletedTasks--;
    }
    int index = _seek(taskData);
    _data.saveTask(_list[index], index: index);
    _onHomeDataChangeCb(true);
  }

  void moveToTop(TaskData taskData) {
    int index = _seek(taskData);
    TaskListItem item = _list[index];
    if (index >= _timedHead && index <= _timedTail) {
      throw Exception("Can't move scheduled task to the top");
    }
    else if (index >= _timedTail) {
      _timedHead++;
      _timedTail++;
    }
    _list.removeAt(index);
    _listWidgetState.removeItem(
      index,
      (context, animation) =>
          ListItem(UniqueKey(), item.listItemData, animation)
    );
    _list.insert(0, item);
    _listWidgetState.insertItem(0);
    // Save changes to database
    _data.updateIndices(Utils.dateToString(_listDate), _list, _numTasks);
  }

  void moveToBottom(TaskData taskData) {
    int index = _seek(taskData);
    TaskListItem item = _list[index];
    if (index >= _timedHead && index <= _timedTail) {
      throw Exception("Can't move scheduled task to the bottom");
    }
    else if (index < _timedHead) {
      _timedHead--;
      _timedTail--;
    }
    _list.removeAt(index);
    _listWidgetState.removeItem(
      index,
      (context, animation) =>
          ListItem(UniqueKey(), item.listItemData, animation)
    );
    _list.insert(_numTasks - 1, item);
    _listWidgetState.insertItem(_numTasks - 1);
    // Save changes to database
    _data.updateIndices(Utils.dateToString(_listDate), _list, _numTasks);
  }

  void removeTask(TaskData taskData) {
    int index = _seek(taskData);
    TaskListItem item = _list[index];
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
      _data.deleteTask(item);
      if (_listLength > 0) {
        _data.updateIndices(Utils.dateToString(_listDate), _list, _numTasks);
      }
    }
    _listWidgetState.removeItem(
      index,
      (context, animation) =>
          ListItem(UniqueKey(), item.listItemData, animation)
    );
    _onHomeDataChangeCb(true);
  }

  void scrollToTop() {
    pageData.scrollIndex = 0;
    pageData.shouldScroll = true;
    _onHomeDataChangeCb(true);
  }

  void scrollToBottom() {
    pageData.scrollIndex = _listLength;
    pageData.shouldScroll = true;
    _onHomeDataChangeCb(true);
  }

  DateTime getListDate() => _listDate;

  bool isLocked() => _data.isLocked;

  int getNumTasks() => _numTasks;

  int getNumCompletedTasks() => _numCompletedTasks;

  void lockTasks() {
    _data.isLocked = true;
    // Remove all unset tasks
    int length = _listLength;
    for (int i = _numTasks; i < length; i++) {
      TaskListItem item = _list[_numTasks];
      _list.removeAt(_numTasks);
      _listWidgetState.removeItem(
        _numTasks,
        (context, animation) =>
            ListItem(UniqueKey(), item.listItemData, animation)
      );
    }
    _data.saveListData(_listDate);
    _onHomeDataChangeCb(true);
  }

  @override
  Future getInitFuture() {
    return _initialized;
  }

  @override
  Widget getItemWidget(int index, Animation<double> animation) {
    if (_list[index] == null) {
      return SizedBox(height: 72, width: 30);
    }
    return ListItem(UniqueKey(), _list[index].listItemData, animation);
  }

  @override
  int getListLength() {
    return _list.length;
  }
}

class TaskListItem {
  TaskData data;

  ListItemData listItemData;

  bool isDeleted;

  // TODO: bool isWastedTime;

  TaskListItem({this.data, this.listItemData, this.isDeleted : false});
}