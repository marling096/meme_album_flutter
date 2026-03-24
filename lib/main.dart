import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

// Your internal imports
import 'package:meme_album/ui/page/home/home_page.dart';
import 'package:meme_album/app/initializer/appInitializer.dart';
import 'permission.dart';

// Global GetIt instance
final GetIt get_it = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initial permissions and dependency registration
  await requestStoragePermissionOnStartup();
  await AppInitializer(get_it).initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Meme Album',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      // Home no longer needs parameters passed in
      home: Home(get_it: get_it),
    );
  }
}
