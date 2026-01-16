import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/locale_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/models/window_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations_delegate.dart';

import 'browser.dart';
import 'modern_browser.dart';
import 'pages/splash_screen.dart';
import 'utils/version_checker.dart';

// ignore: non_constant_identifier_names
late final String WEB_ARCHIVE_DIR;
// ignore: non_constant_identifier_names
late final double TAB_VIEWER_BOTTOM_OFFSET_1;
// ignore: non_constant_identifier_names
late final double TAB_VIEWER_BOTTOM_OFFSET_2;
// ignore: non_constant_identifier_names
late final double TAB_VIEWER_BOTTOM_OFFSET_3;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_OFFSET_1 = 0.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_OFFSET_2 = 10.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_OFFSET_3 = 20.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_SCALE_TOP_OFFSET = 250.0;
// ignore: constant_identifier_names
const double TAB_VIEWER_TOP_SCALE_BOTTOM_OFFSET = 230.0;

WebViewEnvironment? webViewEnvironment;
Database? db;

int windowId = 0;
String? windowModelId;

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Util.isDesktop()) {
    windowId = args.isNotEmpty ? int.tryParse(args[0]) ?? 0 : 0;
    windowModelId = args.length > 1 ? args[1] : null;
    try {
      await WindowManagerPlus.ensureInitialized(windowId);
    } catch (e) {
      // Ignore error on unsupported platforms
      if (kDebugMode) {
        print('WindowManagerPlus initialization failed: $e');
      }
    }
  }

  final appDocumentsDir = await getApplicationDocumentsDirectory();

  if (Util.isDesktop()) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  db = await databaseFactory.openDatabase(
      p.join(appDocumentsDir.path, "databases", "myDb.db"),
      options: OpenDatabaseOptions(
          version: 1,
          singleInstance: false,
          onCreate: (Database db, int version) async {
            await db.execute(
                'CREATE TABLE browser (id INTEGER PRIMARY KEY, json TEXT)');
            await db.execute(
                'CREATE TABLE windows (id TEXT PRIMARY KEY, json TEXT)');
          }));

  if (Util.isDesktop()) {
    WindowOptions windowOptions = WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle:
          Util.isWindows() ? TitleBarStyle.normal : TitleBarStyle.hidden,
      minimumSize: const Size(1280, 720),
      size: const Size(1280, 720),
    );
    WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      if (!Util.isWindows()) {
        await WindowManagerPlus.current.setAsFrameless();
        await WindowManagerPlus.current.setHasShadow(true);
      }
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  WEB_ARCHIVE_DIR = (await getApplicationSupportDirectory()).path;

  TAB_VIEWER_BOTTOM_OFFSET_1 = 150.0;
  TAB_VIEWER_BOTTOM_OFFSET_2 = 160.0;
  TAB_VIEWER_BOTTOM_OFFSET_3 = 170.0;

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    assert(availableVersion != null,
        'Failed to find an installed WebView2 Runtime or non-stable Microsoft Edge installation.');

    webViewEnvironment = await WebViewEnvironment.create(
        settings:
            WebViewEnvironmentSettings(userDataFolder: 'flutter_browser_app'));
  }

  if (Util.isMobile()) {
    await FlutterDownloader.initialize(debug: kDebugMode);
  }

  if (Util.isMobile()) {
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LocaleModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => BrowserModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => WebViewModel(),
        ),
        ChangeNotifierProxyProvider<WebViewModel, WindowModel>(
          update: (context, webViewModel, windowModel) {
            if (windowModel != null) {
              windowModel.setCurrentWebViewModel(webViewModel);
              return windowModel;
            }
            return WindowModel(id: null)
              ..setCurrentWebViewModel(webViewModel);
          },
          create: (BuildContext context) =>
              WindowModel(id: null),
        ),
      ],
      child: const FlutterBrowserApp(),
    ),
  );
}

class FlutterBrowserApp extends StatefulWidget {
  const FlutterBrowserApp({super.key});

  @override
  State<FlutterBrowserApp> createState() => _FlutterBrowserAppState();
}

class _FlutterBrowserAppState extends State<FlutterBrowserApp>
    with WindowListener {

  // https://github.com/pichillilorenzo/window_manager_plus/issues/5
  late final AppLifecycleListener? _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    if (Util.isDesktop()) {
      WindowManagerPlus.current.addListener(this);
    }

    // https://github.com/pichillilorenzo/window_manager_plus/issues/5
    if (Util.isDesktop() && WindowManagerPlus.current.id > 0 && Platform.isMacOS) {
      _appLifecycleListener = AppLifecycleListener(
        onStateChange: _handleStateChange,
      );
    }
  }

  void _handleStateChange(AppLifecycleState state) {
    // https://github.com/pichillilorenzo/window_manager_plus/issues/5
    if (Util.isDesktop() && WindowManagerPlus.current.id > 0 && Platform.isMacOS && state == AppLifecycleState.hidden) {
      SchedulerBinding.instance.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive);
    }
  }

  @override
  void dispose() {
    if (Util.isDesktop()) {
      WindowManagerPlus.current.removeListener(this);
    }
    _appLifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleModel>(
      builder: (context, localeModel, child) {
        final materialApp = MaterialApp(
          title: 'Flutter Browser',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: ThemeMode.system,
          locale: localeModel.locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('zh', ''),
          ],
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(), // 启动图页面
            '/': (context) => const ModernBrowser(), // 使用新的现代化浏览器
            '/old': (context) => const Browser(), // 保留旧版本以便对比
          },
        );

        return Util.isMobile()
            ? materialApp
            : ContextMenuOverlay(
                child: materialApp,
              );
      },
    );
  }

  @override
  void onWindowFocus([int? windowId]) {
    setState(() {});
    if (Util.isDesktop() && !Util.isWindows()) {
      WindowManagerPlus.current.setMovable(false);
    }
  }

  @override
  void onWindowBlur([int? windowId]) {
    if (Util.isDesktop() && !Util.isWindows()) {
      WindowManagerPlus.current.setMovable(true);
    }
  }
}
