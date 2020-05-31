import 'package:flutter/material.dart';

typedef Widgets = List<Widget> Function();

class BottomActionBar extends StatefulWidget {

  final List<Widget> _actionWidgets;

  BottomActionBar(this._actionWidgets);

  @override
  _BottomActionBarState createState() => _BottomActionBarState(_actionWidgets);
}

class _BottomActionBarState extends State<BottomActionBar> {

  List<Widget> _actionWidgets;

  _BottomActionBarState(this._actionWidgets);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(1, 0, 1, 0.5),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16)
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _actionWidgets,
        ),
      ),
    );
  }
}