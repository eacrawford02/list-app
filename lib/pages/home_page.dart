import 'package:flutter/material.dart';
import 'package:listapp/models/tab_collection.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin{

  final String title = "List";
  List<IconButton> _buttons;
  TabCollection _tabCollection;

  @override
  void initState() {
    super.initState();

    _buttons = [
      // TODO: add icon buttons
    ];

    Container floatingWidget = Container(
      color: Color.fromRGBO(1, 0, 0, 0.5),
      alignment: Alignment.bottomCenter,
      height: 20,
      child: FloatingActionButton(onPressed: null),
    );
    Container view1 = Container(color: Colors.blue);
    Container view2 = Container(color: Colors.green);

    _tabCollection = TabCollection(this);
    _tabCollection.setFloatingWidget(floatingWidget);
    _tabCollection.addTab(title: "Current Tasks", view: view1);
    _tabCollection.addTab(title: "Future Tasks", view: view2);
    _tabCollection.addTabChangeCallback(view2, () {
      floatingWidget = Container(
        color: Color.fromRGBO(1, 0, 0, 0.5),
        alignment: Alignment.bottomCenter,
        height: 40,
      );
    });
    _tabCollection.setController();

    // TODO: set controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      // TODO: wrap in stack
      body: NestedScrollView(
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
        body: _tabCollection.getTabLayout()
      ),
    );
  }

  @override
  void dispose() {
    // TODO: dispose controller
    super.dispose();
  }
}