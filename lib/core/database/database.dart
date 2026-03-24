import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_simple/sqlite3_simple.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

// // 修正常量命名（content 原为 "PicInfo"，应为 "content"）
// final id = "id", name = "name", content = "content", path = "path";
// final fts5Table = "PicInfo_fts";

// const List<String> Tables = [
//   'CREATE TABLE IF NOT EXISTS PicInfo(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, path TEXT, hash TEXT UNIQUE, content TEXT, modifytime TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
// ];

// // 1. 初始化数据库
//   await AppDatabase.init();

//   // 2. 注册表结构 (例如主表和虚表)
//   final dbApp = AppDatabase.instance;

class AppDatabase {
  // 1. 更加简洁的单例模式
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  Database? _db;

  // 使用 Completer 确保初始化逻辑只运行一次，防止并发调用引发的多次初始化
  static Completer<void>? _initCompleter;

  static const String _jiebaDictDirName = 'jieba_dict';
  static const List<String> _jiebaAssetCandidates = [
    'assets/jieba_dict/hmm_model.utf8',
    'assets/jieba_dict/idf.utf8',
    'assets/jieba_dict/jieba.dict.utf8',
    'assets/jieba_dict/stop_words.utf8',
    'assets/jieba_dict/user.dict.utf8',
  ];

  /// 外部统一调用的初始化入口
  static Future<void> init() async {
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();
    try {
      await instance._doInit();
      _initCompleter!.complete();
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      _initCompleter = null; // 出错后允许重试
      rethrow;
    }
  }

  /// 实际的私有初始化逻辑
  Future<void> _doInit() async {
    if (_db != null) return;

    final dir = await getApplicationSupportDirectory();
    final dbDir = Directory(join(dir.path, 'database'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    final dbPath = join(dbDir.path, 'database.db');
    final targetJiebaDir = Directory(join(dbDir.path, _jiebaDictDirName));

    // 1. 加载扩展
    sqlite3.loadSimpleExtension();

    // 2. 准备分词字典 (优化文件拷贝逻辑)
    String? jiebaDictSql;
    try {
      jiebaDictSql = await _prepareJiebaDict(targetJiebaDir);
    } catch (e) {
      print('Jieba dict preparation failed: $e');
    }

    // 3. 打开数据库
    _db = sqlite3.open(dbPath);

    // 4. 配置分词器
    if (jiebaDictSql != null && jiebaDictSql.isNotEmpty) {
      print('Executing jieba dict SQL...');
      final result = _db!.select(jiebaDictSql);
      print('Jieba dict config result: ${result.first[0]}');
    }

    print('Database initialized at: $dbPath');
  }

  Future<String?> _prepareJiebaDict(Directory targetDir) async {
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    // 调用扩展提供的方法获取配置 SQL
    return await sqlite3.saveJiebaDict(
      targetDir.path,
      overwriteWhenExist: false,
    );
  }

  /// 获取数据库实例，如果未初始化则自动初始化
  Future<Database> get database async {
    if (_db == null) await init();
    return _db!;
  }

  Future<void> close() async {
    _db?.dispose();
    _db = null;
    _initCompleter = null;
  }
}
