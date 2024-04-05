import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_view/screen/histroy_screen.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/constants/colors.dart';
import 'package:web_view/services/toast_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadLanguageSetting();
  }

  Future<void> _loadLanguageSetting() async {
    _selectedLanguage = await LanguagePreference.getLanguageSetting();
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
                itemCount: 2, // '언어' 설정과 '방문기록'을 포함한 항목 수
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
