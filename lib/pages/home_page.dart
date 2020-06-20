import 'package:flutter/material.dart';
import 'package:listapp/models/action_widget_collection.dart';
import 'package:listapp/models/tab_collection.dart';
import 'package:listapp/models/task_list.dart';
import 'package:listapp/widgets/bottom_action_bar.dart';
import 'package:listapp/widgets/task.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin{

  final String title = "List";
  List<IconButton> _buttons;
  ActionWidgetCollection _actionBar;
  TabCollection _tabCollection;

  @override
  void initState() {
    super.initState();

    _buttons = [
      // TODO: add icon buttons
    ];

    // TODO: replace/fix all this stuff
    TaskList currentTasks = TaskList();


    _actionBar = ActionWidgetCollection();
    _actionBar.addAction("button", FloatingActionButton(
        onPressed: currentTasks.addNewTask
    ));

    Container view2 = Container(color: Colors.green);

    _tabCollection = TabCollection(this);
    _tabCollection.addTab(title: "Current Tasks", view: currentTasks.getLayout());
    _tabCollection.addTab(title: "Future Tasks", view: view2);
    _tabCollection.setController();

    // TODO: set controller
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
    // TODO: dispose controller
    super.dispose();
  }
}