import 'dart:async';
import 'dart:io';
import 'package:get_it/get_it.dart';

import 'package:meme_album/app/init_task/base.dart';
import 'package:meme_album/repository/pictures/pics_repo.dart';
import 'package:meme_album/repository/pictures/pics_fts5_repo.dart';

import 'package:meme_album/core/utils/log_manger.dart';
import 'package:event_bus/event_bus.dart';
import 'package:logger/logger.dart';

import 'package:meme_album/core/config/env_impl.dart';

import 'package:meme_album/service/search.dart';
import 'package:meme_album/service/ocr_sync.dart';

class ServicesTask extends InitTask {
  final GetIt _getIt;
  ServicesTask(this._getIt);

  late final EventBus _eventBus;
  late final Logger _logger;

  @override
  Future<void> execute() async {
    _eventBus = EventBus();

    final env = _getIt<IEnv>();
    _logger = LoggerManager(File(env.logFile)).logger;

    if (!_getIt.isRegistered<EventBus>()) {
      _getIt.registerSingleton<EventBus>(_eventBus);
    }
    if (!_getIt.isRegistered<Logger>()) {
      _getIt.registerSingleton<Logger>(_logger);
    }

    final picsRepo = _getIt<PicsRepo>();
    final picFTS5Repo = _getIt<PicFTS5Repo>();

    _getIt.registerLazySingleton<Search>(
      () => Search(
        eventbus: _eventBus,
        logger: _logger,
        picsRepo: picsRepo,
        picFTS5Repo: picFTS5Repo,
      ),
    );

    _getIt.registerLazySingleton<OcrSync>(
      () => OcrSync(_eventBus, _logger, picsRepo, picFTS5Repo, env.albumDir),
    );
  }
}
