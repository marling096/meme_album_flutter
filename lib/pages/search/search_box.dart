import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/utils.dart';
import 'package:getwidget/getwidget.dart';
import 'package:meme_album/service/ocr.dart';
import 'package:meme_album/service/store.dart';
import 'package:get/get.dart';
import 'package:meme_album/pages/album/album.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = StoreService.instance;
    return Scaffold(
      body: TextField(
        // 保证输入内容和 hint 在垂直方向居中，跨平台一致
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search...',

          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          alignLabelWithHint: true,
          hintStyle: TextStyle(color: Colors.grey[600]),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: const Color.fromARGB(255, 143, 176, 202),
            ),
            borderRadius: (BorderRadius.all(Radius.circular(10.0))),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              width: 1,
              color: const Color.fromARGB(255, 34, 114, 175),
            ),
            borderRadius: (BorderRadius.all(Radius.circular(10.0))),
          ),
        ),
        onSubmitted: (query) async {
          // Get.to(() => SearchPage(query: query));
          String result = await store.search('PicInfo', query, 'jieba');
          Get.to(() => AlbumPage([result]));
        },
      ),
    );
  }
}
