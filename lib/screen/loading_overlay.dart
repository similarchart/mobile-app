import 'package:flutter/material.dart';
import 'package:web_view/services/preferences.dart';

import '../l10n/app_localizations.dart';

class LoadingOverlay {
  static final LoadingOverlay _instance = LoadingOverlay._internal();

  factory LoadingOverlay() {
    return _instance;
  }

  LoadingOverlay._internal();

  OverlayEntry? _overlayEntry;

  void show(BuildContext context) {
    if (_overlayEntry != null) {
      return; // 이미 오버레이가 표시된 경우 무시
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.5), // 반투명 오버레이
          child: Center(
            child: FutureBuilder<String>(
              future: LanguagePreference.getLanguageSetting(), // 현재 언어 설정을 가져옵니다.
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(); // 언어 설정을 로딩 중이면 기본 로딩 인디케이터 표시
                } else if (snapshot.hasData) {
                  String lang = snapshot.data!;
                  // 언어 설정에 따라 다른 GIF 이미지 로드
                  return Image.asset(lang == 'ko'
                      ? 'assets/loading_image.gif'
                      : 'assets/loading_image_en.gif');
                } else {
                  return Text(AppLocalizations.of(context).translate("failed_to_load_loading_image"));
                }
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}