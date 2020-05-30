import 'package:flutter/material.dart';

class TaskListBar extends StatefulWidget {
  @override
  _TaskListBarState createState() => _TaskListBarState();
}

class _TaskListBarState extends State<TaskListBar> {

  FloatingActionButton _doneButton;
  FloatingActionButton _addButton;
  Text _percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(height: 100),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: Color.fromRGBO(1, 0, 1, 0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10)
        ),
        boxShadow: kElevationToShadow[8]
      ),
    );
  }

}