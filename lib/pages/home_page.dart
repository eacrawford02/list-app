import 'dart:async';
import 'package:intl/intl.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:listapp/models/task_list.dart';
import 'package:listapp/models/task_list_data.dart';
import 'package:listapp/models/task.dart';
import 'package:listapp/widgets/bottom_action_bar.dart';
import 'package:listapp/widgets/tabbed_list_bar.dart';
import 'package:listapp/widgets/item_list.dart';

class HomePage extends StatefulWidget {

  final String notificationTaskId;

  HomePage({this.notificationTaskId});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  final Data _data = Data();
  GlobalKey<AnimatedListState> _currentTasksKey = GlobalKey();
  GlobalKey<AnimatedListState> _futureTasksKey = GlobalKey();
  TaskList _currentTasks;
  TaskList _futureTasks;

  static void scheduleDailyNotifications() async {
    TaskListData listData = TaskListData(DateTime.now());
    List<TaskListItem> taskList = await listData.loadTasks();
    taskList.forEach((element) {
      Task(element.listItemData, null, element.data);
    });
  }

  void _init() {
    _currentTasks = TaskList(
        DateTime.now(),
        onDataChange,
        key: _currentTasksKey,
        pageData: _data,
        initialTaskId: widget.notificationTaskId != null ?
        int.parse(widget.notificationTaskId) : null
    );
    _futureTasks = TaskList(
        DateTime.now().add(Duration(days: 1)),
        onDataChange,
        key: _futureTasksKey,
        pageData: _data
    );
    _data.tabbedTasks = _currentTasks;
  }

  void onDataChange(bool shouldUpdate) {
    setState(() {
      _data.shouldUpdate = shouldUpdate;
    });
  }

  @override
  void initState() {
    super.initState();

    _init();
    // Set end of day timer (for if the app is open)
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));
    DateTime startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    Duration diff = tomorrow.difference(startOfDay).abs();
    Timer(
      diff,
      () {
        setState(() {
          _init();
        });
      }
    );
    // Set end of day timer (for if the app is closed) to schedule future
    // notifications
    AndroidAlarmManager.initialize().then((value) {
      AndroidAlarmManager.periodic(
          Duration(days: 1),
          0,
          scheduleDailyNotifications,
          startAt: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().add(Duration(days: 1)).day,
              0,
              1 // TODO: try changing this (minutes) to zero
          ),
          exact: true,
          rescheduleOnReboot: true
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomePageData(
      data: _data,
      onDataChangeCb: onDataChange,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            TabbedListBar(
              title: "List  -  ${
                  DateFormat.MMMEd().format(_data.tabbedTasks.getListDate())
              }",
              actionButtons: <IconButton>[
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up),
                  onPressed: () => _data.tabbedTasks.scrollToTop()
                ),
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_down),
                  onPressed: () => _data.tabbedTasks.scrollToBottom()
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => _data.tabbedTasks.reload()
                )
              ],
              tabItems: <TabItem>[
                TabItem(
                  title: "Today's Tasks",
                  tabView: ItemList(
                    listKey: _currentTasksKey,
                    listModel: _currentTasks,
                    bottomOffset: 66,
                    getPageData: (BuildContext context) =>
                        HomePageData.of(context).data
                  ),
                  onChangeCb: () {
                    _data.tabbedTasks = _currentTasks;
                    onDataChange(true);
                  }
                ),
                TabItem(
                  title: "Future Tasks",
                  tabView: ItemList(
                    listKey: _futureTasksKey,
                    listModel: _futureTasks,
                    bottomOffset: 66,
                    getPageData: (BuildContext context) =>
                        HomePageData.of(context).data,
                  ),
                  onChangeCb: () {
                    _data.tabbedTasks = _futureTasks;
                    onDataChange(true);
                  }
                )
              ]
            ),
            BottomActionBar(
              actionWidgets: <Widget>[
                _data.tabbedTasks == _currentTasks ? FloatingActionButton(
                  mini: true,
                  elevation: (_currentTasks.getNumTasks() == 0 ||
                      _currentTasks.isLocked()) ? 0 : null,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.done),
                  onPressed: (_currentTasks.getNumTasks() == 0 ||
                      _currentTasks.isLocked()) ? null : () {
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
                            TextButton(
                              child: Text("Cancel"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            FlatButton(
                                child: Text("Save"),
                                onPressed: () {
                                  _currentTasks.lockTasks();
                                  Navigator.of(context).pop();
                                  onDataChange(true); // TODO: not updating tasks
                                }
                            )
                          ],
                        );
                      }
                    );
                  }
                ) : Container(),
                FloatingActionButton(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).accentColor,
                  child: Icon(Icons.add),
                  elevation: _data.tabbedTasks.isLocked() ? 0 : null,
                  onPressed: !_data.tabbedTasks.isLocked() ?
                      _data.tabbedTasks.addTask : null
                ),
                _data.tabbedTasks == _currentTasks ? FloatingActionButton(
                  mini: true,
                  foregroundColor: Colors.white,
                  child: Text(
                    "${_currentTasks.getNumTasks() > 0 ?
                    (_currentTasks.getNumCompletedTasks() /
                        _currentTasks.getNumTasks()) * 100 ~/ 1: 0}%",
                    textScaleFactor: 0.8,
                  ),
                  onPressed: null
                ) : FloatingActionButton(
                  mini: true,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.today),
                  onPressed: () async {
                    DateTime newDate = await showDatePicker(
                      context: context,
                      initialDate: _futureTasks.getListDate(),
                      firstDate: DateTime.now().add(Duration(days: 1)),
                      lastDate: DateTime.now().add(Duration(days: 36500))
                    );
                    if (newDate != null) {
                      _futureTasks.reload(newDate: newDate);
                      onDataChange(true);
                    }
                  }
                )
              ],
            )
          ]
        )
      )
    );
  }
}

class HomePageData extends InheritedWidget {
  final Data data;
  // True if data was changed; false otherwise
  final ValueChanged<bool> onDataChangeCb;

  HomePageData({this.data, this.onDataChangeCb, Widget child})
      : super(child: child);

  // Don't call from initState methods
  static HomePageData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType();

  @override
  bool updateShouldNotify(HomePageData oldWidget) {
    bool b = data.shouldUpdate;
    data.shouldUpdate = false;
    return b;
  }
}

class Data extends ListPageData {
  bool shouldUpdate = false;

  TaskList tabbedTasks; // The task list under the currently selected tab
}