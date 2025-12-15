import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'dart:io';
import 'package:meme_album/pages/album/album.dart';
import 'package:meme_album/pages/search/search_box.dart';
import 'package:meme_album/pages/settings/settings.dart';
import 'permission.dart';

import 'package:meme_album/db/database.dart';
import 'package:meme_album/service/ocr.dart';
import 'package:meme_album/service/store.dart';
import 'package:meme_album/service/ocr_sync.dart';

import 'package:meme_album/utils/log_manger.dart';
import 'package:meme_album/utils/album_utils.dart';
import 'package:event_bus/event_bus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestStoragePermissionOnStartup(); // 请求存储权限
  await dotenv.load(fileName: '.env');

  String apiKey = dotenv.env['API_KEY'] ?? '';
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';

  List<String> albumDir = [];
  String logFile = '';
  if (Platform.isAndroid) {
    albumDir = albumDir =
        dotenv.env['android_albumDir']?.split(',').toList() ??
        ['storage/emulated/0/Download'];
    logFile =
        dotenv.env['android_logFile'] ?? 'storage/emulated/0/Download/logs.txt';
  }
  if (Platform.isWindows || Platform.isLinux) {
    albumDir = dotenv.env['win_albumDir']?.split(',').toList() ?? ['lib/pages'];
    logFile = dotenv.env['win_logFile'] ?? 'logs.txt';
  }

  // print('albumDir: $albumDir');

  var logger = LoggerManager((File(logFile))).logger;

  EventBus eventBus = EventBus();

  await AppDatabase.init();
  PicInfoTable picInfoTable = PicInfoTable(AppDatabase.instance);
  LoggerTable loggerTable = LoggerTable(AppDatabase.instance);

  StoreService().registerDao('PicInfo', picInfoTable);
  StoreService().registerDao('Logger', loggerTable);

  OCRService(StoreService.instance, logger);

  // String result = await OcrSync(
  //   OCRService.instance,
  //   StoreService.instance,
  //   eventBus,
  //   logger,
  //   albumDir,
  // ).init();

  runApp(MyApp(eventBus: null, albumDir: albumDir));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.eventBus, required this.albumDir});
  final List<String> albumDir;
  final EventBus? eventBus;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: Home(eventBus: eventBus, albumDir: albumDir),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, this.eventBus, required this.albumDir});

  final EventBus? eventBus;
  final List<String> albumDir;

  @override
  State<Home> createState() => _HomeState(albumDir);
}

class _HomeState extends State<Home> {
  StreamSubscription<String>? _sub;
  Timer? _timer;
  final List<String> albumDir;
  _HomeState(this.albumDir);

  @override
  void initState() {
    super.initState();
    // 只在 initState 注册一次
    _sub = widget.eventBus?.on<String>().listen((event) {
      GFToast.showToast(
        'EventBus received: $event',
        context,
        toastPosition: GFToastPosition.BOTTOM,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SearchBox(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Get.to(() => SettingsPage(eventBus: widget.eventBus));
              // Get.changeThemeMode(
              //   Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              // );
            },
          ),
        ],
      ),
      body: Center(child: AlbumPage(albumDir)), //['lib/pages', 'lib/store']
    );
  }
}
