# 🤖 JLU课程表 Android Studio 调试指南

## 🚀 快速开始 (3种方法)

### 方法1: 一键启动 (推荐)
```bash
# 双击运行本地Flutter版本
debug_android_local.bat
```

### 方法2: 交互式启动
```powershell
# PowerShell中运行
.\debug_android_studio.ps1
```

### 方法3: 手动命令
```bash
# 使用本地Flutter工具链
flutter\bin\flutter.bat run
```

## 📱 Android Studio AVD 预备工作

### 1. 启动Android Studio
- 打开Android Studio
- 菜单: Tools → AVD Manager
- 启动一个Android虚拟设备 (API 21+推荐)

### 2. 验证AVD连接
```bash
flutter\bin\flutter.bat devices
flutter\bin\flutter.bat emulators
```

## 🧪 间周解析功能验证

### 验证脚本
```powershell
# 运行完整验证
.\verify_interval_weeks.ps1
```

### 手动验证步骤
1. **启动应用**: 使用上述任一方法
2. **导入课表**: 点击"导入课表"按钮
3. **登录系统**: 选择普通登录或VPN登录
4. **观察日志**: 在控制台查找解析输出

### 预期日志输出
```
I/flutter: [周次解析] 检测到间周上课: 1 - 15 周( 单 )
I/flutter: [课程 0] 周次解析成功: 8 个周次: [1,3,5,7,9,11,13,15]
I/flutter: [周次解析] 检测到多段周次: 2 段
I/flutter: [周次解析] 处理范围: 1 - 4 周
I/flutter: [周次解析] 处理范围: 6 - 13 周
```

## 🔧 调试工具

### 热重载命令
- `r` - 热重载 (保持状态)
- `R` - 热重启 (重置状态)
- `q` - 退出调试
- `h` - 帮助信息

### 日志查看
```bash
# 实时日志 (新终端窗口)
flutter\bin\flutter.bat logs

# 过滤间周解析日志
flutter\bin\flutter.bat logs | findstr "周次解析"
```

## 🎯 支持的课程格式

| 格式 | 示例 | 解析结果 | 状态 |
|------|------|----------|------|
| 连续周次 | "2-10周" | [2,3,4,5,6,7,8,9,10] | ✅ |
| 单周间周 | "1-15周(单周)" | [1,3,5,7,9,11,13,15] | ✅ |
| 双周间周 | "2-16周(双周)" | [2,4,6,8,10,12,14,16] | ✅ |
| 多段周次 | "1-4周,6-13周" | [1,2,3,4,6,7,8,9,10,11,12,13] | ✅ |
| 单周 | "5周" | [5] | ✅ |

## ❗ 常见问题

### 1. 模拟器无法连接
- 确保Android Studio AVD已启动
- 检查模拟器是否完全启动 (显示桌面)
- 重启adb: `adb kill-server && adb start-server`

### 2. 网络请求失败
- 确保模拟器可以访问外网
- 检查代理设置
- 在模拟器浏览器中手动访问 i.jlu.edu.cn 测试

### 3. WebView显示异常
- 确保模拟器API级别 ≥ 21
- 检查网络安全配置
- 清除应用数据重试

### 4. Flutter工具链问题
- 确保使用项目本地的Flutter: `flutter\bin\flutter.bat`
- 运行: `flutter\bin\flutter.bat doctor`
- 清理依赖: `flutter\bin\flutter.bat clean && flutter\bin\flutter.bat pub get`

## 📊 性能优化

### Android模拟器设置
- **RAM**: 2GB+ 推荐
- **存储**: 4GB+ 可用空间
- **处理器**: 启用硬件加速
- **GPU**: Hardware - GLES 2.0

### Flutter优化
```bash
# Release模式运行 (性能更好)
flutter\bin\flutter.bat run --release

# 启用Impeller渲染引擎 (Flutter 3.10+)
flutter\bin\flutter.bat run --enable-impeller
```

---

💡 **提示**: 首次运行需要下载Gradle依赖，请耐心等待约5-10分钟