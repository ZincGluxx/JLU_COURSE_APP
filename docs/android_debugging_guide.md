# Android虚拟机调试设置指南

## 🔧 环境准备

### 1. Flutter环境检查
```bash
# 检查Flutter是否安装
flutter --version

# 检查Flutter环境
flutter doctor

# 检查Android相关环境
flutter doctor --android-licenses
```

### 2. Android Studio和SDK设置
```bash
# 确保已安装Android Studio
# 在Android Studio中：
# - Tools > AVD Manager 创建虚拟设备
# - SDK Manager 确保已安装所需SDK版本

# 检查可用的Android设备
flutter devices

# 列出所有Android模拟器
flutter emulators
```

## 🚀 启动Android虚拟机调试

### 方法一：使用Flutter命令行

**Step 1: 启动Android模拟器**
```bash
# 查看可用模拟器列表
flutter emulators

# 启动指定模拟器（替换为你的模拟器ID）
flutter emulators --launch Pixel_3a_API_30_x86

# 或者使用Android Studio AVD Manager启动
```

**Step 2: 运行Flutter应用**
```bash
cd c:\Users\ZincG\Desktop\code\jlu_course_app

# 运行到Android设备（调试模式）
flutter run

# 或指定设备运行
flutter run -d emulator-5554

# 发布模式运行（性能更好）
flutter run --release
```

### 方法二：使用VS Code

1. **打开项目**: 在VS Code中打开项目文件夹
2. **启动模拟器**: Ctrl+Shift+P → "Flutter: Launch Emulator"
3. **运行应用**: F5 或 Ctrl+Shift+P → "Flutter: Run Flutter in Debug Mode"

## 🔍 调试间周解析功能

### 在Android中测试课表导入

1. **启动应用**后点击"导入课表"
2. **选择登录方式**：
   - 普通登录：i.jlu.edu.cn
   - VPN登录：vpn.jlu.edu.cn

3. **调试输出查看**：
   ```bash
   # 在另一个终端查看实时日志
   flutter logs

   # 过滤特定标签
   flutter logs | grep "周次解析"
   ```

### 预期调试输出
应该在日志中看到类似输出：
```
I/flutter(12345): [周次解析] 检测到间周上课: 1 - 15 周( 单 )
I/flutter(12345): [课程 0 测试课程] 周次解析成功: 8 个周次: [1,3,5,7,9,11,13,15]
I/flutter(12345): [周次解析] 检测到多段周次: 2 段
I/flutter(12345): [周次解析] 处理范围: 1 - 4 周
I/flutter(12345): [周次解析] 处理范围: 6 - 13 周
```

## 📱 Android特定配置

### 网络权限（已配置）
确保 `android/app/src/main/AndroidManifest.xml` 包含：
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### WebView配置
在 `android/app/src/main/AndroidManifest.xml` 的 `<application>` 标签中：
```xml
<application
    android:usesCleartextTraffic="true">
```

## 🛠️ 常见问题解决

### 1. 模拟器无法启动
```bash
# 检查HAXM是否安装（Intel处理器）
# 或检查Hyper-V是否启用（AMD处理器）

# 重启adb服务
adb kill-server
adb start-server
```

### 2. 应用无法连接网络
```bash
# 确保模拟器有网络连接
adb shell ping google.com

# 检查代理设置
# 在模拟器设置中配置网络代理（如需要）
```

### 3. WebView无法加载页面
- 确保模拟器API级别 ≥ 21
- 在模拟器中手动访问 i.jlu.edu.cn 测试网络
- 检查防火墙和代理设置

### 4. 性能问题
```bash
# 使用硬件加速
flutter run --enable-software-rendering=false

# 或者使用release模式
flutter run --release
```

## 📋 测试清单

### 基础功能测试
- [ ] 应用正常启动
- [ ] 界面正确显示
- [ ] 课表导入按钮可点击

### 网络功能测试
- [ ] WebView可以打开
- [ ] 可以访问吉大教务系统
- [ ] VPN登录功能正常

### 间周解析测试
- [ ] 连续周次正确解析："2-10周"
- [ ] 单周间周正确解析："1-15周(单周)"
- [ ] 双周间周正确解析："2-16周(双周)"
- [ ] 多段周次正确解析："1-4周,6-13周"
- [ ] 解析结果正确显示在课表中

## 🎯 性能优化建议

### Android模拟器设置
- **RAM**: 分配至少2GB内存
- **存储空间**: 至少4GB可用空间
- **图形**: 启用硬件加速
- **CPU核心数**: 设置为宿主机核心数的一半

### Flutter应用优化
```bash
# 构建优化版本用于性能测试
flutter build apk --release

# 安装到设备
flutter install
```

## 📞 调试技巧

### 热重载使用
```bash
# 在应用运行时按键盘快捷键：
# 'r' - 热重载
# 'R' - 热重启
# 'q' - 退出调试
```

### 断点调试
1. 在VS Code中设置断点
2. F5启动调试模式
3. 在断点处检查变量值

### 日志输出
```dart
// 在代码中添加调试日志
print('调试信息: $variableName');
debugPrint('详细调试: $details');
```

现在您可以按照这个指南在Android虚拟机中调试运行应用了！