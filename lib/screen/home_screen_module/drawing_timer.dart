import 'package:flutter/material.dart';

class DrawingTimer {
  static final DrawingTimer _instance = DrawingTimer._internal();
  factory DrawingTimer() => _instance;

  DrawingTimer._internal();

  DateTime? _lastDrawingTime;
  Duration _cooldown = const Duration(seconds: 60);
  ValueNotifier<bool> isCooldownCompleted = ValueNotifier<bool>(false);

  void startTimer(int seconds) {
    _cooldown = Duration(seconds: seconds);
    _lastDrawingTime = DateTime.now();
    isCooldownCompleted.value = false;

    // 타이머 시작
    Future.delayed(_cooldown, () {
      isCooldownCompleted.value = true;
    });
  }

  bool get isCooldownActive {
    if (_lastDrawingTime == null) return false;
    return DateTime.now().difference(_lastDrawingTime!) < _cooldown;
  }

  int get remainingTimeInSeconds {
    if (_lastDrawingTime == null) return 0;
    Duration timeLeft = _cooldown - DateTime.now().difference(_lastDrawingTime!);
    return timeLeft.isNegative ? 0 : timeLeft.inSeconds;
  }

  void resetTimer() {
    _lastDrawingTime = null;
    isCooldownCompleted.value = false;
  }
}
