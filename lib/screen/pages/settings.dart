import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:domain_verification_manager/domain_verification_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import '../../main.dart';
import '../../prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AfterLayoutMixin<SettingsPage>, WidgetsBindingObserver {
  bool _isSupported = false;
  List<String> _domainStateSelected = [];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if(kDebugMode)
      print(state);
    if(state == AppLifecycleState.resumed) {
      if(_isSupported) 
        await getDomainStateSelected();
    }
    
    super.didChangeAppLifecycleState(state);
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    if (await getIsSupported())
      getDomainStateSelected();
  }

  Future<bool> getIsSupported() async {
    var result = false;
    
    try {
      result = await DomainVerificationManager.isSupported;
    } on PlatformException {
      if(kDebugMode)
        print('DomainVerificationManager unsupported platform.');
    }
    if (!mounted)
      return result;

    setState(() {
      _isSupported = result;
    });

    return result;
  }

  Future<void> getDomainStateSelected() async {
    List<String>? result;
    try {
      result = await DomainVerificationManager.domainStageSelected;
    } on PlatformException {
      if(kDebugMode)
        print('DomainVerificationManager unsupported platform.');
    }
    if(kDebugMode)
      print(mounted);

    if (!mounted)
      return;

    setState(() {
      _domainStateSelected = result ?? [];
    });
  }

  Future<void> domainRequest() async {
    await DomainVerificationManager.domainRequest();
  }

  @override
  void activate() {
    if(kDebugMode)
      print('Activated');
    super.activate();
    setState(() { });
  }

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
          if(_isSupported)
            ListTile(
              leading: _domainStateSelected.isNotEmpty 
                ? const Icon(Icons.link) 
                : const Icon(Icons.link_off),
              title: Text(
                'App links',
                style: Theme.of(context).textTheme.headline6?.copyWith(fontSize: 16.0),
              ),
              subtitle: Text(
                _domainStateSelected.isNotEmpty 
                  ? 'nhentai.net urls will be opened in app' 
                  : 'nhentai.net urls will be opened in browser',
                style: Theme.of(context).textTheme.subtitle2
                  ?.copyWith(fontSize: 13.0, fontWeight: FontWeight.normal),  
              ),
              onTap: () async => DomainVerificationManager.domainRequest(),
              trailing: Switch.adaptive(
                value: _domainStateSelected.isNotEmpty,
                onChanged: (_) async => DomainVerificationManager.domainRequest(),
                activeColor: Theme.of(context).colorScheme.secondary,
              ),
              dense: true,
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
