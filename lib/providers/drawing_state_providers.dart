import 'package:flutter_riverpod/flutter_riverpod.dart';

final isDrawingLoadingProvider = StateProvider<bool>((ref) => false);
// 쿨다운 상태 관리
final isCooldownCompletedProvider = StateProvider<bool>((ref) => true);
// 마지막 드로잉 시간 관리
final lastDrawingTimeProvider = StateProvider<DateTime?>((ref) => null);
// 쿨다운 지속 시간 관리
final cooldownDurationProvider = StateProvider<Duration>((ref) => const Duration(seconds: 60));