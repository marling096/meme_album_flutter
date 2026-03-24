import 'package:meme_album/app/init_task/base.dart';
import 'package:meme_album/core/config/env_impl.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:get_it/get_it.dart';

// lib/core/config/env_impl.dart
class Env implements IEnv {
  @override
  final String apiKey;
  @override
  final String secretKey;
  @override
  final List<String> albumDir;
  @override
  final String logFile;

  Env({
    required this.apiKey,
    required this.secretKey,
    required this.albumDir,
    required this.logFile,
  });
}

class Env_Task extends InitTask {
  final GetIt _getIt;
  Env_Task(this._getIt);

  @override
  Future<void> execute() async {
    await dotenv.load(fileName: '.env');
    String apiKey = dotenv.env['API_KEY'] ?? '';
    String secretKey = dotenv.env['SECRET_KEY'] ?? '';

    List<String> albumDir = [];
    String logFile = '';
    if (Platform.isAndroid) {
      albumDir = albumDir =
          dotenv.env['android_albumDir']?.split(',').toList() ??
          ['storage/emulated/0/Download'];
      logFile =
          dotenv.env['android_logFile'] ??
          'storage/emulated/0/Download/logs.txt';
    }
    if (Platform.isWindows || Platform.isLinux) {
      albumDir =
          dotenv.env['win_albumDir']?.split(',').toList() ?? ['lib/pages'];
      logFile = dotenv.env['win_logFile'] ?? 'logs.txt';
    }

    _getIt.registerSingleton<IEnv>(
      Env(
        apiKey: apiKey,
        secretKey: secretKey,
        albumDir: albumDir,
        logFile: logFile,
      ),
    );
  }
}
