import 'package:flutter/material.dart';

class DrawingTimer {
  static final DrawingTimer _instance = DrawingTimer._internal();
  factory DrawingTimer() => _instance;

  DrawingTimer._internal();

  DateTime? _lastDrawingTime;
  Duration _cooldown = const Duration(seconds: 60);
  VoidCallback? onTimerComplete;  // 타이머 완료시 호출될 콜백

  void startTimer(int seconds, {VoidCallback? onComplete}) {
    _cooldown = Duration(seconds: seconds);
    _lastDrawingTime = DateTime.now();
    onTimerComplete = onComplete;  // 콜백 저장
    // 타이머 시작
    Future.delayed(_cooldown, () {
      if (onTimerComplete != null) {
        onTimerComplete!();
      }
    });
  }

  bool get isCooldownActive {
    if (_lastDrawingTime == null) return false;
    return DateTime.now().difference(_lastDrawingTime!) < _cooldown;
  }

  void resetTimer() {
    _lastDrawingTime = null;
  }
}