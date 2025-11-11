import 'dart:async';
import 'dart:io';

import 'package:meme_album/service/ocr.dart';
import 'package:meme_album/service/store.dart';

import 'package:logger/logger.dart';
import 'package:event_bus/event_bus.dart';

String path = r'lib/pages/album';

class OcrSync {
  final OCRService ocrService;
  final StoreService storeService;
  final EventBus eventbus;
  final Logger logger;

  OcrSync(this.ocrService, this.storeService, this.eventbus, this.logger);

  FutureOr<String> init() async {
    var result = await storeService.sort('PicInfo', 'id', 'DESC', '1');
    var lastRecord = result.isNotEmpty ? result.first : null;
    var lastPath = lastRecord?['path'];
    var lastmodfytime = lastRecord?['modifytime'];
    print('OcrSync init last record: $lastPath');

    var processResult = await processDir(
      path,
      lastmodfytime ?? '',
      lastPath ?? '',
    );
    if (processResult == 'done') {
      eventbus.fire('ocr_sync_progress done');
    }

    return 'complete';
  }

  Future<String> processDir(
    String dir,
    String lastmodfytime,
    String lastPath,
  ) async {
    var entities = await Directory(dir).list().toList();

    // 仅保留文件且扩展名为图片的实体
    var fillist = entities
        .where(
          (e) => FileSystemEntity.isFileSync(e.path) && _isImageFile(e.path),
        )
        .toList();

    fillist.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return aTime.compareTo(bTime); // 升序：旧文件在前
    });

    for (var file in fillist) {
      print('Found file: ${file.path}');

      var modifytime = (await File(file.path).lastModified()).toIso8601String();

      if ((lastmodfytime != null && modifytime.compareTo(lastmodfytime) <= 0) ||
          file.path == lastPath) {
        print(
          'Skipping file (modifytime not newer): ${file.path}, $modifytime',
        );
        continue;
      }

      var filePath = file.path;
      print('Processing file: $filePath');
      try {
        await ocrService.ocrImageFile(filePath);
      } catch (e) {
        return 'error: $e';
      }
    }
    return 'done';
  }

  // 新增：根据扩展名判断是否为常见图片格式
  bool _isImageFile(String p) {
    final ext = p.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp') ||
        ext.endsWith('.bmp') ||
        ext.endsWith('.heic') ||
        ext.endsWith('.tiff') ||
        ext.endsWith('.svg');
  }
}
