import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/navigation_model.dart';
import '../models/splash_model.dart';
import '../models/version_model.dart';
import '../models/logo_model.dart';

class ApiService {
  static const String baseUrl = 'https://818.56768.xyz/';
  static const Duration timeout = Duration(seconds: 10);

  // 缓存键
  static const String _navigationCacheKey = 'navigation_cache';
  static const String _navigationTimestampKey = 'navigation_timestamp';
  static const String _splashCacheKey = 'splash_cache';
  static const String _splashTimestampKey = 'splash_timestamp';
  static const String _logoCacheKey = 'logo_cache';
  static const String _logoTimestampKey = 'logo_timestamp';

  // 缓存有效期
  static const Duration navigationCacheDuration = Duration(hours: 1);
  static const Duration splashCacheDuration = Duration(hours: 24);
  static const Duration logoCacheDuration = Duration(hours: 24);

  /// 获取导航列表
  static Future<List<NavigationItem>> getNavigations() async {
    try {
      // 先尝试从缓存获取
      final cachedData = await _getCachedNavigations();
      if (cachedData != null) {
        return cachedData;
      }

      // 从服务器获取
      final response = await http
          .get(Uri.parse('$baseUrl/api/navigation'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final navigationResponse = NavigationResponse.fromJson(jsonData);

        // 缓存数据
        await _cacheNavigations(navigationResponse.data);

        return navigationResponse.data;
      } else {
        throw Exception('Failed to load navigations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching navigations: $e');
      // 如果网络请求失败，尝试返回过期的缓存
      final cachedData = await _getCachedNavigations(ignoreExpiry: true);
      return cachedData ?? [];
    }
  }

  /// 获取启动图配置
  static Future<SplashConfig?> getSplashConfig() async {
    try {
      // 先尝试从缓存获取
      final cachedData = await _getCachedSplash();
      if (cachedData != null) {
        return cachedData;
      }

      // 从服务器获取
      final response = await http
          .get(Uri.parse('$baseUrl/api/splash'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final splashResponse = SplashResponse.fromJson(jsonData);

        // 缓存数据
        if (splashResponse.data != null) {
          await _cacheSplash(splashResponse.data!);
        }

        return splashResponse.data;
      } else {
        throw Exception('Failed to load splash: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching splash: $e');
      // 如果网络请求失败，尝试返回过期的缓存
      return await _getCachedSplash(ignoreExpiry: true);
    }
  }

  /// 检查版本更新
  static Future<VersionResponse?> checkVersion(String currentVersion) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/version?currentVersion=$currentVersion'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return VersionResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to check version: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking version: $e');
      return null;
    }
  }

  /// 获取应用 Logo
  static Future<LogoConfig?> getLogo() async {
    try {
      // 先尝试从缓存获取
      final cachedData = await _getCachedLogo();
      if (cachedData != null) {
        return cachedData;
      }

      // 从服务器获取
      final response = await http
          .get(Uri.parse('$baseUrl/api/logo'))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final logoResponse = LogoResponse.fromJson(jsonData);

        // 缓存数据
        if (logoResponse.data != null) {
          await _cacheLogo(logoResponse.data!);
        }

        return logoResponse.data;
      } else {
        throw Exception('Failed to load logo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching logo: $e');
      // 如果网络请求失败，尝试返回过期的缓存
      return await _getCachedLogo(ignoreExpiry: true);
    }
  }

  // ========== 缓存相关方法 ==========

  /// 获取缓存的导航列表
  static Future<List<NavigationItem>?> _getCachedNavigations(
      {bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_navigationCacheKey);
      final timestamp = prefs.getInt(_navigationTimestampKey);

      if (cachedJson == null || timestamp == null) {
        return null;
      }

      // 检查缓存是否过期
      if (!ignoreExpiry) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > navigationCacheDuration) {
          return null;
        }
      }

      final List<dynamic> jsonList = json.decode(cachedJson);
      return jsonList
          .map((item) => NavigationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error reading cached navigations: $e');
      return null;
    }
  }

  /// 缓存导航列表
  static Future<void> _cacheNavigations(List<NavigationItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      await prefs.setString(_navigationCacheKey, json.encode(jsonList));
      await prefs.setInt(
          _navigationTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching navigations: $e');
    }
  }

  /// 获取缓存的启动图配置
  static Future<SplashConfig?> _getCachedSplash(
      {bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_splashCacheKey);
      final timestamp = prefs.getInt(_splashTimestampKey);

      if (cachedJson == null || timestamp == null) {
        return null;
      }

      // 检查缓存是否过期
      if (!ignoreExpiry) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > splashCacheDuration) {
          return null;
        }
      }

      final jsonData = json.decode(cachedJson);
      return SplashConfig.fromJson(jsonData as Map<String, dynamic>);
    } catch (e) {
      print('Error reading cached splash: $e');
      return null;
    }
  }

  /// 缓存启动图配置
  static Future<void> _cacheSplash(SplashConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_splashCacheKey, json.encode(config.toJson()));
      await prefs.setInt(
          _splashTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching splash: $e');
    }
  }

  /// 获取缓存的 Logo 配置
  static Future<LogoConfig?> _getCachedLogo(
      {bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_logoCacheKey);
      final timestamp = prefs.getInt(_logoTimestampKey);

      if (cachedJson == null || timestamp == null) {
        return null;
      }

      // 检查缓存是否过期
      if (!ignoreExpiry) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > logoCacheDuration) {
          return null;
        }
      }

      final jsonData = json.decode(cachedJson);
      return LogoConfig.fromJson(jsonData as Map<String, dynamic>);
    } catch (e) {
      print('Error reading cached logo: $e');
      return null;
    }
  }

  /// 缓存 Logo 配置
  static Future<void> _cacheLogo(LogoConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_logoCacheKey, json.encode(config.toJson()));
      await prefs.setInt(
          _logoTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching logo: $e');
    }
  }

  /// 清除所有缓存
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_navigationCacheKey);
      await prefs.remove(_navigationTimestampKey);
      await prefs.remove(_splashCacheKey);
      await prefs.remove(_splashTimestampKey);
      await prefs.remove(_logoCacheKey);
      await prefs.remove(_logoTimestampKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
