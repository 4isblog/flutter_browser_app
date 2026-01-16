# 视频播放优化说明

## 已完成的优化

根据专业开发者的建议，我们对 WebView 进行了系统性的视频播放优化，特别针对 B 站等视频网站。

### 1. WebView 核心配置优化 (`lib/webview_tab.dart`)

#### 视频播放关键设置
```dart
mediaPlaybackRequiresUserGesture: false  // 允许自动播放
allowsInlineMediaPlayback: true          // 允许内联播放
allowsPictureInPictureMediaPlayback: true // 支持画中画
```

#### Android 特定优化
```dart
useHybridComposition: true  // Android 视频兼容性关键（解决黑屏问题）
hardwareAcceleration: true  // 硬件加速（提升性能）
```

#### User-Agent 更新
- **旧版**: Chrome/83 (Android 9)
- **新版**: Chrome/120 (Android 10) - 更现代，B 站等网站兼容性更好
- **可配置**: 用户可以在"高级设置"中自定义 User-Agent
  - 如果设置了自定义 UA，将优先使用自定义值
  - 如果未设置，则使用默认的现代 Chrome UA

### 2. Android 配置 (`android/app/src/main/AndroidManifest.xml`)

#### 权限
- ✅ `INTERNET` - 网络访问
- ✅ `WAKE_LOCK` - 防止播放时休眠
- ✅ `CAMERA` / `RECORD_AUDIO` - 支持视频通话
- ✅ `MODIFY_AUDIO_SETTINGS` - 音频控制

#### Application 级别
- ✅ `android:hardwareAccelerated="true"` - 全局硬件加速

### 3. iOS 配置 (`ios/Runner/Info.plist`)

#### 媒体播放设置
```xml
<key>allowsInlineMediaPlayback</key>
<true/>
<key>mediaPlaybackRequiresUserAction</key>
<false/>
<key>webkitAllowsInlineMediaPlayback</key>
<true/>
```

## 支持的视频功能

✅ H5 `<video>` 标签播放
✅ MSE (Media Source Extensions) - B 站等网站使用
✅ 自动播放（无需用户手势）
✅ 内联播放（不全屏）
✅ 画中画模式
✅ 硬件加速解码
✅ 音频控制
✅ 自定义 User-Agent - 用户可在设置中配置

## 如何使用自定义 User-Agent

1. 打开浏览器菜单 → 设置
2. 进入"高级设置"
3. 点击"用户代理"
4. 选择预设的设备类型或自定义

### 预设的 User-Agent 选项

1. **默认（移动端）** - 使用系统默认 User-Agent
2. **Chrome 移动端** - Android Chrome 浏览器（推荐，支持 B 站等视频网站）
3. **Chrome 桌面端** - Windows 桌面版 Chrome（访问桌面版网站）
4. **Safari iPad** - iPad Safari 浏览器（平板体验）
5. **自定义** - 输入任意 User-Agent 字符串

### 常用场景

- **视频播放优化**: 选择"Chrome 移动端"（默认）
- **访问桌面版网站**: 选择"Chrome 桌面端"
- **特殊网站兼容**: 选择"自定义"并输入特定 UA

保存后，所有新标签页和现有标签页都会立即使用新的 User-Agent。

## 测试建议

### 测试网站
1. **B 站**: https://www.bilibili.com
2. **YouTube**: https://m.youtube.com
3. **腾讯视频**: https://v.qq.com
4. **爱奇艺**: https://m.iqiyi.com

### 测试场景
- [ ] 视频能否正常加载
- [ ] 播放器控件是否显示
- [ ] 点击播放是否响应
- [ ] 视频是否黑屏
- [ ] 音频是否正常
- [ ] 全屏功能是否正常
- [ ] 画中画是否可用

## 常见问题排查

### 如果视频仍然无法播放

1. **检查网络连接** - 确保设备能访问视频网站
2. **清除缓存** - 在设置中清除浏览器缓存
3. **检查 DRM** - 某些付费内容需要 DRM 支持（需要额外配置）
4. **查看控制台** - 开启调试模式查看 JavaScript 错误

### 如果需要拦截广告

在 `shouldOverrideUrlLoading` 中添加白名单：
```dart
// 不要拦截视频资源
if (url.contains("bilivideo.com") || 
    url.endsWith(".m4s") || 
    url.endsWith(".m3u8") ||
    url.endsWith(".flv") ||
    url.endsWith(".ts")) {
  return NavigationActionPolicy.ALLOW;
}
```

## 技术原理

### 为什么需要 useHybridComposition?
- Android 的 WebView 有两种渲染模式：Virtual Display 和 Hybrid Composition
- Virtual Display 模式下，视频播放器经常出现黑屏
- Hybrid Composition 直接使用原生视图，视频兼容性更好

### 为什么需要更新 User-Agent?
- B 站等网站会检测 UA，旧版 Chrome 可能被拒绝
- 现代 UA 能获得更好的 HTML5 特性支持
- 某些网站会根据 UA 返回不同的播放器代码

### 为什么需要 mediaPlaybackRequiresUserGesture: false?
- 默认情况下，浏览器要求用户点击才能播放（防止自动播放广告）
- 但这会导致某些网站的播放器初始化失败
- 设置为 false 后，网站可以自动初始化播放器

## 下一步优化（可选）

如果上述优化仍不能满足需求，可以考虑：

1. **集成原生播放器** - 拦截视频 URL，使用原生播放器播放
2. **DRM 支持** - 添加 Widevine 等 DRM 支持
3. **视频下载** - 实现视频嗅探和下载功能
4. **自定义播放器** - 完全自定义的视频播放界面

但在大多数情况下，当前的优化已经足够支持主流视频网站。
