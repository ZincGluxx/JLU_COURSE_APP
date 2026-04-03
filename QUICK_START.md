# 快速开始指南

## 📱 用户使用指南

### 第一步：安装应用

前往 [Releases](https://github.com/ZincGluxx/JLU_COURSE_APP/releases) 下载最新 APK 并安装到 Android 设备。

### 第二步：导入课表

1. 打开应用，进入底部导航栏的**设置**页面
2. 点击**导入课表**，选择登录方式：
   - **普通登录**：校内网络，访问 `i.jlu.edu.cn`
   - **VPN 登录**：校外网络，访问 `vpn.jlu.edu.cn`
3. 在内置浏览器中完成学号密码登录
4. 登录后手动导航至"**我的课表**"页面，等待加载完成
5. 点击右上角**下载按钮（⬇️）**提取课程数据
6. 在弹出的对话框中输入学期标识（格式：`YYYY-YYYY-N`，例如 `2025-2026-2`）并保存

### 第三步：设置开学日期

1. 在**设置**页面点击**开学日期**
2. 选择本学期第一周的周一日期
3. 应用将自动计算当前所在周次

### 第四步：查看课表

- **周视图**：在主页可看到整周课表网格
- **日视图**：左右滑动切换查看每天的课程
- **课程详情**：点击任意课程格子查看详细信息
- **切换周次**：点击顶部周次选择器切换查看其他周

---

## 🔧 开发者指南

### 环境准备

```bash
# 验证 Flutter 环境
flutter doctor
```

确保 Flutter 和 Android 开发环境配置正确后继续。

### 获取依赖

```bash
flutter pub get
```

### 运行应用

**连接真实设备（推荐）：**
1. 手机开启开发者选项和 USB 调试
2. USB 连接手机，执行 `flutter devices` 确认识别
3. 运行 `flutter run`

**使用 Android 模拟器：**
1. 在 Android Studio 中启动 AVD
2. 运行 `flutter run`

### 构建 APK

```bash
# 调试版本
flutter build apk --debug

# 发布版本（推荐，体积更小）
flutter build apk --split-per-abi --release
```

**构建产物位置**：
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`（等）

**安装到手机：**
```bash
flutter install
```

### Windows 编译（推荐配置国内镜像）

```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
flutter build apk --split-per-abi --release
```

---

## 📖 文档导航

| 文档 | 说明 |
|------|------|
| [README.md](README.md) | 项目总览和功能介绍 |
| [WEBVIEW_LOGIN_GUIDE.md](WEBVIEW_LOGIN_GUIDE.md) | WebView 登录详细说明 |
| [JLU_API_GUIDE.md](JLU_API_GUIDE.md) | 教务系统 API 研究文档 |
| [CRAWLER_USAGE.md](CRAWLER_USAGE.md) | 抓包与爬虫使用教程 |
| [tools/README.md](tools/README.md) | Python 辅助脚本说明 |

---

## 🔨 常用 Flutter 命令

```bash
flutter clean            # 清理构建缓存
flutter pub get          # 获取依赖
flutter pub upgrade      # 升级依赖包
flutter analyze          # 静态分析代码
flutter test             # 运行测试
flutter build appbundle  # 构建 AAB（用于 Google Play）
```

---

## ❓ 故障排除

### 依赖或构建问题

```bash
flutter clean
flutter pub get
flutter build apk
```

### Gradle 构建失败

```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

### 课表提取失败

- 确认已完成登录且处于"我的课表"页面
- 等待页面**完全加载**后再点击下载按钮
- 如自动提取失败，可手动点击右上角下载按钮

---

祝开发顺利！🎉
