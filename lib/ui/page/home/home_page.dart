import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:event_bus/event_bus.dart';
import 'package:get_it/get_it.dart';

// Your internal imports
import 'package:meme_album/ui/page/album/album.dart';
import 'package:meme_album/ui/page/search/search_box.dart';
import 'package:meme_album/ui/page/settings/settings.dart';
import 'package:meme_album/core/config/env_impl.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.get_it});

  final GetIt get_it;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    // 2. Access EventBus directly via GetIt
    final eventBus = widget.get_it<EventBus>();

    _sub = eventBus.on<String>().listen((event) {
      GFToast.showToast(
        'EventBus received: $event',
        context,
        toastPosition: GFToastPosition.BOTTOM,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. Access IEnv directly to get album directories
    final albumDir = widget.get_it<IEnv>().albumDir;

    return Scaffold(
      // 1. 恢复标准高度或略高一点，确保搜索框有足够的呼吸空间
      appBar: AppBar(
        toolbarHeight: 64, // 适当增加高度，提升精致感
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0, // 减少左侧默认间距，增加搜索框宽度
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0), // 左侧留白
          child: Container(
            height: 44, // 搜索框高度
            decoration: BoxDecoration(
              // 如果 SearchBox 内部没有自带背景，可以在这里给个浅灰色背景
              color: Theme.of(context).hoverColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SearchBox(get_it: widget.get_it),
          ),
        ),
        actions: [
          // 2. 增加设置按钮的间距，防止误触
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined), // 使用空心图标更显精致
              onPressed: () => Get.to(() => const SettingsPage()),
            ),
          ),
        ],
      ),

      // 3. 简化 body 结构，AlbumPage 应该直接作为主要内容
      body: SafeArea(
        // 如果 AlbumPage 内部已经是列表或 Grid，直接放置即可
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), // 统一边距
          child: AlbumPage(
            widget.get_it<IEnv>().albumDir,
          ), // 同样建议将依赖注入内部或直接通过 GetIt 获取
        ),
      ),
    );
  }
}
