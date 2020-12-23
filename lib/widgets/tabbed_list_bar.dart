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
  double _prevAnimValue = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = TabController(length: widget.tabItems.length, vsync: this);
    _tabs = List();
    _tabViews = List();
    for (int i = 0; i < widget.tabItems.length; i++) {
      TabItem item = widget.tabItems[i];
      _tabs.add(Tab(text: item.title, icon: item.icon));
      _tabViews.add(item.tabView);
      _controller.animation.addListener(() {
        int index = i;
        Animation animation = _controller.animation;
        if (animation.value > _prevAnimValue && // Swiping to the right
            (animation.value > index - 0.5 && animation.value <= index) &&
            _prevAnimValue < index - 0.5) { // Coming from the prev page
          widget.tabItems[i].onChangeCb?.call();
          _prevAnimValue = animation.value;
        }
        else if (animation.value < _prevAnimValue && // Swiping to the left
            (animation.value < index + 0.5 && animation.value >= index) &&
            _prevAnimValue > index + 0.5) { // Coming from the prev page
          widget.tabItems[i].onChangeCb?.call();
          _prevAnimValue = animation.value;
        }
      });
    }
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
              tabs: _tabs,
              labelColor: Theme.of(context).accentColor,
              unselectedLabelColor: Theme.of(context).textTheme.bodyText2.color
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
  final VoidCallback onChangeCb;

  TabItem({this.title, this.icon, @required this.tabView, this.onChangeCb}) {
    if (title == null && icon == null) {
      throw Exception("Either a title or an icon must be provided");
    }
    if (title != null && icon != null) {
      throw Exception("Only one of either a title or an icon can be provided");
    }
  }
}