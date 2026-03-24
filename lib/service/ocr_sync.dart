import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;

import 'package:logger/logger.dart';
import 'package:event_bus/event_bus.dart';

import 'package:meme_album/core/utils/album_utils.dart';
import 'package:meme_album/core/utils/ocr.dart';

import 'package:crypto/crypto.dart';

import 'package:meme_album/repository/pictures/pics_repo.dart';
import 'package:meme_album/repository/pictures/pics_fts5_repo.dart';

class OcrSync {
  final EventBus eventbus;
  final Logger logger;
  final PicsRepo picsRepo;
  final PicFTS5Repo picFTS5Repo;
  final List<String> albumDir;
  List<String> pic_dirs = [];
  OcrSync(
    this.eventbus,
    this.logger,
    this.picsRepo,
    this.picFTS5Repo,
    this.albumDir,
  );

  FutureOr<String> init() async {
    var result = await picsRepo.getList(
      sortBy: 'modifytime',
      order: 'DESC',
      limit: 1,
    );
    var lastRecord = result.isNotEmpty ? result.first : null;
    var lastPath = lastRecord?.path;
    var lastmodfytime = lastRecord?.modifytime;
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
      await init();

      final entities = await Directory(dir).list().toList();

      for (final entity in entities) {
        if (entity is Directory) {
          final subEntities = await entity.list().toList();
          final firstImage = subEntities.firstWhereOrNull(
            (meta) => meta is File && isImageFile(meta.path),
          );
          if (firstImage != null) {
            pic_dirs.add(entity.path);
          }
        } else if (entity is File && isImageFile(entity.path)) {
          pic_dirs.add(entity.path);
          // debugPrint('Added image: ${entity.path}');
        }
      }
    } catch (e) {}
    print('Processed directory: $pic_dirs');

    var entities = <FileSystemEntity>[];
    for (final pth in pic_dirs) {
      try {
        if (isImageFile(pth)) {
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
          (e) => FileSystemEntity.isFileSync(e.path) && isImageFile(e.path),
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
        final bytes = await File(filePath).readAsBytes();
        final fileHash = md5.convert(bytes).toString();
        final fileName = p.basename(filePath);
        final modifytime = (await File(
          filePath,
        ).lastModified()).toIso8601String();
        final imageBase64 = base64Encode(bytes);

        var result = await performOCR(imageBase64);
        // print('OCR result for $fileName: $result');
        await picsRepo.insertPic(
          PicInfo(
            name: fileName,
            path: filePath,
            hash: fileHash,
            modifytime: modifytime,
            content: result,
          ),
        );
      } catch (e) {
        return 'error: $e';
      }
    }
    return 'done';
  }
}
