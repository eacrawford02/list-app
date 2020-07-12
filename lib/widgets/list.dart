import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ListWidget extends StatefulWidget {

  final IListData _listModel;
  final Future<void> _initialized;

  ListWidget(this._listModel, this._initialized, Key key)
      : super(key : key);

  @override
  ListWidgetState createState() =>
      ListWidgetState(_listModel, _initialized);
}

class ListWidgetState extends State<ListWidget> {

  final IListData _listModel;
  // For whatever stupid reason, the GlobalKey used to access this state must
  // be created in the state class otherwise trying to access it via the
  // currentState property will return null
  final GlobalKey<AnimatedListState> _key = GlobalKey<AnimatedListState>();
   Future<void> _initialized;
   AutoScrollController _scrollController;
   bool _shouldScroll = false;
   int _scrollIndex = 0;

  ListWidgetState(this._listModel, this._initialized) {
    _listModel.setKey(_key);
    _listModel.setItemRemover(_removeItem);
    _listModel.setRefreshCallback(_refresh);
    _listModel.setScrollTo(_scrollTo);
  }

  @override
  void initState() {
    super.initState();

    _scrollController = AutoScrollController(
      axis: Axis.vertical
    );
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    Widget item = _listModel.getItemWidget(index, animation);
    Widget scrollItem =  AutoScrollTag(
      key: item.key,
      controller: _scrollController,
      index: index,
      child: item
    );
    // print("$index = ${_listModel.getListLength() - 1}");
    if (_shouldScroll) {
      _scrollController.scrollToIndex(_scrollIndex);
      _shouldScroll = false;
    }
    return scrollItem;
  }

  Widget _removeItem(Widget widget) => widget;

  void _refresh() {
    setState(() {});
  }

  void _scrollTo(int index) {
    _scrollIndex = index;
    _shouldScroll = true;
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
            initialItemCount: _listModel.getListLength(),
            itemBuilder: _buildItem,
            controller: _scrollController,
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

  void setScrollTo(Function function);

  int getNumItems();

  int getListLength();

  Widget getItemWidget(int index, Animation<double> animation);
}