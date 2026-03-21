# 🤖 Android调试快速参考

## 🚀 快速启动
```bash
# 方法1: 使用批处理文件
debug_android.bat

# 方法2: 使用PowerShell脚本
.\debug_android.ps1

# 方法3: 手动命令
flutter run
```

## 📱 常用调试命令
```bash
# 查看设备
flutter devices

# 查看模拟器
flutter emulators

# 启动模拟器
flutter emulators --launch Pixel_3a_API_30_x86

# 查看日志
flutter logs

# 过滤间周解析日志
flutter logs | grep "周次解析"

# 热重载
r

# 热重启
R

# 退出调试
q
```

## 🔍 测试间周功能
1. **启动应用**: 使用上述任一方法
2. **打开课表导入**: 点击"导入课表"按钮
3. **选择登录方式**: VPN或普通登录
4. **检查日志输出**: 应看到周次解析信息

## 📊 预期输出
```
I/flutter: [周次解析] 检测到间周上课: 1 - 15 周( 单 )
I/flutter: [课程 0] 周次解析成功: 8 个周次: [1,3,5,7,9,11,13,15]
```

## 🛠️ 问题排查
- **模拟器无法启动**: 检查HAXM/Hyper-V
- **网络无法连接**: 检查模拟器网络设置
- **WebView白屏**: 确保API级别≥21
- **应用崩溃**: 查看 `flutter logs` 错误信息

## 📁 测试文件
- `test/android_webview_test.html`: WebView解析功能测试
- `docs/android_debugging_guide.md`: 详细调试指南

---
✨ **提示**: 首次运行可能需要下载Gradle依赖，请耐心等待