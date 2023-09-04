import 'package:logging/logging.dart';

/// Service which provides other services with information about the state of
/// the app, i.e. if it's in the foreground, minimized, ...
class LifecycleService {
  final Logger _log = Logger('LifecycleService');

  /// Flag indicating whether the app is currently active, i.e. in the foreground (true),
  /// or inactive (false).
  bool _active = false;
  bool get isActive => _active;
  set isActive(bool flag) {
    _log.finest('Setting isActive to $flag');
    _active = flag;
  }
}
