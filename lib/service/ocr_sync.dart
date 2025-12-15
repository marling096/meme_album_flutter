import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:meme_album/service/ocr.dart';
import 'package:meme_album/service/store.dart';

import 'package:logger/logger.dart';
import 'package:event_bus/event_bus.dart';

class OcrSync {
  final OCRService ocrService;
  final StoreService storeService;
  final EventBus eventbus;
  final Logger logger;
  final List<String> albumDir;
  List<String> pic_dirs = [];
  OcrSync(
    this.ocrService,
    this.storeService,
    this.eventbus,
    this.logger,
    this.albumDir,
  );

  FutureOr<String> init() async {
    var result = await storeService.sort('PicInfo', 'id', 'DESC', '1');
    var lastRecord = result.isNotEmpty ? result.first : null;
    var lastPath = lastRecord?['path'];
    var lastmodfytime = lastRecord?['modifytime'];
    print('OcrSync init last record: $lastPath');
    print('album_dir: $albumDir');

    eventbus.on<String>().listen((event) {
      print('Event received: $event');
      if (event.startsWith('AlbumFolderPicker')) {
        var folderPath = event.split(';')[1];
        print('Received new album folder path: $folderPath');
      }
    });
    var processResult = '';
    for (var dir in albumDir) {
      processResult = await processDir(
        dir,
        lastmodfytime ?? '',
        lastPath ?? '',
      );
    }
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
    try {
      final entities = await Directory(dir).list().toList();

      for (final entity in entities) {
        if (entity is Directory) {
          final subEntities = await entity.list().toList();
          final firstImage = subEntities.firstWhereOrNull(
            (meta) => meta is File && _isImageFile(meta.path),
          );
          if (firstImage != null) {
            pic_dirs.add(entity.path);
          }
        } else if (entity is File && _isImageFile(entity.path)) {
          pic_dirs.add(entity.path);
          // debugPrint('Added image: ${entity.path}');
        }
      }
    } catch (e) {}
    print('Processed directory: $pic_dirs');

    var entities = <FileSystemEntity>[];
    for (final pth in pic_dirs) {
      try {
        if (_isImageFile(pth)) {
          entities.add(File(pth));
        } else {
          final dirEntity = Directory(pth);
          if (await dirEntity.exists()) {
            entities.addAll(await dirEntity.list().toList());
          }
        }
      } catch (e) {
        // ignore errors per original behavior
      }
    }

    print('Processing directory: $dir, found ${entities.length} entities');

    var fillist = entities
        .where(
          (e) => FileSystemEntity.isFileSync(e.path) && _isImageFile(e.path),
        )
        .toList();

    fillist.sort((a, b) {
      final aTime = a.statSync().modified;
      final bTime = b.statSync().modified;
      return aTime.compareTo(bTime);
    });

    for (var file in fillist) {
      print('Found file: ${file.path}');

      var modifytime = (await File(file.path).lastModified()).toIso8601String();

      if ((modifytime.compareTo(lastmodfytime) <= 0) || file.path == lastPath) {
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
