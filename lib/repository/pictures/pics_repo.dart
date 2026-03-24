import 'package:meme_album/repository/base.dart';

class PicInfo extends DataModel {
  final String name;
  final String path;
  final String hash;
  final String content;
  final String modifytime;

  PicInfo({
    int? id,
    required this.name,
    required this.path,
    required this.hash,
    required this.content,
    required this.modifytime,
  }) : super(id: id);
}

class PicTableSchema extends TableSchema<PicInfo> {
  @override
  String get tableName => 'PicInfo';

  @override
  List<String> get createTableSql => [
    '''
        CREATE TABLE IF NOT EXISTS $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          path TEXT NOT NULL,
          hash TEXT UNIQUE NOT NULL,
          content TEXT NOT NULL,
          modifytime TEXT NOT NULL, 
          timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        ''',

    // 如果未来需要为主表添加索引，可以直接在这里增加元素
    // 'CREATE INDEX IF NOT EXISTS idx_pic_hash ON $tableName (hash);',
  ];

  PicInfo fromMap(Map<String, dynamic> map) {
    return PicInfo(
      id: map['id'] as int?,
      name: map['name'] as String,
      path: map['path'] as String,
      hash: map['hash'] as String,
      content: map['content'] as String,
      modifytime: map['modifytime'] as String,
    );
  }

  Map<String, dynamic> toMap(PicInfo pic) {
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

class PicsRepo extends BaseDao<PicInfo> {
  // 构造函数：super.table 会被赋值给继承自 BaseDao 的 table 属性
  PicsRepo(super.db, super.table);

  Future<void> insertPic(PicInfo pic) async => await insert(pic);

  /// 优化后的 getList：返回模型对象列表
  Future<List<PicInfo>> getList({
    String sortBy = 'id',
    String order = 'DESC',
    int limit = 20,
    int offset = 0,
  }) async {
    // 1. 校验排序字段和顺序，防止 SQL 注入
    final allowedColumns = ['id', 'name', 'modifytime', 'timestamp'];
    final safeSortBy = allowedColumns.contains(sortBy) ? sortBy : 'id';
    final safeOrder = (order.toUpperCase() == 'ASC') ? 'ASC' : 'DESC';

    final String sql =
        '''
      SELECT * FROM ${table.tableName} 
      ORDER BY $safeSortBy $safeOrder 
      LIMIT ? OFFSET ?
    ''';

    // 2. 执行查询得到 ResultSet
    final results = db.select(sql, [limit, offset]);

    // 3. 将每一行数据 (Row) 转换为 PicInfo 对象
    // 注意：这里使用继承自 BaseDao 的 table 成员进行转换
    return results.map((row) => table.fromMap(row)).toList();
  }
}
