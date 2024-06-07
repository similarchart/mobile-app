import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_view/providers/search_state_providers.dart';

class SearchingTimer {
  final WidgetRef ref;

  SearchingTimer(this.ref);

  void startTimer(int seconds) {
    ref.read(lastSearchTimeProvider.notifier).state = DateTime.now();
    ref.read(cooldownDurationProvider.notifier).startCooldown(seconds);
  }

  bool get isCooldownActive {
    return ref.read(cooldownDurationProvider) > 0;
  }

  int get remainingTimeInSeconds {
    return ref.read(cooldownDurationProvider);
  }

  void resetTimer() {
    ref.read(lastSearchTimeProvider.notifier).state = null;
    ref.read(cooldownDurationProvider.notifier).startCooldown(0);
  }
}
