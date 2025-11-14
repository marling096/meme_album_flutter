import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_simple/sqlite3_simple.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';

abstract class BaseDao<T> {
  final AppDatabase db;
  final String tableName;

  BaseDao(this.db, this.tableName);

  Future<void> insert(Map<String, dynamic> data) async =>
      await db.insert(tableName, data);

  Future<void> update(
    Map<String, dynamic> data,
    String where,
    List<Object?> whereArgs,
  ) async => await db.update(tableName, data, where, whereArgs);

  Future<void> delete(String where, List<Object?> whereArgs) async =>
      await db.delete(tableName, where, whereArgs);

  Future<List<Map<String, dynamic>>> queryAll([
    String? where,
    List<Object?>? whereArgs,
  ]) async => await db.query(tableName, where: where, whereArgs: whereArgs);

  Future<List<Map<String, dynamic>>> sort(
    String tableName,
    String column,
    String orderBy,
    String limit,
  ) async {
    final dbClient = db._db;
    final result = await dbClient?.select(
      'SELECT * FROM $tableName ORDER BY $column $orderBy LIMIT $limit',
    );
    return result ?? [];
  }
}

class PicInfoTable extends BaseDao<PicInfo> {
  PicInfoTable(AppDatabase db) : super(db, 'PicInfo');

  Future<void> insertPic(PicInfo pic) async => await insert(pic.toMap());

  Future<List<PicInfo>> allPics() async {
    final rows = await queryAll();
    return rows.map((m) => PicInfo.fromMap(m)).toList();
  }

  /// 通过指定分词器 [tokenizer] 搜索， [tokenizer] 可为 'jieba' 或 'simple'
  ResultSet? search(String value, String tokenizer) {
    // 安全限制，防止 SQL 注入
    const allowed = ['jieba', 'simple'];
    final tk = allowed.contains(tokenizer) ? tokenizer : 'simple';
    final tokenizerQuery = tk == 'jieba' ? 'jieba_query' : 'simple_query';

    const wrapperLeft = '\u200B';
    const wrapperRight = '\u200C';

    // 查询虚表 PicInfo_fts
    final resultSet = db._db?.select(
      '''
    SELECT 
      PicInfo.rowid AS id,
      PicInfo.name,
      PicInfo.path,
      simple_highlight(PicInfo_fts, 0, '$wrapperLeft', '$wrapperRight') AS highlight_content
    FROM PicInfo_fts 
    JOIN PicInfo ON PicInfo.id = PicInfo_fts.rowid
    WHERE PicInfo_fts MATCH $tokenizerQuery(?);
    ''',
      [value],
    );

    return resultSet;
  }
}

class LoggerTable extends BaseDao<LoggerInfo> {
  LoggerTable(AppDatabase db) : super(db, 'Logger');

  Future<void> insertLog(LoggerInfo log) async => await insert(log.toMap());

  Future<List<LoggerInfo>> allLogs() async {
    final rows = await queryAll();
    return rows.map((m) => LoggerInfo.fromMap(m)).toList();
  }
}

class PicInfo {
  final String name;
  final String path;
  final String hash;
  final String content;

  PicInfo({
    required this.name,
    required this.path,
    required this.hash,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {'name': name, 'path': path, 'hash': hash, 'content': content};
  }

  factory PicInfo.fromMap(Map<String, dynamic> map) {
    return PicInfo(
      name: map['name'] as String? ?? '',
      path: map['path'] as String? ?? '',
      hash: map['hash'] as String? ?? '',
      content: map['content'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'PicInfo{name: $name, path: $path, hash: $hash, content: $content}';
  }
}

class LoggerInfo {
  final String log;
  final DateTime timestamp;

  LoggerInfo({required this.log, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {'log': log, 'timestamp': timestamp.toIso8601String()};
  }

  factory LoggerInfo.fromMap(Map<String, dynamic> map) {
    return LoggerInfo(
      log: map['log'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String? ?? ''),
    );
  }

  @override
  String toString() {
    return 'LoggerInfo{log: $log, timestamp: $timestamp}';
  }
}

// 修正常量命名（content 原为 "PicInfo"，应为 "content"）
final id = "id", name = "name", content = "content", path = "path";
final fts5Table = "PicInfo_fts";

const List<String> Tables = [
  'CREATE TABLE IF NOT EXISTS PicInfo(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, path TEXT, hash TEXT UNIQUE, content TEXT, modifytime TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
  'CREATE TABLE IF NOT EXISTS Logger(id INTEGER PRIMARY KEY AUTOINCREMENT, log TEXT , timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)',
];

class AppDatabase {
  static AppDatabase get instance => _instance;

  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  static const bool copyJiebaFromAssets = true;
  static const String jiebaAssetPath = 'assets/jieba_dict/';

  static const List<String> jiebaAssetCandidates = [
    'assets/jieba_dict/hmm_model.utf8',
    'assets/jieba_dict/idf.utf8',
    'assets/jieba_dict/jieba.dict.utf8',
    'assets/jieba_dict/stop_words.utf8',
    'assets/jieba_dict/user.dict.utf8',
  ];

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (_instance._db != null) return;
    try {
      Directory dbDir;
      try {
        if (Platform.isAndroid) {
          final pkgInfo = await PackageInfo.fromPlatform();
          final pkg = pkgInfo.packageName;
          dbDir = Directory(join('/data/data', pkg, 'databases'));
        } else {
          final dir = await getApplicationDocumentsDirectory();
          dbDir = Directory('${dir.path}/data.db');
        }
      } catch (e) {
        dbDir = Directory.current;
      }
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      final dbPath = join(dbDir.path, 'my.db');
      final jiebaDictPath = join(dbDir.path, 'jieba_dict');
      sqlite3.loadSimpleExtension();

      String? jiebaDictSql;
      final bool shouldCopyFromAssets =
          (Platform.isAndroid || Platform.isWindows || Platform.isLinux) &&
          copyJiebaFromAssets;

      final targetDir = Directory(jiebaDictPath);

      try {
        final possibleFile = File(jiebaDictPath);
        if (await possibleFile.exists()) {
          await possibleFile.delete();
        }

        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } catch (e) {
        print('Failed to prepare jieba_dict directory: $e');
      }

      if (await targetDir.exists()) {
        try {
          if (shouldCopyFromAssets) {
            bool copied = false;
            for (final assetCandidate in jiebaAssetCandidates) {
              try {
                final data = await rootBundle.load(assetCandidate);
                // 将 asset 的内容写入目标目录下的同名文件（而不是写入目录本身）
                final assetFileName = basename(assetCandidate);
                final destFile = File(join(targetDir.path, assetFileName));
                print('Copying $assetCandidate to ${destFile.path} ...');
                await destFile.writeAsBytes(
                  data.buffer.asUint8List(),
                  flush: true,
                );
                jiebaDictSql = await sqlite3.saveJiebaDict(
                  jiebaDictPath,
                  overwriteWhenExist: false,
                );
                print("用于设置结巴分词字典路径（assets 拷贝）：$jiebaDictSql");
                copied = true;
                break;
              } catch (e) {
                print('Failed to copy $assetCandidate: $e');
              }
            }
            if (!copied) {
              print(
                'jieba_dict 目录存在，但未找到可用文件；且从 assets 拷贝失败。'
                '请确认 pubspec.yaml 中已列出 assets/jieba_dict/ 下的具体文件，'
                '或将 copyJiebaFromAssets 设置为 false 来禁用自动拷贝。',
              );
            }
          } else {
            print('jieba_dict 目录存在，但未找到可用文件。跳过结巴字典设置。');
          }
        } catch (e) {
          print('检查 jieba_dict 目录时出错：$e');
        }
      } else if (shouldCopyFromAssets) {
        bool copied = false;

        if (!copied) {
          print(
            'Failed to copy jieba dict from assets. 请确认 pubspec.yaml 中已逐一声明 assets/jieba_dict/ 下的具体文件名，'
            '或将 copyJiebaFromAssets 设置为 false 来禁用自动拷贝。',
          );
        }
      } else {
        print(
          'jieba_dict not found at $jiebaDictPath. Skipping jieba dict setup.',
        );
      }

      // 先打开 sqlite3 数据库，再对其执行 jiebaDictSql（之前执行顺序会失效，因为 _db 为空）
      _instance._db = sqlite3.open(dbPath);
      if (jiebaDictSql != null && jiebaDictSql.isNotEmpty) {
        _instance._db!.execute(jiebaDictSql);
      }

      // 创建表
      for (var tableSql in Tables) {
        _instance._db!.execute(tableSql);
      }

      /// FTS5虚表
      _instance._db?.execute('''
DELETE FROM PicInfo
WHERE id NOT IN (
  SELECT MIN(id)
  FROM PicInfo
  GROUP BY hash
);

    ''');

      /// FTS5虚表
      _instance._db?.execute('''
CREATE VIRTUAL TABLE IF NOT EXISTS PicInfo_fts USING fts5(
  content,              -- 要全文索引的字段（对应 PicInfo.content）
  name UNINDEXED,       -- 不参与索引，但会同步保存，可用作显示或过滤
  path UNINDEXED,
  hash UNINDEXED,
  content='PicInfo',    -- 绑定主表
  content_rowid='id',   -- 关联主表的主键
  tokenize='simple'
);


    ''');

      _instance._db?.execute(
        'INSERT INTO PicInfo_fts(PicInfo_fts) VALUES (\'rebuild\');',
      );
    } catch (e, st) {
      print('AppDatabase init error: $e\n$st');
      rethrow;
    }
  }

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    } else {
      throw Exception('Database not initialized. Call init() first.');
    }
  }

  static Future<Database> getDatabase() async {
    await AppDatabase.init();
    return await _instance.database;
  }

  Future<void> insert(String tableName, Map<String, dynamic> data) async {
    if (_db == null) throw Exception('Database not initialized.');
    if (data.isEmpty) return;

    final columns = data.keys.join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');

    final sql =
        'INSERT OR IGNORE INTO $tableName ($columns) VALUES ($placeholders)';

    final stmt = _db!.prepare(sql);
    try {
      stmt.execute(data.values.toList());
    } finally {
      stmt.dispose();
    }
  }

  Future<void> update(
    String tableName,
    Map<String, dynamic> data,
    String where,
    List<Object?> whereArgs,
  ) async {
    if (_db == null) throw Exception('Database not initialized.');
    if (data.isEmpty) return;

    final setClause = data.keys.map((k) => '$k = ?').join(', ');
    final sql = 'UPDATE $tableName SET $setClause WHERE $where';
    final params = [...data.values, ...whereArgs];
    final stmt = _db!.prepare(sql);
    try {
      stmt.execute(params);
    } finally {
      stmt.dispose();
    }
  }

  Future<void> delete(
    String tableName,
    String where,
    List<Object?> whereArgs,
  ) async {
    if (_db == null) throw Exception('Database not initialized.');

    final sql = 'DELETE FROM $tableName WHERE $where';
    final stmt = _db!.prepare(sql);
    try {
      stmt.execute(whereArgs);
    } finally {
      stmt.dispose();
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String tableName, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (_db == null) return [];

    String sql = 'SELECT * FROM $tableName';
    if (where != null && where.trim().isNotEmpty) {
      sql += ' WHERE $where';
    }

    ResultSet resultSet;
    if (whereArgs == null || whereArgs.isEmpty) {
      resultSet = _db!.select(sql);
    } else {
      final stmt = _db!.prepare(sql);
      try {
        resultSet = stmt.select(whereArgs);
      } finally {
        stmt.dispose();
      }
    }

    return resultSet
        .map(
          (row) => row
              .map((column, value) => MapEntry(column, value))
              .cast<String, dynamic>(),
        )
        .toList();
  }

  Future<void> close() async {
    if (_db != null) {
      _db!.dispose();
      _db = null;
    }
  }
}
