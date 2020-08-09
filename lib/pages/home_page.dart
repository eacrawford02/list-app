import 'package:flutter/material.dart';
import 'package:listapp/widgets/bottom_action_bar.dart';
import 'package:listapp/widgets/tabbed_list_bar.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {

  final String title = "List";
  Data _data = Data();

  void onDataChange(bool shouldUpdate) {
    setState(() {
      _data.shouldUpdate = shouldUpdate;
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
              title: title,
              actionButtons: <IconButton>[ // Delete contents
                IconButton(icon: Icon(Icons.ac_unit), onPressed: null)
              ],
              tabItems: <TabItem>[ // Delete contents
                TabItem(
                  title: "page 1",
                  tabView: Container(
                    decoration: BoxDecoration(color: Colors.green),
                  )
                ),
                TabItem(
                  title: "page 2",
                  tabView: Container(
                    decoration: BoxDecoration(color: Colors.blue)
                  )
                )
              ]
            ),
            BottomActionBar(
              actionWidgets: <Widget>[ // Delete contents
                FloatingActionButton(
                  onPressed: null,
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

enum PageEvents {
  SCROLL_TOP, SCROLL_BOTTOM, RELOAD, LOCK_LIST, ADD_TASK
}

class Data {
  bool shouldUpdate = false;
  List<PageEvents> events = List();

  Widget currentTab;
}