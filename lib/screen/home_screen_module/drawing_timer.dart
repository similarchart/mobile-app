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

  int get remainingTimeInSeconds {
    if (_lastDrawingTime == null) return 0; // 타이머가 시작되지 않았다면 0 반환
    Duration timeLeft = _cooldown - DateTime.now().difference(_lastDrawingTime!);
    return timeLeft.isNegative ? 0 : timeLeft.inSeconds; // 남은 시간이 음수가 아니라면 초 단위로 반환, 그렇지 않으면 0 반환
  }

  void resetTimer() {
    _lastDrawingTime = null;
  }
}