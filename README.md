# 吉林大学课程表 App

这是一个基于 Flutter 开发的吉林大学课程表应用，支持查看课程表、查询成绩和设置课程提醒功能。

## 功能特性

- ✅ **课程表查看**：按周次和星期显示课程安排
- ✅ **成绩查询**：查看所有课程成绩和GPA
- ✅ **课程提醒**：支持课前提醒通知
- ✅ **周次切换**：方便查看不同周次的课程
- ✅ **详细信息**：查看课程的教师、地点、时间等详细信息

## 截图

（待添加应用截图）

## 技术栈

- Flutter 3.0+
- Dart 3.0+
- Provider (状态管理)
- flutter_local_notifications (本地通知)
- http (网络请求)

## 安装和运行

### 前置要求

1. 安装 [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. 安装 Android Studio 或 VS Code
3. 配置 Android 开发环境

### 安装步骤

1. 克隆或下载项目到本地
   ```bash
   cd jlu_course_app
   ```

2. 获取依赖
   ```bash
   flutter pub get
   ```

3. 运行应用（移动端）
   ```bash
   flutter run
   ```

4. 在浏览器测试（Web）
   ```bash
   flutter run -d edge
   ```

5. 构建 APK
   ```bash
   flutter build apk --release
   ```
   生成的 APK 文件位于 `build/app/outputs/flutter-apk/app-release.apk`

## API 配置

### 重要提示

**当前应用已集成吉林大学金智教务系统 API 支持，但需要手动配置具体的接口参数。**

吉林大学使用的是 **金智教务系统**，教务系统地址：
- 主站: https://iedu.jlu.edu.cn/
- 课程表: https://iedu.jlu.edu.cn/jwapp/sys/wdkb/*default/index.do

### 快速配置（三步走）

#### 第一步：使用 Python 脚本测试 API

1. 安装 Python 依赖：
   ```bash
   pip install requests beautifulsoup4
   ```

2. 运行测试脚本：
   ```bash
   cd tools
   python jlu_api_test.py
   ```

3. 根据脚本输出查看实际的 API 响应格式

#### 第二步：抓包获取 API 接口

使用浏览器开发者工具（F12）：
1. 登录教务系统
2. 打开 Network 标签
3. 筛选 XHR 请求
4. 找到课程表和成绩的 API 接口
5. 记录 URL、请求头和参数

详细步骤请查看：[JLU_API_GUIDE.md](JLU_API_GUIDE.md)

#### 第三步：更新代码配置

1. 打开 `lib/services/jlu_api_service.dart`

2. 修改 API 路径（根据抓包结果）：
   ```dart
   static const String loginPath = '/你抓包看到的登录路径';
   static const String coursePath = '/你抓包看到的课程表路径';
   static const String gradePath = '/你抓包看到的成绩路径';
   ```

3. 修改字段映射（根据实际响应数据）：
   ```dart
   Course _parseCourse(Map<String, dynamic> json) {
     return Course(
       id: json['实际的课程ID字段'] ?? '',
       name: json['实际的课程名字段'] ?? '',
       // ... 其他字段
     );
   }
   ```

### 详细文档

- [API 对接完整指南](JLU_API_GUIDE.md) - API 接口详细说明
- [爬虫使用教程](CRAWLER_USAGE.md) - 抓包和配置步骤
- [工具脚本说明](tools/README.md) - Python 测试脚本使用

### API 数据格式

#### 课程表数据格式 (Course)
```json
{
  "id": "1",
  "name": "高等数学",
  "teacher": "张教授",
  "location": "东荣大厦A座201",
  "weekday": 1,
  "startSection": 1,
  "endSection": 2,
  "weeks": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
  "description": "必修课"
}
```

#### 成绩数据格式 (Grade)
```json
{
  "courseId": "1",
  "courseName": "高等数学",
  "credit": "5.0",
  "score": "92",
  "gradePoint": "4.2",
  "semester": "2024-2025学年第一学期",
  "examType": "期末考试"
}
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── course.dart          # 课程模型
│   └── grade.dart           # 成绩模型
├── services/                # 服务层
│   ├── api_service.dart     # API 接口服务
│   ├── course_service.dart  # 课程业务逻辑
│   └── notification_service.dart  # 通知服务
├── screens/                 # 页面
│   ├── home_screen.dart           # 主页
│   ├── course_table_screen.dart   # 课程表页面
│   ├── grades_screen.dart         # 成绩页面
│   └── settings_screen.dart       # 设置页面
└── widgets/                 # 自定义组件
    └── course_card.dart     # 课程卡片组件
```

## 使用说明

### 首次使用

1. **登录教务系统**
   - 打开应用，进入"设置"页面
   - 点击"未登录"
   - 输入学号和密码登录
   - 登录成功后自动获取课程表和成绩

2. **不登录使用（体验模式）**
   - 点击"暂不登录，使用模拟数据"
   - 可以体验应用的所有功能
   - 显示的是模拟数据

### 查看课程表
- 左右滑动可以切换不同星期
- 点击右上角可以选择查看的周次
- 点击课程卡片可以查看详细信息

### 查询成绩
- 在底部导航栏点击"成绩"标签
- 可以看到所有课程成绩和平均绩点
- 显示学分、绩点等详细信息

### 设置课程提醒
1. 在底部导航栏点击"设置"标签
2. 开启"课程提醒"开关
3. 选择提前提醒的时间（5/10/15/20/30分钟）
4. 应用会在课程开始前发送通知

###功能开发进度

- [x] 课程表查看（支持周次切换）
- [x] 成绩查询（包含 GPA 计算）
- [x] 课程提醒功能
- [x] 用户登录功能（金智教务系统）
- [x] 账号管理（登录/退出）
- [ ] 支持自定义课程颜色
- [ ] 添加课程笔记功能
- [ ] 支持导出课程表为图片
- [ ] 添加考试倒计时功能
- [ ] 支持暗黑模式
- [ ] 考试安排查询
- [ ] 空闲教室查询林大学的课程表 API？
A: 需要联系吉林大学教务处或相关技术部门获取API接口文档和访问权限。

### Q: 如何添加登录功能？
A: 可以在 `lib/screens/` 目录下添加 `login_screen.dart`，实现用户登录逻辑，并在 `lib/services/api_service.dart` 中添加 token 管理。

### Q: 通知不起作用？
A: 请确保：
1. 已授予应用通知权限
2. Android 版本支持（需要 Android 8.0+）
3. 正确设置了学期开始日期

## 后续开发计划

- [ ] 添加用户登录功能
- [ ] 支持自定义课程颜色
- [ ] 添加课程笔记功能
- [ ] 支持导出课程表为图片
- [ ] 添加考试倒计时功能
- [ ] 支持暗黑模式

## 开发者

如有问题或建议，欢迎提出 Issue。

## 许可证

MIT License
