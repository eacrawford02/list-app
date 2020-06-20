import 'package:flutter/material.dart';
import 'package:listapp/widgets/list.dart';
import 'package:listapp/widgets/task.dart';

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

  TaskList() {
    _list = List();
    _timedHead = 0;
    _timedTail = 0;
    _numTasks = 0;
    _numCompletedTasks = 0;

    _listWidget = ListWidget(this, _key, _loadTasks());
  }

  int _loadTasks() {
    // TODO: load task data from database
    for (int i = 0; i < 3; i++) {
      _list.add(TaskData(id: i));
      _numTasks++;
    }

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

  void addNewTask({TaskData taskData}) {
    _list.add(taskData ?? TaskData(id: DateTime.now().millisecondsSinceEpoch));
    _listWidgetState.insertItem(_list.length - 1);
  }

  @override
  void submitTaskEdit(TaskData taskData) {
    // Add task data to list
    

    // TODO: add task data to database
  }

  @override
  void moveToTop(TaskData data) {
    _list.removeAt(_seek(data));
    _list.insert(0, data);
    removeTask(data);
    _listWidgetState.insertItem(0);
  }

  @override
  void moveToBottom(TaskData data) {
    // TODO: implement moveToBottom
  }

  @override
  void removeTask(TaskData data) {
    int index = _seek(data);
    _list.removeAt(index);

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