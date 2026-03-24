import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';
import 'package:event_bus/event_bus.dart';

class FileTidy {
  Future<void> albumTidy(
    String dirPath,
    List<String> source,
    Logger logger,
    EventBus eventBus,
  ) async {
    eventBus.on<String>().listen((event) {
      if (event.startsWith('FileTidyFolderPicker')) {
        var folderPath = event.split(';')[1];
        print('Received new File Tidy folder path: $folderPath');
        dirPath = folderPath;
      }
    });
    if (!Directory(dirPath).existsSync()) {
      logger.w('Directory does not exist: $dirPath');
      Directory(dirPath).create(recursive: true);
    }

    for (String dir in source) {
      var dirEntry = Directory(dir);
      final entities = await dirEntry.list().toList();
      for (var pic in entities) {
        File(pic.path).copySync(p.join(dirPath, p.basename(pic.path)));
      }
    }
  }
}
