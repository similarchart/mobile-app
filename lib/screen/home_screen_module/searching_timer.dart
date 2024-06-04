import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_view/providers/search_state_providers.dart';

class SearchingTimer {
  final WidgetRef ref;

  SearchingTimer(this.ref);

  void startTimer(int seconds) {
    ref.read(cooldownDurationProvider.notifier).state = Duration(seconds: seconds);
    ref.read(lastSearchTimeProvider.notifier).state = DateTime.now();
    ref.read(isCooldownCompletedProvider.notifier).state = false;

    Future.delayed(ref.read(cooldownDurationProvider), () {
      ref.read(isCooldownCompletedProvider.notifier).state = true;
    });
  }

  bool get isCooldownActive {
    DateTime? lastDrawingTime = ref.read(lastSearchTimeProvider);
    if (lastDrawingTime == null) return false;
    return DateTime.now().difference(lastDrawingTime) < ref.read(cooldownDurationProvider);
  }

  int get remainingTimeInSeconds {
    DateTime? lastDrawingTime = ref.read(lastSearchTimeProvider);
    if (lastDrawingTime == null) return 0;
    Duration timeLeft = ref.read(cooldownDurationProvider) - DateTime.now().difference(lastDrawingTime);
    return timeLeft.isNegative ? 0 : timeLeft.inSeconds;
  }

  void resetTimer() {
    ref.read(lastSearchTimeProvider.notifier).state = null;
    ref.read(isCooldownCompletedProvider.notifier).state = false;
  }
}
