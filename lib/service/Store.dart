import 'dart:async';

import 'package:meme_album/db/database.dart';

class StoreService {
  static final StoreService _instance = StoreService._internal();

  factory StoreService() {
    return _instance;
  }

  StoreService._internal();

  static StoreService get instance => _instance;

  final Map<String, BaseDao> Tables = {};

  void registerDao(String key, BaseDao dao) {
    Tables[key] = dao;
  }

  //CRUD
  Future<int> insert(String tableKey, Map<String, dynamic> values) async {
    final dao = Tables[tableKey];
    if (dao != null) {
      await dao.insert(values);
      return 1; // 返回受影响的行数，假设为1
    } else {
      throw Exception('DAO for $tableKey not found');
    }
  }

  Future<List<Map<String, dynamic>>> queryAll(String tableKey) async {
    final dao = Tables[tableKey];
    if (dao != null) {
      return await dao.queryAll();
    } else {
      throw Exception('DAO for $tableKey not found');
    }
  }

  Future<int> update(String tableKey, Map<String, dynamic> values) async {
    final dao = Tables[tableKey];
    if (dao != null) {
      // 假设更新条件是基于 'id' 字段
      await dao.update(values, 'id = ?', [values['id']]);
      return 1; // 返回受影响的行数，假设为1
    } else {
      throw Exception('DAO for $tableKey not found');
    }
  }

  Future<int> delete(
    String tableKey,
    String where,
    List<Object?> whereArgs,
  ) async {
    final dao = Tables[tableKey];
    if (dao != null) {
      await dao.delete(where, whereArgs);
      return 1; // 返回受影响的行数，假设为1
    } else {
      throw Exception('DAO for $tableKey not found');
    }
  }

  Future<String> search(String tableKey, String query, String tokenizer) async {
    final dao = Tables[tableKey];
    var path = '';
    if (dao != null && dao is PicInfoTable) {
      final result = dao.search(query, tokenizer);
      for (final row in result ?? []) {
        path = row['path'];
        print("--- Search Result ---");
        print('路径: ${row['path']}');
        print('内容高亮: ${row['highlight_content']}');
      }

      return path; // 返回受影响的行数，假设为1或0
    } else {
      throw Exception('DAO for PicInfo not found or invalid');
    }
  }

  Future<List<Map<String, dynamic>>> sort(
    String tableKey,
    String column,
    String orderBy,
    String limit,
  ) async {
    final dao = Tables[tableKey];
    if (dao != null) {
      return await dao.sort(tableKey, column, orderBy, limit);
    } else {
      throw Exception('DAO for $tableKey not found');
    }
  }
}
