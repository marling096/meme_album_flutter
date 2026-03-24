import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:meme_album/core/utils/album_utils.dart';

String _normalizePath(String path) => path.replaceAll(r'\', '/');

class AlbumController extends GetxController {
  /// 当前状态：idle / loading / done / error
  final RxString status = 'idle'.obs;

  final RxList<String> covers = <String>[].obs;

  List<String> pic_dirs = [];

  List<String> albumPath = [];

  AlbumController(List<String> paths) {
    albumPath = paths.map(_normalizePath).toList();
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    Set<String> albums = {};
    status.value = 'loading';

    for (String path in albumPath) {
      if (Directory(path).existsSync()) {
        albums.addAll(await scanAlbumDirectory(path));
      }
      if (File(path).existsSync()) {
        covers.add(path);
      }
    }
    if (albums.isNotEmpty) {
      for (String album in albums) {
        if (File(album).existsSync()) {
          covers.add(album);
        }
        if (Directory(album).existsSync()) {
          final cover = await getAlbumCoverImage(album);
          if (cover.isNotEmpty) {
            covers.add(cover);
          }
        }
      }
    }

    status.value = 'done';
    print('AlbumController initialized with ${covers.length} covers.');
    print('Covers: $covers');
  }
}

class AlbumPage extends StatefulWidget {
  final List<String> albumPath;
  AlbumPage(this.albumPath, {super.key}) {
    // 可选调试输出
    // debugPrint('path: $albumPath');
  }

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  late final String tag;
  late final AlbumController controller;
  final ScrollController _scrollController = ScrollController();

  // 点击放大图片的对话框
  void _showImageDialog(BuildContext context, String file) {
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              child: InteractiveViewer(
                child: Image.file(
                  File(file),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Icon(Icons.broken_image, size: 80)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    tag = Uuid().v4();
    controller = Get.put<AlbumController>(
      AlbumController(widget.albumPath),
      tag: tag,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 可选：当页面销毁时移除 controller（根据你的 GetX 使用策略）
    // Get.delete<AlbumController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Obx(() {
        final status = controller.status.value;

        if (status == 'loading') {
          return const Center(child: CircularProgressIndicator());
        }
        if (status == 'error') {
          return Center(
            child: Text(
              '无法加载相册：${controller.albumPath.join(", ")}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (controller.covers.isEmpty) {
          return const Center(child: Text('未找到任何图片'));
        }

        // Scrollbar + SingleChildScrollView 包裹可滚动内容
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 8.0;
                final double available = constraints.maxWidth;
                final double itemWidth = (available - spacing) / 2.0;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  alignment: WrapAlignment.start,
                  children: controller.covers.map((file) {
                    final fileName = p.basename(file);
                    final fileDirRaw = p.dirname(file);
                    final fileDir = _normalizePath(fileDirRaw);
                    return GestureDetector(
                      onTap: () async {
                        if (controller.albumPath.contains(file) ||
                            controller.albumPath.contains(fileDir)) {
                          _showImageDialog(context, file);
                          debugPrint(
                            'Tapped file: $fileName, dir: $fileDir, file_path: $file',
                          );
                        } else {
                          Get.to(
                            () => AlbumPage([fileDir]),
                            preventDuplicates: false,
                          );
                        }
                      },
                      onLongPress: () async {
                        await Clipboard.setData(ClipboardData(text: file));
                        Get.snackbar(
                          'Copied',
                          '已复制文件路径：$fileName',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: SizedBox(
                        width: itemWidth,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(file),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 60,
                                        ),
                                      ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    color: Colors.black45,
                                    child: Text(
                                      !controller.albumPath.contains(fileDir)
                                          ? fileDir
                                          : fileName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}
