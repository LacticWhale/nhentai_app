import 'dart:async';
import 'dart:io';

import 'package:domain_verification_manager/domain_verification_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import '../../api.dart';
import '../../main.dart';
import '../../prefs.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static String? cachedAgent;

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
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
    if(_isSupported && state == AppLifecycleState.resumed)
      setState(() { });
    
    super.didChangeAppLifecycleState(state);
  }

  Future<bool> getIsSupported() async {
    try {
      return _isSupported = await DomainVerificationManager.isSupported;
    } on PlatformException {
      if(kDebugMode)
        print('DomainVerificationManager unsupported platform.');
    }

    return _isSupported;
  }

  Future<void> getDomainStateSelected() async {
    List<String>? result;
    try {
      result = await DomainVerificationManager.domainStageSelected;
    } on PlatformException {
      if(kDebugMode)
        print('DomainVerificationManager unsupported platform.');
    }
    
    _domainStateSelected = result ?? [];
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
                defaultValue: preferences.recordHistory,
                childrenIfEnabled: [
                  SwitchSettingsTile(
                    title: 'Reset history',
                    settingKey: Preferences.kResetHistoryOnBoot,
                    defaultValue: preferences.resetHistoryOnBoot,
                    enabledLabel: 'History will be cleared on app launch.',
                    disabledLabel: 'History stay on app relaunch.',
                  ),
                ],
              ),
            ],
          ),
          SettingsGroup(
            title: 'Global',
            children: [
              FutureBuilder<void>(
                // ignore: discarded_futures
                future: (() async {
                  if(await getIsSupported())
                    await getDomainStateSelected();
                })(),
                builder: (context, snapshot) {
                  if(snapshot.connectionState != ConnectionState.done)
                    return const SizedBox.shrink();
                  
                  if(!_isSupported)
                    return const SizedBox.shrink();

                  return ListTile(
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
                  );
                },
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
                onChange: (value) {
                  if(kDebugMode)
                    print('${Preferences.kBlurImages}: $value');
                },
              ),
            ],
          ),
          SettingsGroup(
            title: 'Networking', 
            children: [
              if(Platform.isWindows)
                TextInputSettingsTile(
                  onChange: (p0) => SettingsPage.cachedAgent = p0,
                  title: 'user agent', 
                  settingKey: 'none2',
                  initialValue: MyApp.userAgent,
                ),
              if(Platform.isWindows)
                TextInputSettingsTile(
                  title: 'cf_clearance',
                  settingKey: 'cf_clearance_value',
                ),
            ],
          ),
        ],
      ),
    ),
  );

}
