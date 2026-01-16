import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // 通用
  String get appName;
  String get ok;
  String get cancel;
  String get delete;
  String get save;
  String get settings;
  String get enabled;
  String get disabled;
  
  // 浏览器相关
  String get searchOrTypeUrl;
  String get newTab;
  String get closeTab;
  String get closeTabs;
  String get refresh;
  String get forward;
  String get back;
  String get share;
  String get copyLink;
  String get openInNewTab;
  String get addToFavorites;
  String get removeFromFavorites;
  String get favorites;
  String get history;
  String get downloads;
  String get clearHistory;
  String get clearCache;
  String get desktopMode;
  String get incognitoMode;
  String get findOnPage;
  String get webArchives;
  String get openNewWindow;
  String get saveWindow;
  String get savedWindows;
  
  // 设置页面
  String get generalSettings;
  String get privacySettings;
  String get searchEngine;
  String get homepage;
  String get language;
  String get clearBrowsingData;
  String get about;
  String get crossPlatform;
  String get android;
  String get ios;
  String get defaultUserAgent;
  String get debuggingEnabled;
  String get debuggingDescription;
  String get flutterBrowserPackageInfo;
  String get packageName;
  String get version;
  String get buildNumber;
  String get flutterInAppWebViewProject;
  String get webViewPackageInfo;
  String get off;
  String get on;
  
  // 开发者工具
  String get developerTools;
  String get console;
  String get networkInfo;
  String get storageManager;
  
  // 语言选项
  String get chinese;
  String get english;
  String get systemDefault;
}
