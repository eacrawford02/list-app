import 'package:flutter/material.dart';

class TabbedListBar extends StatefulWidget {
  final String title;
  final List<IconButton> actionButtons;
  final List<TabItem> tabItems;

  TabbedListBar({this.title, this.actionButtons, this.tabItems});

  @override
  TabbedListBarState createState() => TabbedListBarState();
}

class TabbedListBarState extends State<TabbedListBar>
    with SingleTickerProviderStateMixin{
  TabController _controller;
  List<Widget> _tabs;
  List<Widget> _tabViews;

  @override
  void initState() {
    super.initState();

    _controller = TabController(length: widget.tabItems.length, vsync: this);
    widget.tabItems.forEach((element) {
      if (element.title != null) {
        _tabs.add(Text(element.title));
      }
      else {
        _tabs.add(element.icon);
      }
      _tabViews.add(element.tabView);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            title: Text("${widget.title}"),
            actions: widget.actionButtons,
            floating: false,
            pinned: true,
            snap: false,
            forceElevated: innerBoxIsScrolled,
            bottom: TabBar(
              controller: _controller,
              tabs: _tabs
            )
          )
        ];
      },
      body: TabBarView(
        controller: _controller,
        children: _tabViews
      )
    );
  }
}

class TabItem {
  final String title;
  final Icon icon;
  final Widget tabView;

  TabItem({this.title, this.icon, @required this.tabView}) {
    if (title == null && icon == null) {
      throw Exception("Either a title or an icon must be provided");
    }
    if (title != null && icon != null) {
      throw Exception("Only one of either a title or an icon can be provided");
    }
  }
}