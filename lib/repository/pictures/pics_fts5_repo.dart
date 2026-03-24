import 'package:meme_album/repository/base.dart';
import 'package:sqlite3/sqlite3.dart';

class PicInfo_fts5 extends DataModel {
  final String name;
  final String path;
  final String hash;
  final String content;
  final String modifytime;

  PicInfo_fts5({
    int? id,
    required this.name,
    required this.path,
    required this.hash,
    required this.content,
    required this.modifytime,
  }) : super(id: id);
}

class PicFTS5TableSchema extends TableSchema<PicInfo_fts5> {
  // 假设物理主表的名字叫 'PicInfo'
  final String sourceTableName = 'PicInfo';

  @override
  String get tableName => 'PicInfo_fts'; // 这是虚表的名字

  @override
  List<String> get createTableSql => [
    '''
  -- 1. 创建 FTS5 虚表
  CREATE VIRTUAL TABLE IF NOT EXISTS $tableName USING fts5(
    content,
    name UNINDEXED,
    path UNINDEXED,
    hash UNINDEXED,
    modifytime UNINDEXED, -- 声明了 5 个数据列
    content='$sourceTableName',
    content_rowid='id',
    tokenize='simple'
  );
  ''',

    '''
  -- 2. INSERT 触发器 (必须包含所有声明的字段)
  CREATE TRIGGER IF NOT EXISTS trg_${sourceTableName}_ai AFTER INSERT ON $sourceTableName 
  BEGIN
    INSERT INTO $tableName(rowid, content, name, path, hash, modifytime)
    VALUES (new.id, new.content, new.name, new.path, new.hash, new.modifytime);
  END;
  ''',

    '''
  -- 3. DELETE 触发器
  CREATE TRIGGER IF NOT EXISTS trg_${sourceTableName}_ad AFTER DELETE ON $sourceTableName 
  BEGIN
    INSERT INTO $tableName($tableName, rowid, content, name, path, hash, modifytime)
    VALUES('delete', old.id, old.content, old.name, old.path, old.hash, old.modifytime);
  END;
  ''',

    '''
  -- 4. UPDATE 触发器
  CREATE TRIGGER IF NOT EXISTS trg_${sourceTableName}_au AFTER UPDATE ON $sourceTableName 
  BEGIN
    -- 删除旧索引
    INSERT INTO $tableName($tableName, rowid, content, name, path, hash, modifytime)
    VALUES('delete', old.id, old.content, old.name, old.path, old.hash, old.modifytime);
    -- 插入新索引
    INSERT INTO $tableName(rowid, content, name, path, hash, modifytime)
    VALUES (new.id, new.content, new.name, new.path, new.hash, new.modifytime);
  END;
  ''',
  ];
  @override
  PicInfo_fts5 fromMap(Map<String, dynamic> map) {
    // FTS 查询返回的行可以直接映射
    return PicInfo_fts5(
      id: map['id'] as int?,
      name: map['name'] as String,
      path: map['path'] as String,
      hash: map['hash'] as String,
      content: map['content'] as String,
      modifytime: map['modifytime']?.toString() ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap(PicInfo_fts5 pic) {
    // 虚表通常不直接调用 insert/update，而是由主表触发
    return {
      'id': pic.id,
      'name': pic.name,
      'path': pic.path,
      'hash': pic.hash,
      'content': pic.content,
      'modifytime': pic.modifytime,
    };
  }
}

class PicFTS5Repo extends BaseDao<PicInfo_fts5> {
  PicFTS5Repo(super.db, super.table);

  List<PicInfo_fts5> search(String value, {String tokenizer = 'jieba'}) {
    // 1. 预处理查询关键词：去掉空格，防止 MATCH 语法错误
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) return [];

    // 2. 根据分词器构造逻辑
    // 注意：如果是 jieba，必须调用 jieba_query(?) 才能实现语义分词
    // 如果是 simple，建议配合 * 实现前缀匹配
    final isJieba = tokenizer == 'jieba';
    final String matchQuery = isJieba ? "jieba_query(?)" : "simple_query(?)";

    // 对于 simple 模式，如果需要前缀匹配，value 需要处理成 '关键词*'
    // 但注意：jieba_query 内部通常不建议带 *，除非该插件版本明确支持
    final dynamic queryParam = isJieba ? cleanValue : '$cleanValue*';

    const String wrapperLeft = '<b>';
    const String wrapperRight = '</b>';

    // 3. 使用 simple_highlight 代替内置 highlight
    // 原因：对于外部内容表，内置 highlight 需要回表查询，性能极差
    // 且 simple 插件提供的 simple_highlight 对中文支持更好
    final sql =
        '''
    SELECT
      p.id, p.name, p.path, p.hash, p.modifytime,
      simple_highlight(PicInfo_fts, 0, '$wrapperLeft', '$wrapperRight') AS highlight_content
    FROM PicInfo_fts
    JOIN PicInfo AS p ON p.id = PicInfo_fts.rowid
    WHERE PicInfo_fts MATCH $matchQuery
    ORDER BY rank;
  ''';

    try {
      final resultSet = db.select(sql, [queryParam]);

      return resultSet.map((row) {
        return PicInfo_fts5(
          id: row['id'] as int?,
          name: row['name'] as String,
          path: row['path'] as String,
          hash: row['hash'] as String,
          // 如果高亮失败或没匹配到，取原表的 content
          content:
              (row['highlight_content'] as String?) ??
              (row['content'] as String? ?? ''),
          modifytime: row['modifytime'] as String,
        );
      }).toList();
    } catch (e) {
      print('FTS Search Error: $e');
      return [];
    }
  }
}
