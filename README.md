# 📚 吉林大学课程表 App (JLU Course App)

<div align="center">
  <p><strong>专为吉林大学学生打造的轻量级本地化课程表应用</strong></p>
  <p>
    <img alt="Version" src="https://img.shields.io/badge/version-1.2.0-blue.svg" />
    <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.0+-brightgreen.svg" />
    <img alt="Dart" src="https://img.shields.io/badge/Dart-3.0+-blue.svg" />
    <img alt="License" src="https://img.shields.io/badge/license-GPL%20v3-green.svg" />
  </p>
</div>

基于 Flutter 开发的**免服务器**教务辅助应用。核心特性为**纯本地解析**：直接通过内置浏览器 (WebView) 登录吉林大学教务系统并拉取数据，数据直接存储在本地，不经过任何第三方服务器，**最大化保障您的账号安全和隐私**。

---

## 🌟 核心特性

### 🔒 安全保障
- **纯本地无后端验证**：彻底基于内置 WebView + 注入 JS 脚本爬取数据，无第三方服务器中转
- **隐私优先**：所有数据直接存储在本地，告别密码泄露担忧
- **官方系统对接**：已完美适配吉林大学金智教务系统

### 📅 功能特色
- **智能周视图展示**：精简清晰的课程表网格界面，支持周次切换
- **倒计时提醒**：支持课前智能提醒通知，可自定义提前时间
- **桌面小组件**：直接在桌面查看今日课程安排
- **暗黑模式**：自动跟随系统主题，护眼更舒适

### ⚡ 体验优化
- **导入后热重载刷新**：更新课表后自动清理缓存并无缝刷新界面
- **高精度课程解析**：深度优化的地点解析逻辑，精准显示教室位置
- **清爽 UI 设计**：移除冗余功能，专注实用的周视图展示
- **离线查看**：支持离线查看已缓存的课程表数据

---

## 🛠️ 技术架构

### 核心技术栈
- **框架**: Flutter 3.0+ (Dart 3.0+)
- **状态管理**: Provider
- **UI设计**: Material Design 3

### 主要依赖
| 依赖包 | 版本 | 功能描述 |
|--------|------|----------|
| `webview_flutter` | ^4.7.0 | 内置安全浏览器环境 |
| `shared_preferences` | ^2.2.2 | 轻量级本地数据持久化 |
| `provider` | ^6.1.1 | 状态管理解决方案 |
| `home_widget` | ^0.6.0 | 桌面小组件支持 |

---

## 📦 安装与下载

### 💾 下载应用
前往 [Releases](https://github.com/ZincGluxx/JLU_COURSE_APP/releases) 页面下载最新版本：
- 📱 **Android APK**: 提供 `arm64-v8a` 和 `armeabi-v7a` 双架构版本
- 🔄 **自动更新**: 应用内支持检查更新提醒

### 🚀 快速开始
1. 下载并安装 APK 文件
2. 首次打开应用，点击"登录"
3. 在内置浏览器中输入学号密码
4. 登录成功后自动同步课程数据
5. 享受便捷的课程管理体验

### 🔧 从源码编译

#### 环境要求
- Flutter 3.0+
- Android SDK (API 21+)
- Dart 3.0+

#### Windows 编译 (推荐镜像加速)
```powershell
# 配置国内镜像
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

# 获取依赖并构建
flutter pub get
flutter build apk --split-per-abi --release
```

#### Linux/macOS 编译
```bash
# 获取依赖
flutter pub get

# 构建多架构 APK
flutter build apk --split-per-abi --release
```

**构建产物位置**: `build/app/outputs/flutter-apk/`

---

## 🚀 核心工作原理

### 🤔 如何实现免服务器获取教务数据？

我们采用了创新的**本地化数据获取方案**，完全绕过传统的服务器中转模式：

```mermaid
graph LR
    A[用户登录] --> B[WebView打开教务系统]
    B --> C[自动注入JS脚本]
    C --> D[DOM解析课表数据]
    D --> E[JSON数据回传Flutter]
    E --> F[本地存储+UI刷新]
```

### 📋 详细实现步骤

1. **🌐 WebView 登录代理**
   - 利用 `webview_flutter` 插件打开吉大统一身份认证
   - 访问教务系统 (`https://iedu.jlu.edu.cn/`)

2. **💉 JavaScript 智能注入**
   - 用户登录成功后，自动执行预编写的 JS 脚本
   - 无需用户手动操作，全程后台自动化

3. **🔍 DOM 解析与数据提取**
   - JS 脚本智能抓取课表 HTML 元素
   - 高精度正则分析，还原结构化数据
   - 自动过滤干扰文本和冗余信息

4. **📱 数据回传与持久化**
   - 通过 `JavascriptChannel` 与 Flutter 通信
   - JSON 数据传回 Flutter 引擎
   - SharedPreferences 本地缓存
   - 自动触发 UI 热重载刷新

### 🛡️ 安全保障
- ✅ 数据不经过任何第三方服务器
- ✅ 登录凭据仅在本地 WebView 中存储
- ✅ 支持撤销登录状态和清除本地数据
- ✅ 开源透明，代码可审计

---

## 📖 开发者文档与脚本工具

如果您想要进一步了解接口或贡献代码，项目内附带了完善的 API 研究文档和辅助 Python 脚本：

- **抓包与脚本使用教程**: [CRAWLER_USAGE.md](CRAWLER_USAGE.md)、[tools/README.md](tools/README.md)
- **教务 API 对接详细文档**: [JLU_API_GUIDE.md](JLU_API_GUIDE.md)、[WEBVIEW_LOGIN_GUIDE.md](WEBVIEW_LOGIN_GUIDE.md)
- Python 抓包分析脚本统一存放在 `tools/` 根目录下，用于帮助开发者在 PC 端调试和拆解教务处返回的最新结构。

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交您的修改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

---

## 📄 License
该项目基于 **GPL V3**开源。
