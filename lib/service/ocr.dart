import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:meme_album/service/store.dart';
import 'package:path/path.dart' as p;

const API_KEY = '81xqnAWAyMk5cLWVV5C46nLQ';
const SECRET_KEY = 'hN7WhFk1xCM8fcM1GgUB5jfNBXWTvWoc';
const TOKEN_URL =
    'https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=$API_KEY&client_secret=$SECRET_KEY';
const OCR_URL =
    'https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token={access_token}';

String access_token = '';

var logger = Logger();

class OCRService {
  late StoreService store;
  late Logger logger;
  static final OCRService _instance = OCRService._internal();
  factory OCRService(StoreService store, Logger logger) {
    _instance.store = store;
    _instance.logger = logger;
    return _instance;
  }
  static OCRService get instance => _instance;
  OCRService._internal();

  Future<String> fetchAccessToken() async {
    final response = await http.get(Uri.parse(TOKEN_URL));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      access_token = data['access_token'];
      return access_token;
    } else {
      throw Exception('Failed to fetch access token');
    }
  }

  Future<String> performOCR(String imageBase64, {bool retry = true}) async {
    if (access_token.isEmpty) {
      await fetchAccessToken();
    }

    final url = OCR_URL.replaceFirst('{access_token}', access_token);
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'image': imageBase64},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey('error_code') && retry) {
        await fetchAccessToken();
        return performOCR(imageBase64, retry: false);
      }

      if (data.containsKey('words_result')) {
        final List<dynamic> wordsResult = data['words_result'];
        StringBuffer ocrText = StringBuffer();
        for (var item in wordsResult) {
          ocrText.writeln(item['words']);
        }
        // print(ocrText.toString());
        return ocrText.toString();
      } else {
        return '';
      }
    } else {
      throw Exception('Failed to perform OCR');
    }
  }

  Future<String> ocrImageFile(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final imageBase64 = base64Encode(bytes);
    final ocrResult = await performOCR(imageBase64);

    final fileHash = md5.convert(bytes).toString();
    final fileName = p.basename(imagePath);

    final modifytime = (await File(imagePath).lastModified()).toIso8601String();

    await store.insert('PicInfo', {
      'name': fileName,
      'path': imagePath,
      'hash': fileHash,
      'content': ocrResult,
      'modifytime': modifytime,
    });

    logger.i('OCR processed for $fileName, $imagePath, $fileHash, $modifytime');
    // await store.insert('Logger', {
    //   'log': 'OCR processed for $fileName',
    //   'timestamp': DateTime.now().toIso8601String(),
    // });

    // var result = await store.sort('Logger', 'timestamp', 'DESC');
    // print("--- Logger Entries ---");
    // for (var entry in result) {
    //   print('Log: ${entry['log']}');
    //   print('Timestamp: ${entry['timestamp']}');
    // }
    sleep(Duration(milliseconds: 500)); // 延时0.5秒
    return ocrResult;
  }
}
