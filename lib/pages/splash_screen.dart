import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/splash_model.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  Future<void> _initSplash() async {
    try {
      // 获取启动图配置
      final splashConfig = await ApiService.getSplashConfig();

      if (splashConfig != null && mounted) {
        // 显示启动图指定的时长
        await Future.delayed(Duration(milliseconds: splashConfig.duration));
      } else {
        // 如果没有启动图配置，显示默认时长（2秒）
        await Future.delayed(const Duration(seconds: 2));
      }

      // 跳转到主页
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      print('Error in splash screen: $e');
      // 出错时也要跳转到主页
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pushReplacementNamed('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SplashConfig?>(
      future: ApiService.getSplashConfig(),
      builder: (context, snapshot) {
        // 默认背景色
        Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
        Widget? splashImage;

        if (snapshot.hasData && snapshot.data != null) {
          final config = snapshot.data!;

          // 解析背景色
          try {
            final colorString = config.backgroundColor.replaceAll('#', '');
            backgroundColor = Color(int.parse('FF$colorString', radix: 16));
          } catch (e) {
            print('Error parsing background color: $e');
          }

          // 加载网络图片
          splashImage = CachedNetworkImage(
            imageUrl: config.imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => _buildDefaultSplash(),
          );
        } else {
          // 使用默认启动图
          splashImage = _buildDefaultSplash();
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: splashImage,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultSplash() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/icon.png',
          width: 120,
          height: 120,
        ),
        const SizedBox(height: 24),
        Text(
          'Flutter Browser',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
