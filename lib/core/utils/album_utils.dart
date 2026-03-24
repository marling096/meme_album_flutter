import 'dart:io';

Future<Set<String>> scanAlbumDirectory(String dirPath) async {
  final dir = Directory(dirPath);
  final Set<String> albumPaths = {};

  if (!await dir.exists()) {
    throw FileSystemException('Directory does not exist', dirPath);
  }

  final entities = await Directory(dirPath).list().toList();

  for (var entry in entities) {
    if (entry is Directory) {
      final subEntities = await entry.list().toList();
      for (var subEntry in subEntities) {
        if (subEntry is File && isImageFile(subEntry.path)) {
          albumPaths.add(entry.path);
          break;
        }
      }
    } else if (entry is File && isImageFile(entry.path)) {
      albumPaths.add(entry.path);
      continue;
    }
  }

  return albumPaths;
}

Future<String> getAlbumCoverImage(String albumPath) async {
  final dir = Directory(albumPath);

  if (!await dir.exists()) {
    throw FileSystemException('Directory does not exist', albumPath);
  }

  final entities = await dir.list().toList();

  for (var entry in entities) {
    if (entry is File && isImageFile(entry.path)) {
      return entry.path;
    }
  }

  throw FileSystemException('No image files found in album', albumPath);
}

bool isImageFile(String p) {
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
