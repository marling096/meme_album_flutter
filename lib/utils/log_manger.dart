import 'dart:ffi';

import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:io';

var logfile = 'logs.txt';
var logFile = File(logfile);

class LoggerManager {
  static final LoggerManager _instance = LoggerManager._internal();
  factory LoggerManager() {
    return _instance;
  }
  LoggerManager._internal();

  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: LoggerWriter(),
  );
}

class LoggerWriter extends FileOutput {
  LoggerWriter()
    : super(file: File(logfile), overrideExisting: false, encoding: utf8);
  @override
  void output(OutputEvent event) async {
    for (var line in event.lines) {
      // You can customize this to write logs to a file or other destinations
      var sink = logFile.openWrite(mode: FileMode.append);
      try {
        sink.writeln(line);

        await sink.flush();
      } finally {
        await sink.close();
      }
    }
  }
}
