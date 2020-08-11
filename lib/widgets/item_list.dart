import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

typedef GetPageData = ListPageData Function(BuildContext context);

class ItemList extends StatefulWidget {
  final GlobalKey<AnimatedListState> listKey;
  final IListModel listModel;
  final double bottomOffset;
  final GetPageData getPageData;

  ItemList({this.listKey, this.listModel, this.bottomOffset : 0.0,
      this.getPageData}) {
    if (listKey == null || listModel == null || getPageData == null) {
      throw Exception("Error: null arguments provided");
    }
    if (listKey != listModel.key) {
      throw Exception("The same key object must be provided to both the "
          "ItemList widget and its corresponding data model");
    }
  }

  @override
  ItemListState createState() => ItemListState();
}

class ItemListState extends State<ItemList> {
  AutoScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = AutoScrollController(
      axis: Axis.vertical,
      viewportBoundaryGetter: () => Rect.fromLTRB(0, 0, 0, widget.bottomOffset)
    );
  }

  Widget _buildItem(BuildContext context, int index,
      Animation<double> animation) {
    Widget item = widget.listModel.getItemWidget(index, animation);
    Widget scrollItem = AutoScrollTag(
      key: item.key,
      controller: _scrollController,
      index: index,
      child: item
    );
    // The AND clause ensures we don't scroll to an index that has not yet been
    // built
    ListPageData pageData = widget.getPageData(context);
    if (pageData.shouldScroll && index == pageData.scrollIndex) {
      _scrollController.scrollToIndex(pageData.scrollIndex);
      pageData.shouldScroll = false;
    }
    return scrollItem;
  }

  @override
  Widget build(BuildContext context) {
    // Handle changes to list data
    ListPageData pageData = widget.getPageData(context);
    if (pageData.shouldScroll) {
      _scrollController.scrollToIndex(pageData.scrollIndex);
      pageData.shouldScroll = false;
    }

    return FutureBuilder(
      future: widget.listModel.getInitFuture(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        // If the list model has been initialized
        if (snapshot.connectionState == ConnectionState.done) {
          return AnimatedList(
            key: widget.listKey,
            initialItemCount: widget.listModel.getListLength(),
            itemBuilder: _buildItem,
            controller: _scrollController
          );
        }
        else {
          return Container(
            alignment:  Alignment.center,
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator()
            )
          );
        }
      }
    );
  }
}

abstract class IListModel<T> {
  // This must be the same key object as is provided to ItemList
  GlobalKey<AnimatedListState> key;
  T pageData;

  IListModel({this.key, this.pageData});

  Future getInitFuture();

  Widget getItemWidget(int index, Animation<double> animation);

  int getListLength();
}

// Having a single ListPageData instance held by the parent page will work as
// long as two ItemLists aren't visible at the same time
abstract class ListPageData {
  bool shouldScroll = false;

  int scrollIndex = 0;
}