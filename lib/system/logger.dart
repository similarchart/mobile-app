import 'package:logger/logger.dart';

class Log {
  static final Logger _logger = Logger();

  static Logger get instance => _logger;
}