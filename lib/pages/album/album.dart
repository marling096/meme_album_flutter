import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:event_bus/event_bus.dart';

import 'package:meme_album/service/ocr.dart';

// 新增：路径标准化为使用正斜杠（显示与比较统一）
String _normalizePath(String path) => path.replaceAll(r'\', '/');

/// AlbumController — 负责扫描目录并生成封面图片列表
class AlbumController extends GetxController {
  /// 当前状态：idle / loading / done / error
  final RxString status = 'idle'.obs;

  /// 相册封面路径列表
  final RxList<String> covers = <String>[].obs;

  /// 根目录路径
  List<String> albumPath = [];

  AlbumController(List<String> paths) {
    // 将传入路径标准化（统一为正斜杠风格），便于后续比较与展示
    albumPath = paths.map(_normalizePath).toList();
  }

  void load_new(String newPath) {
    this.albumPath = [newPath];
    scanAlbum(newPath);
  }

  static const List<String> _imageExts = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.heic',
  ];

  @override
  void onInit() {
    super.onInit();
    debugPrint("AlbumController initialized for path: $albumPath");
    for (var path in albumPath) {
      scanAlbum(path);
    }
  }

  /// 判断文件是否为图片
  bool _isImageFile(FileSystemEntity file) {
    final ext = p.extension(file.path).toLowerCase();
    return _imageExts.contains(ext);
  }

  /// 扫描相册目录
  Future<void> scanAlbum(path) async {
    status.value = 'loading';
    covers.clear();
    final albumDir = Directory(path);
    //判断path是否为目录

    // if (!await albumDir.exists()) {
    //   status.value = 'error';
    //   debugPrint('Album directory not found: $path');
    //   return;
    // }
    final type = await FileSystemEntity.type(path);
    if (type != FileSystemEntityType.directory) {
      // status.value = 'error';
      // debugPrint('Path is not a directory: $path');
      covers.add(path);
      status.value = 'done';
      return;
    }

    debugPrint('Scanning album directory: $path');

    try {
      final entities = await albumDir.list().toList();

      for (final entity in entities) {
        if (entity is Directory) {
          // 查找子目录中的第一张图片作为封面
          final subEntities = await entity.list().toList();
          final firstImage = subEntities.firstWhereOrNull(
            (meta) => meta is File && _isImageFile(meta),
          );
          if (firstImage != null) {
            covers.add(firstImage.path);
            debugPrint('Added cover from subdir: ${firstImage.path}');
          }
        } else if (entity is File && _isImageFile(entity)) {
          // 直接添加图片文件
          covers.add(entity.path);
          debugPrint('Added image: ${entity.path}');
        }
      }

      status.value = 'done';
      debugPrint('Scan complete, found ${covers.length} covers.');
    } catch (e, st) {
      status.value = 'error';
      debugPrint('Error while scanning album: $e\n$st');
    }
  }
}

class AlbumPage extends StatefulWidget {
  final List<String> albumPath;
  AlbumPage(this.albumPath, {super.key}) {
    // 可选调试输出
    debugPrint('path: $albumPath');
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
