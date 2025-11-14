import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

class LoggerManager {
  // 使用可空的延迟单例，并在首次传入 logfile 时创建实例
  static LoggerManager? _instance;
  factory LoggerManager(File logfile) {
    _instance ??= LoggerManager._internal(logfile);
    return _instance!;
  }
  LoggerManager._internal(this.logfile) {
    // 确保目录存在
    try {
      if (!logfile.existsSync()) {
        logfile.createSync(recursive: true);
      }
    } catch (_) {}

    logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,

        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: LoggerWriter(logfile: logfile),
    );
  }

  final File logfile;

  // 延迟初始化 logger，构造中赋值
  late final Logger logger;
}

class LoggerWriter extends FileOutput {
  final File file;

  LoggerWriter({required File logfile})
    : file = logfile,
      super(file: logfile, overrideExisting: false, encoding: utf8);

  @override
  void output(OutputEvent event) async {
    // 一次性打开 sink，写入所有行后再 flush 和 close
    var sink = file.openWrite(mode: FileMode.append);
    try {
      for (var line in event.lines) {
        sink.writeln(line);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }
}
