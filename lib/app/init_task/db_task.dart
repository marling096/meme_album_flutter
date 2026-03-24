import 'package:meme_album/app/init_task/base.dart';

import 'package:sqlite3/sqlite3.dart';
import 'package:meme_album/repository/base.dart';
import 'package:meme_album/core/database/database.dart';
import 'package:meme_album/repository/pictures/pics_repo.dart';
import 'package:meme_album/repository/pictures/pics_fts5_repo.dart';

import 'package:get_it/get_it.dart';

class db_task extends InitTask {
  final GetIt _getIt;
  db_task(this._getIt);

  @override
  Future<void> execute() async {
    await AppDatabase.init();
    final dbApp = await AppDatabase.instance.database;

    List<TableSchema> Tables = [PicTableSchema(), PicFTS5TableSchema()];

    _getIt.registerSingleton<Database>(dbApp);
    _getIt.registerLazySingleton(() => PicsRepo(dbApp, PicTableSchema()));
    _getIt.registerLazySingleton(
      () => PicFTS5Repo(dbApp, PicFTS5TableSchema()),
    );

    for (var table in Tables) {
      for (var sql in table.createTableSql) {
        dbApp.execute(sql);
      }
    }
  }
}
