import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';


// Cooldown state management
class CooldownNotifier extends StateNotifier<int> {
  Timer? _timer;

  CooldownNotifier() : super(0);

  void startCooldown(int seconds) {
    state = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// cooldownDurationProvider는 CooldownNotifier 클래스의 state 변수와 연결되어 있습니다.
final cooldownDurationProvider = StateNotifierProvider<CooldownNotifier, int>((ref) {
  return CooldownNotifier();
});

// Last drawing time management
final lastSearchTimeProvider = StateProvider<DateTime?>((ref) => null);

// Cooldown completed management
final isCooldownCompletedProvider = Provider<bool>((ref) {
  return ref.watch(cooldownDurationProvider) == 0;
});
