import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:listapp/models/action_widget_collection.dart';
import 'package:listapp/models/tab_collection.dart';
import 'package:listapp/models/task_list.dart';
import 'package:listapp/widgets/bottom_action_bar.dart';
import 'package:listapp/widgets/task.dart';

class HomePage extends StatefulWidget {

  final String notificationTaskId;

  HomePage({this.notificationTaskId});

  @override
  _HomePageState createState() => _HomePageState(notificationTaskId);
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin{

  final String _notificationTaskId;
  final String title = "List";
  List<IconButton> get _buttons => [
    IconButton(
        icon: Icon(Icons.keyboard_arrow_up),
        onPressed: () => _tabbedTaskList.scrollTo(0)
    ),
    IconButton(
        icon: Icon(Icons.keyboard_arrow_down),
        onPressed: () => _tabbedTaskList.scrollTo(
            _tabbedTaskList.getListLength() - 1
        )
    ),
    IconButton(
        icon: Icon(Icons.refresh),
        onPressed: () => _tabbedTaskList.reload()
    )
  ];
  ActionWidgetCollection _actionBar;
  TabCollection _tabCollection;
  TaskList _currentTasks;
  TaskList _futureTasks;
  TaskList _tabbedTaskList;

  _HomePageState(this._notificationTaskId) {
    _init();
  }

  void _init() {
    // Set list callbacks
    ListEventCallback _listEventCallback = (ListEvents event) async {
      switch(event) {
        case ListEvents.EDIT_TASK:
          setState(() {});
          break;
        case ListEvents.REMOVE_TASK:
          setState(() {});
          break;
      }
    };

    // Add tabbed screens
    _tabCollection = TabCollection(this);
    _currentTasks = TaskList(
        DateTime.now(),
        initialTaskId: _notificationTaskId != null ?
        int.parse(_notificationTaskId) : null,
        eventCallback: _listEventCallback
    );
    _tabCollection.addTab(
        title: "Today's Tasks",
        view: _currentTasks.getLayout()
    );
    _futureTasks = TaskList(
        DateTime.now().add(Duration(days: 1)),
        eventCallback: _listEventCallback
    );
    _tabCollection.addTab(
        title: "Future Tasks",
        view: _futureTasks.getLayout()
    );
    _tabbedTaskList = _currentTasks;

    // Add bottom action bar
    _actionBar = ActionWidgetCollection();
    // TODO: fix issue with futures
    var actionBarDoneButton = FutureBuilder(
        future: _currentTasks.getInitFuture(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_currentTasks.getNumTasks() == 0 ||
                _currentTasks.isLocked()) {
              return FloatingActionButton(
                  mini: true,
                  elevation: 0,
                  child: Icon(Icons.done),
                  onPressed: null
              );
            }
            else {
              return FloatingActionButton(
                  mini: true,
                  child: Icon(Icons.done),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                                "Done For The Day?",
                                textAlign: TextAlign.center
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Divider()
                                ),
                                Text(
                                  "This action will lock all tasks",
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                            actions: <Widget>[
                              FlatButton(
                                child: Text("Cancel"),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              FlatButton(
                                  child: Text("Save"),
                                  onPressed: () {
                                    setState(() {
                                      _currentTasks.lockTasks();
                                    });
                                    Navigator.of(context).pop();
                                  }
                              )
                            ],
                          );
                        }
                    );
                  }
              );
            }
          }
          else {
            return FloatingActionButton(
                mini: true,
                elevation: 0,
                child: Icon(Icons.done),
                onPressed: null
            );
          }
        }
    );
    var actionBarAddButton = FutureBuilder(
        future: _tabbedTaskList.getInitFuture(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return FloatingActionButton(
                child: Icon(Icons.add),
                elevation: _tabbedTaskList.isLocked() ? 0 : null,
                onPressed: !_tabbedTaskList.isLocked() ?
                  _tabbedTaskList.addNewTask : null
            );
          }
          else {
            return FloatingActionButton(
              child: Icon(Icons.add),
              elevation: 0,
              onPressed: null
            );
          }
        }
    );
    var actionBarPercentage = FutureBuilder(
      future: _currentTasks.getInitFuture(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FloatingActionButton(
            mini: true,
            child: Text(
                "${_currentTasks.getNumTasks() > 0 ?
                  (_currentTasks.getNumCompletedTasks() /
                    _currentTasks.getNumTasks()) * 100 ~/ 1: 0}%",
              textScaleFactor: 0.8,
            ),
            onPressed: null
          );
        }
        else {
          return FloatingActionButton(
            mini: true,
            elevation: 0,
            child: Text("0%", textScaleFactor: 0.8),
            onPressed: null
          );
        }
      }
    );
    var actionBarListDate = FloatingActionButton(
      mini: true,
      child: Icon(Icons.today),
      onPressed: () async {
        DateTime newDate = await showDatePicker(
            context: context,
            initialDate: _futureTasks.getListDate(),
            firstDate: DateTime.now().add(Duration(days: 1)),
            lastDate: DateTime.now().add(Duration(days: 36500))
        );
        setState(() {
          if (newDate != null) {
            Widget prevView = _futureTasks.getLayout();
            _futureTasks = TaskList(newDate, eventCallback: _listEventCallback);
            _tabCollection.updateTabView(prevView, _futureTasks.getLayout());
            _tabbedTaskList = _futureTasks;
          }
        });
      }
    );
    _actionBar.addAction(
        "done button",
        actionBarDoneButton
    );
    _actionBar.addAction(
        "add button",
        actionBarAddButton
    );
    _actionBar.addAction(
      "percentage button",
      actionBarPercentage
    );


    // Set tab transitions
    _tabCollection.addTabChangeCallback(
        _futureTasks.getLayout(),
            () {
          setState(() {
            _tabbedTaskList = _futureTasks;
            _actionBar.setAction("done button", Container());
            _actionBar.setAction(
                "add button",
                FutureBuilder(
                    future: _futureTasks.getInitFuture(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return FloatingActionButton(
                            child: Icon(Icons.add),
                            onPressed: _futureTasks.addNewTask
                        );
                      }
                      else {
                        return FloatingActionButton(onPressed: null);
                      }
                    }
                )
            );
            _actionBar.setAction("percentage button", actionBarListDate);
          });
        }
    );
    _tabCollection.addTabChangeCallback(
        _currentTasks.getLayout(),
            () {
          setState(() {
            _tabbedTaskList = _currentTasks;
            _actionBar.setAction("done button", actionBarDoneButton);
            _actionBar.setAction("add button", actionBarAddButton);
            _actionBar.setAction("percentage button", actionBarPercentage);
          });
        }
    );
    _tabCollection.setController();
  }

  @override
  void initState() {
    super.initState();

    // Set end of day timer
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));
    DateTime startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    Duration diff = tomorrow.difference(startOfDay);
    Timer(
      diff,
      () {
        setState(() {
          _init();
        });
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      body: Stack(
        children: <Widget>[
          NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    title: Text("$title"),
                    actions: _buttons,
                    floating: false,
                    pinned: true,
                    snap: false,
                    forceElevated: innerBoxIsScrolled,
                    bottom: TabBar(
                      tabs: _tabCollection.getTabs(),
                      controller: _tabCollection.getController(),
                    ),
                  )
                ];
              },
              // body parameter takes a Widget object, not a sliver (which is
              // why we use a AnimatedList instead of a SliverAnimatedList) in
              // the ListWidget class
              body: _tabCollection.getTabLayout()
          ),
          _actionBar.getLayout()
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _tabCollection.getController().dispose();
  }
}