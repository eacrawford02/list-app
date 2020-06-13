import 'package:flutter/material.dart';
import 'package:listapp/widgets/list.dart';
import 'package:listapp/widgets/task.dart';

class TaskList implements IListData<TaskData> {

  List<TaskData> _list;
  int _timedHead;
  int _timedTail;
  int _numTasks;
  int _numCompletedTasks;
  // TODO: _wastedTime;
  Widget _listWidget;
  SliverAnimatedListState _listWidgetState;

  TaskList() {
    _list = List();
    _timedHead = 0;
    _timedTail = 0;
    _numTasks = 0;
    _numCompletedTasks = 0;
    
    GlobalKey<SliverAnimatedListState> k = GlobalKey<SliverAnimatedListState>();
    _listWidget = ListWidget(this, k, _loadTasks());
    _listWidgetState = k.currentState;
  }

  int _loadTasks() {
    // TODO: load task data from database
    for (int i = 0; i < 3; i++) {
      _list.add(TaskData());
      _numTasks++;
    }

    return _numTasks;
  }

  void addNewTask(TaskData taskData) {
    _list.add(taskData);
    _listWidgetState.insertItem(_list.length - 1);
  }

  void submitTaskEdit(TaskData taskData) {

  }

  @override
  TaskData getItemData(int index) {
    return _list[index];
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