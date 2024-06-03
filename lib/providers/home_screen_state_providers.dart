import 'package:flutter_riverpod/flutter_riverpod.dart';

// 상태 변수를 관리하는 프로바이더들
final isFirstLoadProvider = StateProvider<bool>((ref) => true);
final showFloatingActionButtonProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final isPageLoadingProvider = StateProvider<bool>((ref) => false);
final subPageLabelProvider = StateProvider<String>((ref) => '');
final homePageLabelProvider = StateProvider<String>((ref) => '');
final didScrollDownProvider = StateProvider<bool>((ref) => true);
final bottomBarFixedPrefProvider = StateProvider<bool>((ref) => true);
final startYProvider = StateProvider<double>((ref) => 0.0);
final isDraggingProvider = StateProvider<bool>((ref) => false);
final isOnHomeScreenProvider = StateProvider<bool>((ref) => true);