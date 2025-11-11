import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
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

  var logger = LoggerManager().logger;

  EventBus eventBus = EventBus();

  await AppDatabase.init();
  PicInfoTable picInfoTable = PicInfoTable(await AppDatabase.instance);
  LoggerTable loggerTable = LoggerTable(await AppDatabase.instance);

  StoreService().registerDao('PicInfo', picInfoTable);
  StoreService().registerDao('Logger', loggerTable);

  runApp(MyApp(eventBus: eventBus));

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
  const MyApp({super.key, required this.eventBus});

  final EventBus eventBus;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      home: Home(eventBus: eventBus),
    );
  }
}

// ...existing code...
class Home extends StatefulWidget {
  const Home({super.key, required this.eventBus});

  final EventBus eventBus;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  StreamSubscription<String>? _sub;
  Timer? _timer;

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
    var rootdir = [''];
    if (Platform.isWindows) {
      rootdir = ['lib/pages', 'lib/store'];
    }
    if (Platform.isAndroid) {
      rootdir = ['storage/emulated/0/Download'];
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
              Get.to(SettingsPage());
              print("setting clickeed");
            },
          ),
          IconButton(
            onPressed: () {
              widget.eventBus.fire("EventBus Test Message");
            },
            icon: Icon(Icons.fork_right),
          ),
        ],
      ),
      body: Center(child: AlbumPage(rootdir)),
    );
  }
}
