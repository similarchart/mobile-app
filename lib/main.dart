import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_view/model/recent_item.dart';
import 'package:web_view/screen/home_screen.dart';
import 'package:web_view/model/history_item.dart';
import 'package:web_view/services/background_tasks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:web_view/l10n/app_localizations.dart';
import 'package:web_view/providers/language_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:web_view/services/translation_service.dart';

// RouteObserver 객체 생성
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureBackgroundFetch();

  await TranslationService.loadTranslations();
  MobileAds.instance.initialize();

  // Hive 초기화 및 박스 열기
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());
  Hive.registerAdapter(RecentItemAdapter());
  await Hive.openBox<HistoryItem>('history');
  await Hive.openBox<RecentItem>('recent');

  await dotenv.load(fileName: ".env");

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      //  앱에서 다양한 언어로의 전환을 지원하기 위해 필요한 텍스트 리소스를 로드하는 "도우미들"을 지정하는 부분
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ko', ''),
      ],
      home: const HomeScreen(),
      navigatorObservers: [routeObserver], // RouteObserver 추가
    );
  }
}