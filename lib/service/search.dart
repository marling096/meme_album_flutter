import 'package:meme_album/repository/pictures/pics_repo.dart';
import 'package:meme_album/repository/pictures/pics_fts5_repo.dart';

import 'package:logger/logger.dart';
import 'package:event_bus/event_bus.dart';

class Search {
  final EventBus eventbus;
  final Logger logger;
  final PicsRepo picsRepo;
  final PicFTS5Repo picFTS5Repo;

  Search({
    required this.eventbus,
    required this.logger,
    required this.picsRepo,
    required this.picFTS5Repo,
  });
  List<String> searchPics(String query, {String tokenizer = 'jieba'}) {
    List<PicInfo_fts5> results = picFTS5Repo.search(
      query,
      tokenizer: tokenizer,
    );
    List<String> PicPaths = [];
    for (var pic in results) {
      print('--- Search Result ---');
      PicPaths.add(pic.path);
    }

    return PicPaths;
  }
}
