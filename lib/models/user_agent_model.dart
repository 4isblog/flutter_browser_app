class UserAgentModel {
  final String name;
  final String value;
  final String description;

  const UserAgentModel({
    required this.name,
    required this.value,
    required this.description,
  });
}

// 预设的 User-Agent 列表
const List<UserAgentModel> PresetUserAgents = [
  UserAgentModel(
    name: '默认（移动端）',
    value: '',
    description: '使用系统默认 User-Agent',
  ),
  UserAgentModel(
    name: 'Chrome 移动端',
    value: 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    description: 'Android Chrome 浏览器',
  ),
  UserAgentModel(
    name: 'Chrome 桌面端',
    value: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    description: 'Windows 桌面版 Chrome',
  ),
  UserAgentModel(
    name: 'Safari iPad',
    value: 'Mozilla/5.0 (iPad; CPU OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
    description: 'iPad Safari 浏览器',
  ),
  UserAgentModel(
    name: '自定义',
    value: 'custom',
    description: '输入自定义 User-Agent',
  ),
];
