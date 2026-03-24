import 'package:logger/logger.dart';

abstract class BaseService {
  String get serviceName;

  Logger get logger;
}
