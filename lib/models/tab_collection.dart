import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class TabCollection {

  final TickerProvider _vsync;
  List<Tab> _tabs;
  List<Widget> _tabViews;
  Widget _floatingWidget; // TODO: remove
  Map<Widget, Function> _callbacks;
  TabController _tabController;

  TabCollection(this._vsync) {
    _tabs = List();
    _tabViews = List();
    _callbacks = Map();
  }

  void addTab({String title, Icon icon, @required Widget view}) {
    if (title == null && icon == null)
      return;
    _tabs.add(Tab(text: title, icon: icon));
    _tabViews.add(view);
  }

  void addTabChangeCallback(Widget targetView, Function callback) {
    _callbacks[targetView] = callback;
  }

  void setFloatingWidget(Widget floatingWidget) {
    _floatingWidget = floatingWidget;
  }

  void setController() {
    _tabController = TabController(length: _tabs.length, vsync: _vsync);
    _tabController.addListener(() {
      Widget targetView = _tabViews[_tabController.index];
      Function callback = _callbacks[targetView];
      callback?.call();
    });
  }

  TabController getController() {
    return _tabController;
  }

  List<Tab> getTabs() {
    return _tabs;
  }

  Widget getTabLayout() {
    return Stack(
      children: <Widget>[
        TabBarView(
          controller: _tabController,
          children: _tabViews,
        ),
        _floatingWidget
      ],
    );
  }

}