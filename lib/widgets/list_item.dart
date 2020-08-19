import 'package:flutter/material.dart';

typedef GetChildWidgets = Widget Function(BuildContext context);

class ListItem extends StatefulWidget {
  final ListItemData listItemData;
  final Animation<double> animation;

  ListItem(Key key, this.listItemData, this.animation) : super(key: key);

  @override
  ListItemState createState() => ListItemState();
}

class ListItemState extends State<ListItem> {

  @override
  void initState() {
    super.initState();

    widget.listItemData.updateWidget = () => setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ListItemData data = widget.listItemData;

    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 8
      ),
      child: SizeTransition(
        axis: Axis.vertical,
        sizeFactor: widget.animation,
        child: Card(
          shape: Border(
            bottom: data.isHighlighted ?
                BorderSide(color: data.highlightColor) : BorderSide.none
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 2,
              bottom: 2
            ),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8
                  ),
                  child: data.leftAction(context)
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.title,
                        style: TextStyle(
                          //fontSize: 18, // TODO: fix later
                          fontWeight: FontWeight.bold
                        )
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          bottom: 8
                        ),
                        child: Text(
                          data.text,
                          style: TextStyle(
                            fontSize: 18,
                            decoration: data.textDecoration
                          )
                        )
                      ),
                      Text(data.bottomText)
                    ]
                  )
                ),
                data.rightAction(context)
              ]
            )
          )
        )
      )
    );
  }
}

class ListItemData {
  VoidCallback updateWidget = () {};

  GetChildWidgets leftAction;

  String title;

  String text;

  TextDecoration textDecoration;

  String bottomText;

  GetChildWidgets rightAction;

  bool isHighlighted;

  Color highlightColor;

  ListItemData({
    GetChildWidgets leftAction,
    this.title : "",
    this.text : "",
    this.textDecoration : TextDecoration.none,
    this.bottomText : "",
    GetChildWidgets rightAction,
    this.isHighlighted : false,
    this.highlightColor : Colors.blue
  }) {
    this.leftAction = leftAction ?? (BuildContext c) => null;
    this.rightAction = rightAction ?? (BuildContext c) => null;
  }
}