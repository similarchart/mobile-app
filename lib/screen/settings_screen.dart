import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_view/services/push_notifications_preference.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/services/toast_service.dart';
import 'package:web_view/l10n/app_localizations.dart';
import 'package:web_view/providers/language_provider.dart';
import 'package:web_view/services/preferences.dart';
import 'package:web_view/screen/histroy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final double height = 60;
  late bool _selectedPushNotification;
  late bool _isBottomBarVisible;
  late String? _selectedMainPage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
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
        title: Text(AppLocalizations.of(context).translate('settings'), style: const TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _buildMainPageSetting(context);
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
    return Consumer(
      builder: (context, ref, child) {
        final locale = ref.watch(languageProvider);
        final selectedLanguage = locale?.languageCode ?? 'ko';

        return Container(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('language'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor),
              ),
              DropdownButton<String>(
                value: selectedLanguage,
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
                  ref.read(languageProvider.notifier).setLocale(Locale(value!));
                  String lang = value == 'ko' ? '한국어' : 'English';
                  ToastService().showToastMessage("language : $lang");
                },
                style: const TextStyle(color: AppColors.textColor),
                underline: Container(height: 2, color: AppColors.textColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryAccess(BuildContext context) {
    return Container(
      height: height,
      child: InkWell(
        onTap: () => onHistoryTap(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            AppLocalizations.of(context).translate('history'),
            style: const TextStyle(
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
          title: Text(
            AppLocalizations.of(context).translate('push_notifications'),
            style: const TextStyle(
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
              ToastService().showToastMessage(value ? AppLocalizations.of(context).translate('push_notifications_enabled') : AppLocalizations.of(context).translate('push_notifications_disabled'));
            });
          },
          activeColor: Colors.green,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
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
          title: Text(
            AppLocalizations.of(context).translate('bottom_bar_fixed'),
            style: const TextStyle(
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
              ToastService().showToastMessage(value ? AppLocalizations.of(context).translate('bottom_bar_fixed') : AppLocalizations.of(context).translate('bottom_bar_unfixed'));
            });
          },
          activeColor: Colors.green,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        ),
      ),
    );
  }

  Widget _buildMainPageSetting(BuildContext context) {
    return Container(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).translate('main_page'),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor),
          ),
          DropdownButton<String>(
            value: _selectedMainPage,
            dropdownColor: AppColors.secondaryColor,
            items: [
              DropdownMenuItem(
                  value: 'naver',
                  child: Text(AppLocalizations.of(context).translate('naver_finance'),
                      style: const TextStyle(color: AppColors.textColor))),
              DropdownMenuItem(
                  value: 'chart',
                  child: Text(AppLocalizations.of(context).translate('similar_chart'),
                      style: const TextStyle(color: AppColors.textColor))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMainPage = value;
                MainPagePreference.setMainPageSetting(value!);
                String page = value == 'naver' ? AppLocalizations.of(context).translate('naver_finance') : AppLocalizations.of(context).translate('similar_chart');
                ToastService().showToastMessage("${AppLocalizations.of(context).translate('main_page')} : $page");
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
    Navigator.pop(context, url);
  }
}