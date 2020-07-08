import 'package:flutter/material.dart';
import 'package:listapp/widgets/task.dart';

class ListWidget extends StatefulWidget {

  final IListData _listModel;
  final GlobalKey<AnimatedListState> _key;
  final int _initialItems;

  ListWidget(this._listModel, this._key, this._initialItems);

  @override
  ListWidgetState createState() =>
      ListWidgetState(_listModel, _initialItems);
}

class ListWidgetState extends State<ListWidget> {

  final IListData _listModel;
  // For whatever stupid reason, the GlobalKey used to access this state must
  // be created in the state class otherwise trying to access it via the
  // currentState property will return null
  final GlobalKey<AnimatedListState> _key = GlobalKey<AnimatedListState>();
   Future<void> _initialized;
  final int _initialItems;

  ListWidgetState(this._listModel, this._initialItems) {
    _listModel.setKey(_key);
    _listModel.setItemRemover(_removeItem);
    _listModel.setRefreshCallback(_refresh);
    this._initialized = _listModel.initialize();
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    print("in list ${_listModel.getNumItems()}");
    return _listModel.getItemWidget(index, animation);
  }

  Widget _removeItem(Widget widget) => widget;

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialized,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        // If the list model has been initialized
        if (snapshot.connectionState == ConnectionState.done) {
          print("num items ${_listModel.getNumItems()}");
          return AnimatedList(
            key: _key,
            initialItemCount: _listModel.getNumItems(),
            itemBuilder: _buildItem,
          );
        }
        else {
          print("bruh items ${_listModel.getNumItems()}");
          return Container(
            alignment: Alignment.center,
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(),
            )
          );
        }
      }
    );
  }
}

// Must be implemented by any list data model that uses this widget
abstract class IListData<T> { // Where T is the type of data, ie. TaskData
  void setKey(GlobalKey<AnimatedListState> key);

  void setItemRemover(Function function);

  void setRefreshCallback(Function function);

  Future<void> initialize();

  int getNumItems();

  Widget getItemWidget(int index, Animation<double> animation);
}