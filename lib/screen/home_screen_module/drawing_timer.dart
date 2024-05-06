// drawing_timer.dart
class DrawingTimer {
  static final DrawingTimer _instance = DrawingTimer._internal();
  factory DrawingTimer() => _instance;

  DrawingTimer._internal();

  DateTime? _lastDrawingTime;
  final Duration _cooldown = const Duration(minutes: 1);

  void startTimer() {
    _lastDrawingTime = DateTime.now();
  }

  bool get isCooldownActive {
    if (_lastDrawingTime == null) return false;
    return DateTime.now().difference(_lastDrawingTime!) < _cooldown;
  }
}
