import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import '../../main.dart';
import '../../prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) => Material(
    child: SafeArea(
      child: SettingsScreen(
        children: [
          SettingsGroup(
            title: 'History',
            children: [
              SwitchSettingsTile(
                title: 'Record view book history', 
                enabledLabel: 'You can find viewed books in history page.',
                disabledLabel: 'Disabling record doesn\'t clear history!',
                leading: const Icon(Icons.save),
                settingKey: Preferences.kRecordHistory,
                childrenIfEnabled: [
                  SwitchSettingsTile(
                    title: 'Reset history',
                    settingKey: Preferences.kResetHistoryOnBoot,
                    enabledLabel: 'History will be cleared on app launch.',
                    disabledLabel: 'History stay on app relaunch.',
                  ),
                ],
              ),
            ],
          ),
          SimpleSettingsTile(
            title: 'Update tags',
            leading: const Icon(Icons.update),
            subtitle: 'Click to update list of tags.',
            onTap: () async {
              await storage.updateTags();
            },
          ),
          SwitchSettingsTile(
            title: 'Blur', 
            settingKey: Preferences.kBlurImages,
            leading: Icon(preferences.blurImages ? Icons.blur_on : Icons.blur_off),
            enabledLabel: 'Images on screen are blurred.',
            disabledLabel: 'Images shown as is.',
            onChange: (_) => setState(() {}),
          ),
        ],
      ),
    ),
  );

}
