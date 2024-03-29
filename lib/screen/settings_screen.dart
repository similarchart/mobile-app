import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_view/services/language_preference.dart';
import 'package:web_view/constants/colors.dart'; // 색상 상수 import

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
        title: Text('설정', style: TextStyle(color: AppColors.textColor)),
        backgroundColor: AppColors.secondaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '언어',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                Spacer(), // 텍스트와 드롭다운 사이에 공간을 추가합니다.
                DropdownButton<String>(
                  // 드롭다운 버튼의 크기를 강제로 제한하지 않고 내용에 맞게 조절합니다.
                  value: _selectedLanguage,
                  dropdownColor: AppColors.secondaryColor,
                  items: [
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
                    });
                  },
                  style: TextStyle(color: AppColors.textColor),
                  underline: Container(height: 2, color: AppColors.textColor),
                ),
              ],
            ),
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    child: Text('적용'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor, // 버튼의 배경색 설정
                      foregroundColor: AppColors.textColor, // 버튼의 텍스트 색상 설정
                      elevation: 5, // 버튼의 그림자 정도
                      shape: RoundedRectangleBorder( // 버튼의 모양 정의
                        borderRadius: BorderRadius.circular(10), // 모서리를 둥글게
                        side: BorderSide(color: AppColors.secondaryColor, width: 2), // 테두리 색상과 두께
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
