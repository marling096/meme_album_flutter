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
import 'package:event_bus/event_bus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await requestStoragePermissionOnStartup(); // 请求存储权限
  await dotenv.load(fileName: '.env');

  String apiKey = dotenv.env['API_KEY'] ?? '';
  String secretKey = dotenv.env['SECRET_KEY'] ?? '';

  List<String> rootdir =
      dotenv.env['rootdir']?.split(',').toList() ?? ['lib/pages'];

  print('rootdir: $rootdir');

  var logger = LoggerManager().logger;

  EventBus eventBus = EventBus();

  await AppDatabase.init();
  PicInfoTable picInfoTable = PicInfoTable(await AppDatabase.instance);
  LoggerTable loggerTable = LoggerTable(await AppDatabase.instance);

  StoreService().registerDao('PicInfo', picInfoTable);
  StoreService().registerDao('Logger', loggerTable);

  runApp(MyApp(eventBus: eventBus, rootdir: rootdir));

  OCRService(StoreService.instance, logger);

  String result = await OcrSync(
    OCRService.instance,
    StoreService.instance,
    eventBus,
    logger,
  ).init();

  // logger.i("Trace log begin");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.eventBus, required this.rootdir});
  final List<String> rootdir;
  final EventBus eventBus;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: Home(eventBus: eventBus, rootdir: rootdir),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key, required this.eventBus, required this.rootdir});

  final EventBus eventBus;
  final List<String> rootdir;

  @override
  State<Home> createState() => _HomeState(rootdir);
}

class _HomeState extends State<Home> {
  StreamSubscription<String>? _sub;
  Timer? _timer;
  final List<String> rootdir;
  _HomeState(this.rootdir);

  @override
  void initState() {
    super.initState();
    // 只在 initState 注册一次
    _sub = widget.eventBus.on<String>().listen((event) {
      GFToast.showToast(
        'EventBus received: $event',
        context,
        toastPosition: GFToastPosition.BOTTOM,
      );
    });

    // _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
    //   widget.eventBus.fire(DateTime.now().second);
    // });
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
              Get.to(() => SettingsPage());
              // Get.changeThemeMode(
              //   Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              // );
            },
          ),
        ],
      ),
      body: Center(child: AlbumPage(this.rootdir)), //['lib/pages', 'lib/store']
    );
  }
}
