import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// 读取目录下的直接子项并返回需要的元数据
/// 返回 List<Map>，每个 Map 包含：
/// {
///   'name': String,
///   'fullPath': String,
///   'isDirectory': bool,
///   'lastModified': String (ISO8601),
///   'fileCount': int,
///   'directoryCount': int
/// }
Future<List<Map<String, dynamic>>> readDirectoryEntries(String dirPath) async {
  final dir = Directory(dirPath);
  final List<Map<String, dynamic>> results = [];

  if (!await dir.exists()) {
    throw FileSystemException('Directory does not exist', dirPath);
  }

  await for (final entity in dir.list(followLinks: false)) {
    try {
      final String fullPath = entity.path;
      final String name = p.basename(fullPath);
      final bool isDir = await FileSystemEntity.isDirectory(fullPath);
      final FileStat stat = await FileStat.stat(fullPath);
      DateTime modified = stat.modified;

      int fileCount = 0;
      int directoryCount = 0;

      if (isDir) {
        final counts = await _countDirectoryRecursive(Directory(fullPath));
        fileCount = counts['files'] ?? 0;
        directoryCount = counts['dirs'] ?? 0;
      }

      results.add({
        'name': name,
        'fullPath': fullPath,
        'isDirectory': isDir,
        'lastModified': modified.toIso8601String(),
        'fileCount': fileCount,
        'directoryCount': directoryCount,
      });
    } catch (e) {
      // 出错时跳过该条目或根据需要记录错误。
      continue;
    }
  }

  return results;
}

/// 递归统计目录下的文件数与子目录数（不包含根目录本身）
Future<Map<String, int>> _countDirectoryRecursive(Directory dir) async {
  int files = 0;
  int dirs = 0;

  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      try {
        if (await FileSystemEntity.isDirectory(entity.path)) {
          dirs += 1;
        } else {
          files += 1;
        }
      } catch (_) {
        // 忽略单个实体错误
        continue;
      }
    }
  } catch (_) {
    // 如果无法遍历目录，返回 0 统计
    return {'files': 0, 'dirs': 0};
  }

  return {'files': files, 'dirs': dirs};
}
