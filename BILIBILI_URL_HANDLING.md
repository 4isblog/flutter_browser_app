# B 站 URL 处理说明

## 问题描述

当访问 B 站视频时，可能会遇到 `net::ERR_UNKNOWN_URL_SCHEME` 错误，显示 "Website not available"。

## 原因分析

B 站有多种 URL 格式：

1. **桌面版 URL**: `https://www.bilibili.com/video/BV1xx411c7mD`
2. **移动版 URL**: `https://m.bilibili.com/video/BV1xx411c7mD`
3. **App Scheme**: `bilibili://video/11589113610628?page=0&...`

当你点击某些链接或扫描二维码时，可能会得到 `bilibili://` 开头的 URL。这是 B 站 App 的专用 scheme，浏览器无法直接打开。

## 解决方案

### 1. 自动转换 bilibili:// URL

浏览器现在会自动将 `bilibili://` 转换为 `https://m.bilibili.com/`：

```
bilibili://video/11589113610628
↓ 自动转换为
https://m.bilibili.com/video/11589113610628
```

### 2. 阻止错误页面显示

对于无法识别的 URL scheme，浏览器会：
- 尝试用外部应用打开（如果安装了 B 站 App）
- 如果失败，静默取消导航，不显示错误页

### 3. 推荐的访问方式

**方式一：直接输入 B 站网址**
```
m.bilibili.com
```

**方式二：使用完整的 HTTPS URL**
```
https://m.bilibili.com/video/BV1xx411c7mD
```

**方式三：搜索视频**
在搜索框输入视频标题，通过搜索引擎找到视频

## 视频播放优化

为了确保 B 站视频能正常播放，请确保：

### 1. User-Agent 设置
- 推荐使用 "Chrome 移动端"（默认）
- 路径：设置 → 高级设置 → 用户代理

### 2. 网络连接
- 确保设备能正常访问 B 站
- 某些地区可能需要特殊网络配置

### 3. 视频格式支持
- 浏览器已启用硬件加速
- 支持 H5 视频播放
- 支持 MSE (Media Source Extensions)

## 常见问题

### Q: 为什么有些 B 站视频能播放，有些不能？

A: 可能的原因：
1. 视频需要登录才能观看
2. 视频有地区限制
3. 视频使用了特殊的 DRM 保护
4. 网络连接问题

### Q: 如何在浏览器中登录 B 站？

A: 
1. 访问 `https://m.bilibili.com`
2. 点击右上角的登录按钮
3. 使用手机号或账号密码登录

### Q: 扫描 B 站二维码后无法打开？

A: 
- 二维码可能包含 `bilibili://` scheme
- 浏览器会自动转换为网页版 URL
- 如果仍然无法打开，请手动访问 B 站网站

## 技术细节

### URL Scheme 处理

在 `webview_tab.dart` 的 `shouldOverrideUrlLoading` 中：

```dart
if (url != null &&
    !["http", "https", "file", "chrome", "data", "javascript", "about"]
        .contains(url.scheme)) {
  // 尝试用外部应用打开
  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  } catch (e) {
    // 静默处理错误
  }
  // 取消 WebView 导航，避免显示错误页
  return NavigationActionPolicy.CANCEL;
}
```

### URL 转换

在 `modern_browser.dart` 的 `_handleUrlSubmit` 中：

```dart
// 处理 bilibili:// scheme，转换为 https://
if (url.startsWith('bilibili://')) {
  url = url.replaceFirst('bilibili://', 'https://m.bilibili.com/');
}
```

## 其他视频网站

类似的处理也适用于其他视频网站的自定义 scheme：

- YouTube: `youtube://` → `https://m.youtube.com/`
- 抖音: `snssdk1128://` → `https://www.douyin.com/`
- 快手: `kwai://` → `https://www.kuaishou.com/`

如需支持更多网站，可以在 `_handleUrlSubmit` 中添加相应的转换规则。
