# 虚拟机调试指南

## 1. Flutter环境设置

### 安装Flutter（如果未安装）
```bash
# 下载Flutter SDK
# 访问 https://flutter.dev/docs/get-started/install/windows
# 或使用Git克隆
git clone https://github.com/flutter/flutter.git -b stable

# 添加Flutter到PATH环境变量
# 将Flutter的bin目录添加到系统PATH中
```

### 验证Flutter环境
```bash
flutter doctor
flutter devices
```

## 2. 项目调试运行

### Web端调试（推荐用于测试间周解析）
```bash
# 启动Web应用（使用预设端口7357）
flutter run -d edge --web-port 7357

# 或使用Chrome
flutter run -d chrome --web-port 7357

# 使用VSCode任务
# Ctrl+Shift+P -> Tasks: Run Task -> run-web-edge
```

### Android模拟器调试
```bash
# 启动Android模拟器
flutter emulators --launch <emulator_id>

# 运行应用到模拟器
flutter run -d <device_id>

# 热重载调试
# 按 'r' 键进行热重载
# 按 'R' 键进行热重启
```

## 3. 间周解析功能测试

### 测试流程
1. **启动应用**：使用上述命令启动调试版本
2. **打开课表导入**：点击"导入课表"按钮
3. **选择登录方式**：
   - 普通登录：`i.jlu.edu.cn`
   - VPN登录：`vpn.jlu.edu.cn`

### 测试用例验证
创建测试HTML页面来模拟间周课程：

```html
<!-- 将此内容保存为test_interval.html并在浏览器中打开 -->
<div class="mtt_arrange_item">
  <div class="mtt_item_kcmc">测试间周课程[01]</div>
  <div class="mtt_item_jxbmc">测试教师</div>
  <div class="mtt_item_room">1-15周(单周),星期1,第5节-第6节,测试教室</div>
</div>
```

### 调试输出检查
在Chrome DevTools控制台中查看输出：
- `[周次解析] 检测到间周上课: 1 - 15 周( 单 )`
- `[课程 0 测试间周课程[01]] 周次解析成功: 8 个周次: [1,3,5,7,9,11,13,15]`

## 4. 调试工具和技巧

### Flutter Inspector
- 在Chrome DevTools中启用Flutter Inspector
- 查看Widget树和渲染性能

### 日志调试
```bash
# 查看详细日志
flutter logs

# 过滤特定标签
flutter logs | grep "周次解析"
```

### 断点调试
1. 在VS Code中设置断点
2. 使用F5启动调试模式
3. 在`_parseCourses`方法中添加断点验证数据

## 5. 虚拟机特殊配置

### 网络配置
- 确保虚拟机可以访问`jlu.edu.cn`域名
- 配置代理（如需要）

### 性能优化
```bash
# 禁用不必要的检查以提高性能
flutter run --release    # 发布模式
flutter run --profile     # 性能分析模式
```

### 热重载问题解决
如果热重载不工作：
```bash
flutter clean
flutter pub get
flutter run
```

## 6. 测试间周解析的具体步骤

### Step 1: 启动调试
```bash
cd c:\Users\ZincG\Desktop\code\jlu_course_app
flutter run -d chrome --web-port 7357
```

### Step 2: 测试验证
1. 打开应用后进入课表导入页面
2. 在WebView中打开开发者工具（F12）
3. 手动运行测试脚本来验证解析逻辑

### Step 3: 验证输出
在控制台中应该看到类似输出：
```
[提取] 找到 X 个课程元素
[周次解析] 检测到间周上课: 1 - 15 周( 单 )
[课程 0] ✅ 测试课程 周次: 8 星期: 1 节次: 5 - 6
```

## 7. 常见问题解决

### WebView相关问题
- 确保`webview_flutter`插件正确安装
- 检查Web安全策略设置

### 网络访问问题
- 配置虚拟机网络为NAT或桥接模式
- 检查防火墙设置

### 性能问题
- 分配足够的内存给虚拟机
- 启用硬件加速（如可用）

## 8. 自动化测试脚本

运行单元测试：
```bash
node test/week_parsing_test.js
```

这会验证所有间周解析逻辑是否正确工作。