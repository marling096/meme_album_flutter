import 'package:meme_album/app/init_task/base.dart';
import 'package:meme_album/app/init_task/db_task.dart';
import 'package:meme_album/app/init_task/env_task.dart';
import 'package:meme_album/app/init_task/services_task.dart';
import 'package:get_it/get_it.dart';

class AppInitializer {
  final GetIt _getIt;
  AppInitializer(this._getIt);
  Future<void> initialize() async {
    List<InitTask> tasks = [
      Env_Task(_getIt),
      db_task(_getIt),
      ServicesTask(_getIt),
    ];

    for (var task in tasks) {
      await task.execute();
    }
  }
}
