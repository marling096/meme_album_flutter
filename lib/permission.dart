import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 启动时申请合适的存储权限
Future<void> requestStoragePermissionOnStartup() async {
  if (!Platform.isAndroid) return;

  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final sdkInt = androidInfo.version.sdkInt;

  print("📱 Android SDK: $sdkInt");

  if (sdkInt >= 33) {
    // Android 13+（含 Android 14）
    final result = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    if (result.values.any((r) => r.isGranted)) {
      print("✅ 已获取媒体访问权限");
    } else {
      print("⚠️ 权限被拒绝，尝试打开设置页");
      await openAppSettings();
    }
  } else if (sdkInt >= 30) {
    // Android 11–12
    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      print("✅ 已获取所有文件访问权限");
    } else {
      print("⚠️ 无法自动授权，请手动前往设置开启权限");
      await openAppSettings();
    }
  } else {
    // Android 10 及以下
    final status = await Permission.storage.request();
    if (status.isGranted) {
      print("✅ 已获取存储权限");
    } else {
      print("❌ 用户拒绝存储权限");
    }
  }
}
