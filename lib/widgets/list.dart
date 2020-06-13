import 'package:flutter/material.dart';
import 'package:listapp/models/task_list.dart';
import 'package:listapp/widgets/task.dart';

class ListWidget extends StatefulWidget {

  final IListData _listModel;
  final GlobalKey<SliverAnimatedListState> _key;
  final int _initialItems;

  ListWidget(this._listModel, this._key, this._initialItems);

  @override
  ListWidgetState createState() => ListWidgetState(_listModel, _key, _initialItems);
}

class ListWidgetState extends State<ListWidget> {

  final IListData _listModel;
  final GlobalKey<SliverAnimatedListState> _key;
  final int _initialItems;

  ListWidgetState(this._listModel, this._key, this._initialItems);

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    return Task( //TODO: clean this up
      listModel: _listModel,
      animation: animation,
      taskData: _listModel.getItemData(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _key,
      initialItemCount: _initialItems,
      itemBuilder: _buildItem,
    );
  }
}

// Must be implemented by any list data model that uses this widget
abstract class IListData<T> { // Where T is the type of data, ie. TaskData
  T getItemData(int index);
}