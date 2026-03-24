import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GFSearchBar(
        searchList: [],
        searchQueryBuilder: (query, list) {
          return list
              .where((item) => item.toLowerCase().contains(query.toLowerCase()))
              .toList();
        },
        overlaySearchListItemBuilder: (item) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: Text(item, style: const TextStyle(fontSize: 18)),
          );
        },
      ),
    );
  }
}
