# 吉林大学课程表 App (JLU Course App)

这是一个专为吉林大学学生打造的轻量级、免服务器、基于 Flutter 开发的本地化课程表与教务辅助应用。
核心特性为**纯本地解析**：直接通过内置浏览器 (WebView) 登录吉林大学教务系统并拉取数据，数据直接存储在本地，不经过任何第三方服务器，最大化保障您的账号安全和隐私。

---

## 🌟 核心特性

- 🔒 **纯本地无后端验证**：彻底基于内置 WebView + 注入 JS 脚本爬取数据，告别第三方服务泄露密码的担忧。（已适配金智教务系统）
- 📅 **智能周视图展示**：精简清晰的课程表网格界面，支持周次切换，按周次和星期直观显示课程。
- ⚡ **导入后热重载刷新**：导入或者更新课表成功后，系统会自动清理底层缓存并直接无缝刷新主课表界面，无需再手动刷新。
- 📍 **高精度课程解析**：深度优化的地点解析正则逻辑，精准剥离“周”、“星期”、“节”等干扰文本，保障教室位置等信息显示准确。
- 🗑️ **清爽 UI 体验**：移除冗余的日视图，完全聚焦于实用的周排版。

---

## 🛠️ 技术栈

- **框架**: Flutter 3.0+ (Dart 3.0+)
- **状态管理**: Provider
- **核心依赖**:
  - `webview_flutter`: 提供安全的内置浏览器运行环境。
  - `shared_preferences`: 进行轻量级本地数据持久化持久化存储。

---

## 📦 安装与下载

前往 [Releases](https://github.com/ZincGluxx/JLU_COURSE_APP/releases) 页面下载最新版本的 Android APK 安装包（提供 `arm64-v8a` 和 `armeabi-v7a` 双架构版本）。

### 编译源码提示

> 如果你需要自己编译源码，由于国内网络环境，可能需要配置相关镜像。

```powershell
# Windows PowerShell 环境下的镜像配置与打包命令
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
.\flutter\bin\flutter.bat build apk --split-per-abi --release
```

打包生成的产物路径位于：`build/app/outputs/flutter-apk/`

---

## 🚀 核心工作原理设计

如何实现不需要后端服务器获取吉林大学教务系统数据的？

1. **WebView 登录代理**：利用 `webview_flutter` 插件打开吉林的统一身份认证 / 教务系统页面（如 `https://iedu.jlu.edu.cn/`）。
2. **Javascript 注入**：用户在 WebView 登录成功后，App 会在后台自动执行预先写好的 JavaScript 脚本。
3. **DOM 解析与提取**：注入的 JS 脚本自动抓取页面 DOM 中的课表 HTML 元素进行正则分析还原。
4. **回传与持久化**：JS 脚本通过 `JavascriptChannel` 与 Flutter 宿主通信，将提取清洗后的 JSON 数据传回 Flutter 引擎，利用 SharedPreferences 写入本地缓存并立即热重载刷新 UI。

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
该项目基于 **MIT License** 开源。
