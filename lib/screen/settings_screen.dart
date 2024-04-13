import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_view/screen/histroy_screen.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/services/push_notifications_preference.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/services/toast_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedLanguage;
  late bool _selectedPushNotification;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _selectedLanguage = await LanguagePreference.getLanguageSetting();
    _selectedPushNotification =
        await PushNotificationPreference.getPushNotificationSetting();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: 3, // '언어' 설정과 '방문기록'을 포함한 항목 수
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // '언어' 설정 항목
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '언어',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor),
                        ),
                        DropdownButton<String>(
                          value: _selectedLanguage,
                          dropdownColor: AppColors.secondaryColor,
                          items: const [
                            DropdownMenuItem(
                                value: 'ko',
                                child: Text('한국어',
                                    style:
                                        TextStyle(color: AppColors.textColor))),
                            DropdownMenuItem(
                                value: 'en',
                                child: Text('English',
                                    style:
                                        TextStyle(color: AppColors.textColor))),
                          ],
                          onChanged: (value) {
                            setState(
                              () {
                                _selectedLanguage = value;
                                LanguagePreference.setLanguageSetting(value!);
                                ToastService().showToastMessage("적용되었습니다");
                              },
                            );
                          },
                          style: const TextStyle(color: AppColors.textColor),
                          underline:
                              Container(height: 2, color: AppColors.textColor),
                        ),
                      ],
                    );
                  } else if (index == 1) {
                    // '방문기록' 항목
                    return InkWell(
                      onTap: () => onHistoryTap(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          '방문기록',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textColor),
                        ),
                      ),
                    );
                  } else if (index == 2) {
                    // '푸시 알림 허용' 설정 항목
                    return SwitchListTile(
                      title: const Text(
                        '푸시 알림 허용',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      value: _selectedPushNotification,
                      onChanged: (bool value) {
                        setState(() {
                          _selectedPushNotification = value;
                          // 여기에 푸시 알림 설정을 저장하는 코드를 넣으세요.
                          ToastService().showToastMessage("적용되었습니다");
                        });
                      },
                      activeColor: AppColors.textColor,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 0), // 좌우 패딩을 0으로 조정
                      // 다른 항목들과 패딩을 맞추기 위해 필요하다면 위 값을 조정하세요.
                    );
                  } else {
                    return Container(); // 확장을 위한 여분의 공간
                  }
                },
                separatorBuilder: (context, index) =>
                    const Divider(color: AppColors.tertiaryColor, height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

onHistoryTap(BuildContext context) async {
  String? url = await Navigator.push(
    // 설정에서 들어간 방문기록에서 기록을 누르면 url를 받음
    context,
    MaterialPageRoute(builder: (context) => HistoryScreen()),
  );
  if (url != null) {
    Navigator.pop(context, url); // apply 문자열 대신 url 반환
  }
}
