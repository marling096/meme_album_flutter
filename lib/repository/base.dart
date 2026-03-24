import 'package:sqlite3/sqlite3.dart';

abstract class DataModel {
  final int? id;
  DataModel({this.id});
}

/// T 是业务模型类
abstract class TableSchema<T extends DataModel> {
  String get tableName;
  List<String> get createTableSql;

  T fromMap(Map<String, dynamic> map);

  Map<String, dynamic> toMap(T entity);

  Map<String, dynamic> getIdMap(T entity) => {'id': entity.id};
}

abstract class BaseDao<T extends DataModel> {
  final Database db;
  final TableSchema<T> table;

  BaseDao(this.db, this.table);

  R _executeSafe<R>(
    String sql,
    List<Object?> params,
    R Function(PreparedStatement) action,
  ) {
    final stmt = db.prepare(sql);
    try {
      return action(stmt);
    } catch (e) {
      throw Exception('Database Error: $e\nSQL: $sql\nParams: $params');
    } finally {
      stmt.dispose();
    }
  }

  Future<int> insert(T entity) async {
    final data = table.toMap(entity)..remove('id');
    final cols = data.keys.join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');

    final sql = 'INSERT INTO ${table.tableName} ($cols) VALUES ($placeholders)';
    final values = data.values.toList();

    return _executeSafe(sql, values, (stmt) {
      stmt.execute(values);
      return db.lastInsertRowId;
    });
  }

  Future<int> update(T entity) async {
    final data = table.toMap(entity);
    final id = data.remove('id');
    if (id == null)
      throw ArgumentError('Entity ID cannot be null during update');

    final setClause = data.keys.map((c) => '$c = ?').join(', ');
    final sql = 'UPDATE ${table.tableName} SET $setClause WHERE id = ?';
    final values = [...data.values, id];

    return _executeSafe(sql, values, (stmt) {
      stmt.execute(values);
      return db.updatedRows;
    });
  }

  Future<T?> findById(int id) async {
    final sql = 'SELECT * FROM ${table.tableName} WHERE id = ? LIMIT 1';

    return _executeSafe(sql, [id], (stmt) {
      final result = stmt.select([id]);
      if (result.isEmpty) return null;
      return table.fromMap(result.first);
    });
  }

  Future<int> delete(int id) async {
    final sql = 'DELETE FROM ${table.tableName} WHERE id = ?';
    return _executeSafe(sql, [id], (stmt) {
      stmt.execute([id]);
      return db.updatedRows;
    });
  }
}
