import 'package:flutter/material.dart';
import 'package:web_view/screen/histroy_screen.dart';
import 'package:web_view/services/preferences.dart'; // 필요에 따라 수정하세요
import 'package:web_view/services/push_notifications_preference.dart'; // 필요에 따라 수정하세요
import 'package:web_view/constants/colors.dart';
import 'package:web_view/services/toast_service.dart'; // 필요에 따라 수정하세요

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final double height = 60;
  late String? _selectedLanguage;
  late bool _selectedPushNotification;
  late bool _isBottomBarVisible;
  late String? _selectedMainPage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _selectedLanguage = await LanguagePreference.getLanguageSetting();
    _selectedPushNotification =
        await PushNotificationPreference.getPushNotificationSetting();
    _selectedMainPage = await MainPagePreference.getMainPageSetting();
    _isBottomBarVisible = await BottomBarPreference.getIsBottomBarFixed();
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: 5, // 설정 옵션의 수
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _buildMainPageSetting();
                    case 1:
                      return _buildLanguageSetting();
                    case 2:
                      return _buildPushNotificationSetting();
                    case 3:
                      return _buildBottomBarVisibilitySetting();
                    case 4:
                      return _buildHistoryAccess(context);
                    default:
                      return Container();
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

  Widget _buildLanguageSetting() {
    return Container(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '비슷한 차트 페이지 언어',
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
                      style: TextStyle(color: AppColors.textColor))),
              DropdownMenuItem(
                  value: 'en',
                  child: Text('English',
                      style: TextStyle(color: AppColors.textColor))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedLanguage = value;
                LanguagePreference.setLanguageSetting(value!);
                String lang = value == 'ko' ? '한국어' : 'English';
                ToastService().showToastMessage("비슷한 차트 페이지 언어 : $lang");
              });
            },
            style: const TextStyle(color: AppColors.textColor),
            underline: Container(height: 2, color: AppColors.textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAccess(BuildContext context) {
    return Container(
      height: height,
      child: InkWell(
        onTap: () => onHistoryTap(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: const Text(
            '방문 기록',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildPushNotificationSetting() {
    return Container(
      height: height,
      child: Align(
        alignment: Alignment.center,
        child: SwitchListTile(
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
              PushNotificationPreference.setPushNotificationSetting(value);
              ToastService().showToastMessage(value ? "푸시 알림 활성화" : "푸시 알림 비활성화");
            });
          },
          activeColor: Colors.green,
          contentPadding: EdgeInsets.symmetric(horizontal: 0),
        ),
      ),
    );
  }

  Widget _buildBottomBarVisibilitySetting() {
    return Container(
      height: height,
      child: Align(
        alignment: Alignment.center,
        child: SwitchListTile(
          title: const Text(
            '하단 바 고정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          value: _isBottomBarVisible,
          onChanged: (bool value) {
            setState(() {
              _isBottomBarVisible = value;
              BottomBarPreference.setIsBottomBarFixed(value);
              ToastService().showToastMessage(value ? "하단 바 고정" : "하단 바 고정 해제");
            });
          },
          activeColor: Colors.green,
          contentPadding: EdgeInsets.symmetric(horizontal: 0),
        ),
      ),
    );
  }

  Widget _buildMainPageSetting() {
    return Container(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '메인 페이지',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor),
          ),
          DropdownButton<String>(
            value: _selectedMainPage,
            dropdownColor: AppColors.secondaryColor,
            items: const [
              DropdownMenuItem(
                  value: 'naver',
                  child: Text('네이버증권',
                      style: TextStyle(color: AppColors.textColor))),
              DropdownMenuItem(
                  value: 'chart',
                  child: Text('비슷한차트',
                      style: TextStyle(color: AppColors.textColor))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMainPage = value;
                MainPagePreference.setMainPageSetting(value!);
                String page = value == 'naver' ? '네이버증권' : '비슷한차트';
                ToastService().showToastMessage("메인 페이지 : $page");
              });
            },
            style: const TextStyle(color: AppColors.textColor),
            underline: Container(height: 2, color: AppColors.textColor),
          ),
        ],
      ),
    );
  }
}

onHistoryTap(BuildContext context) async {
  String? url = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => HistoryScreen()),
  );
  if (url != null) {
    Navigator.pop(context, url); // apply 문자열 대신 url 반환
  }
}
