import 'package:flutter/material.dart';
import 'package:listapp/models/task_data.dart';
import 'package:listapp/widgets/item_list.dart';
import 'package:listapp/widgets/list_item.dart';
import 'package:listapp/pages/home_page.dart';
import 'package:listapp/models/task.dart';

class TaskList extends IListModel<Data> {
  Future<void> _initialized;
  ValueChanged<bool> _onHomeDataChangeCb;
  AnimatedListState get _listWidgetState => key.currentState;
  List<Task> _list;
  int get _listLength => _list.length; // TODO: subtract one
  DateTime _listDate;
  int _timedHead = 0; // Inclusive
  int _timedTail = 0; // Inclusive
  int _numTasks = 0;
  int _numCompletedTasks = 0;
  bool _isLocked = false;

  TaskList(this._listDate, this._onHomeDataChangeCb,
      {int initialTaskId, GlobalKey<AnimatedListState> key, Data pageData})
      : super(key: key, pageData: pageData) {
    // bruh
    _list = List();
  }

  void reload() {
    // TODO: implement
  }

  void addTask() {
    // TODO: implement
    _list.insert(
        _listLength,
        Task(
          ListItemData(),
          this,
          TaskData(
            id: DateTime.now().millisecondsSinceEpoch,
            date: _listDate
          )
        )
    );
    _listWidgetState.insertItem(_listLength - 1);
  }

  void onTaskCheckEvent(bool prevValue, bool newValue) {
    if (!prevValue && newValue) {
      _numCompletedTasks++;
    }
    else if (prevValue && !newValue) {
      _numCompletedTasks--;
    }
    _onHomeDataChangeCb(true);
  }

  void removeTask(Task task) {
    // TODO: implement
  }

  void scrollToTop() {
    // TODO: implement
  }

  void scrollToBottom() {
    // TODO: implement
  }

  void moveToTop(Task task) {
    // TODO: implement
  }

  void moveToBottom(Task task) {
    // TODO: implement
  }

  bool isLocked() => _isLocked;

  @override
  Future getInitFuture() {
    _initialized = Future((){}); // TODO: delete
    return _initialized;
  }

  @override
  Widget getItemWidget(int index, Animation<double> animation) {
    if (_list[index] != null) {
      return ListItem(UniqueKey(), _list[index].listItemData, animation);
    }
    else {
      return SizedBox(height: 72, width: 30);
    }
  }

  @override
  int getListLength() {
    return _list.length;
  }
}