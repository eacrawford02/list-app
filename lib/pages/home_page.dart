import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin{

  final String title = "List";
  List<IconButton> _buttons;
  List<Tab> _tabs;
  List<Widget> _tabViews;
  TabController _tabController;

  @override
  void initState() {
    super.initState();

    _buttons = [
      // TODO: add icon buttons
    ];

    _tabs = [
      // TODO: add tabs
    ];

    _tabViews = [
      // TODO: add tab views
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
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
                tabs: _tabs,
                controller: _tabController,
              ),
            )
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _tabViews,
        ),
      ),
    );
  }
}