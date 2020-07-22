import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

class TabCollection {

  final TickerProvider _vsync;
  List<Tab> _tabs;
  List<Widget> _tabViews;
  Map<Widget, Function> _callbacks;
  TabController _tabController;
  bool _refreshFlag;

  TabCollection(this._vsync) {
    _tabs = List();
    _tabViews = List();
    _callbacks = Map();
    _refreshFlag = false;
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

  void updateTabView(Widget prevView, Widget newView) {
    for(int i = 0; i < _tabViews.length; i++) {
      if (_tabViews[i] == prevView) {
        _tabViews[i] = newView;
        Function callBack = _callbacks[prevView];
        _callbacks.remove(prevView);
        _callbacks[newView] = callBack;
      }
    }
    _refreshFlag = true;
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
    return TabBarView(
      controller: _tabController,
      children: _tabViews,
      key: _getKey()
    );
  }

  Key _getKey() {
    if (_refreshFlag) {
      _refreshFlag = false;
      return UniqueKey();
    }
    else {
      return null;
    }
  }

}