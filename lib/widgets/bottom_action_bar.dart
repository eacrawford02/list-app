import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  final List<Widget> actionWidgets;

  BottomActionBar({this.actionWidgets});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 0, 255, 0.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16)
          )
        ),
        child: Padding(
          padding: const EdgeInsets.only(top:  8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: actionWidgets
          )
        )
      )
    );
  }
}