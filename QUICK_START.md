# 快速开始指南

## 📦 第一步：验证 Flutter 环境

打开命令行，在项目目录执行：

```bash
cd C:\Users\ZincG\Desktop\jlu_course_app
flutter doctor
```

确保 Flutter 和 Android 开发环境配置正确。

## 📥 第二步：获取依赖

```bash
flutter pub get
```

## ⚙️ 第三步：配置 API（重要！）

**当前应用已集成吉林大学金智教务系统支持，但需要配置具体接口。**

### 快速配置（二选一）

#### 方案 A: 直接使用模拟数据（快速体验）
无需配置，直接运行应用，点击"暂不登录，使用模拟数据"即可。

#### 方案 B: 配置真实 API（推荐）
1. 查看 [CONFIG_GUIDE.md](CONFIG_GUIDE.md) - 五分钟快速配置指南
2. 或查看 [CRAWLER_USAGE.md](CRAWLER_USAGE.md) - 详细抓包教程
3. 使用 Python 测试脚本验证: `python tools/jlu_api_test.py`

**吉林大学教务系统地址**：https://iedu.jlu.edu.cn/

## 📱 第四步：运行应用

### 使用 Android 模拟器：

1. 在 Android Studio 中启动 AVD（Android Virtual Device）
2. 或者使用命令：`flutter emulators --launch <模拟器名称>`

### 连接真实设备：

1. 在手机上开启开发者选项和 USB 调试
2. 用 USB 连接手机到电脑
3. 执行 `flutter devices` 查看已连接设备

### 运行应用：

```bash
flutter run
```

## 🔐 第五步：登录使用

**首次使用**：
1. 打开应用后进入"设置"页面
2. 点击"未登录"
3. 输入学号和密码登录
4. 也可以点击"暂不登录，使用模拟数据"体验功能

**注意**：如果没有配置真实 API，登录会失败，请使用模拟数据模式。

## 📦 第六步：构建 APK

### 构建 debug 版本（快速测试）：

```bash
flutter build apk --debug
```

### 构建 release 版本（正式发布）：

```bash
flutter build apk --release
```

生成的📖 文档导航

### 核心文档
- [README.md](README.md) - 项目总览和功能介绍
- [CONFIG_GUIDE.md](CONFIG_GUIDE.md) - ⭐ API 配置快速指南（推荐）
- [QUICK_START.md](QUICK_START.md) - 本文档

### API 对接文档
- [JLU_API_GUIDE.md](JLU_API_GUIDE.md) - 金智教务系统 API 详细说明
- [CRAWLER_USAGE.md](CRAWLER_USAGE.md) - 抓包和爬虫使用教程
- [tools/README.md](tools/README.md) - Python 测试工具说明

## 🔧 配置真实 API（重要！）

### 为什么需要配置？

当前应用包含完整的金智教务系统集成代码，但由于不同学校的具体 API 接口可能略有差异，需要手动配置：

### 快速开始（推荐流程）

1. **使用 Python 脚本测试**（可选但推荐）
   ```bash
   cd tools
   pip install requests
   # 编辑 jlu_api_test.py 填入学号密码
   python jlu_api_test.py
   ```

2. **浏览器抓包**
   - 访问 https://iedu.jlu.edu.cn/
   - F12 打开开发者工具
   - 登录并进入课程表页面
   - 在 Network 中找到 API 接口
   - 记录 URL 和数据格式

3. **更新代码**
   - 打开 `lib/services/jlu_api_service.dart`
   - 修改 API 路径
   - 调整字段映射

详细步骤请查看：
- **⭐ [CONFIG_GUIDE.md](CONFIG_GUIDE.md)** - 五分钟快速配置（推荐）
- [CRAWLER_USAGE.md](CRAWLER_USAGE.md) - 详细抓包教程
- [JLU_API_GUIDE.md](JLU_API_GUIDE.md) - 完整技术文档
- 无需登录即可体验所有功能
- 显示示例课程和成绩数据
- 适合测试和演示

📍 **真实数据模式**
- 需要配置 API 接口
- 从教务系统实时获取数据
- 支持自动登录和 Cookie 管理

## 第七PK 位于：
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

## 第五步：安装到手机

直接将生成的 APK 文件传输到手机安装，或使用命令：

```bash
flutter install
```

## 配置真实 API（重要！）

当前应用使用模拟数据。要使用真实的吉林大学课程数据：

1. 打开 `lib/services/api_service.dart`
2. 找到 `TODO` 注释
3. 替换 `baseUrl` 为真实的 API 地址
4. 实现 `getCourses()` 和 `getGrades()` 方法

示例代码在 `README.md` 中有详细说明。

## 常用 Flutter 命令

- `flutter clean` - 清理构建缓存
- `flutter pub upgrade` - 升级依赖包
- `flutter analyze` - 分析代码问题
- `flutter test` - 运行测试
- `flutter build appbundle` - 构建 AAB 文件（用于 Google Play）

## 故障排除

### 如果遇到依赖问题：

```bash
flutter clean
flutter pub get
```

### 如果遇到 Gradle 问题：

```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

### 如果通知功能不工作：

确保在手机系统设置中授予应用通知权限。

## 开发建议

1. 使用 VS Code 或 Android Studio 进行开发
2. 安装 Flutter 和 Dart 插件
3. 启用 Hot Reload（保存文件即可热重载）
4. 使用 `flutter pub outdated` 检查过时的依赖

祝开发顺利！🎉
