import 'package:flutter/material.dart';
import 'package:listapp/widgets/bottom_action_bar.dart';

class ActionWidgetCollection {

  List<_ActionWidget> _actionWidgets;

  ActionWidgetCollection() {
    _actionWidgets = List();
  }

  void addAction(String name, Widget widget) {
    _actionWidgets.add(_ActionWidget(name, widget));
  }

  void setAction(String name, Widget updatedWidget) {
    for (int i = 0; i < _actionWidgets.length; i++) {
      _ActionWidget actionWidget = _actionWidgets[i];
      if (actionWidget._name == name) {
        actionWidget._widget = updatedWidget;
      }
    }
  }

  void removeAction(String name) {
    for (int i = 0; i < _actionWidgets.length; i++) {
      if (_actionWidgets[i]._name == name) {
        _actionWidgets.removeAt(i);
      }
    }
  }

  List<Widget> getActionWidgets() {
    List<Widget> widgets = List();
    for (int i = 0; i < _actionWidgets.length; i++) {
      widgets.add(_actionWidgets[i]._widget);
    }
    return widgets;
  }

  Widget getLayout() {
    return BottomActionBar(getActionWidgets());
  }
}

class _ActionWidget {

  String _name;
  Widget _widget;

  _ActionWidget(this._name, this._widget);
}