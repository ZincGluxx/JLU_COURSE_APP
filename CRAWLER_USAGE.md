# 金智教务系统爬虫使用说明

## 快速开始

### 1. 抓取 API 接口

由于金智教务系统的具体API接口可能因学校配置不同而有差异，需要手动抓包获取：

#### 使用浏览器开发者工具（推荐）

1. **打开浏览器**（推荐使用 Chrome 或 Edge）

2. **按 F12 打开开发者工具**

3. **切换到 Network（网络）标签**

4. **访问教务系统并登录**
   - 访问: https://iedu.jlu.edu.cn/
   - 输入学号和密码登录
   
5. **筛选 XHR 请求**
   - 在 Network 标签中点击 "XHR" 或 "Fetch" 筛选
   - 或在搜索框输入 "sys" 或 "modules"

6. **查找关键接口**

   查找以下类型的请求：

   **登录接口**:
   - URL 包含: `casValidate`、`login`、`auth`
   - 方法: POST
   - 请求体包含: username, password
   
   **课程表接口**:
   - URL 包含: `wdkb`、`xskcb`、`course`
   - 方法: POST
   - 响应包含: 课程名称、教师、教室等信息
   
   **成绩接口**:
   - URL 包含: `cjcx`、`grade`、`score`
   - 方法: POST
   - 响应包含: 课程成绩、学分、绩点

7. **记录关键信息**

   对于每个接口，记录：
   - 完整的 URL
   - 请求方法（GET/POST）
   - 请求头（Headers）
   - 请求参数（Payload）
   - 响应数据格式

#### 示例：查看课程表接口

右键点击课程表请求 → 选择 "Copy" → "Copy as cURL"

得到类似：
```bash
curl 'https://iedu.jlu.edu.cn/jwapp/sys/wdkb/modules/xskcb/xskcb.do' \
  -H 'Content-Type: application/json' \
  -H 'Cookie: JSESSIONID=...' \
  --data-raw '{"XNXQDM":"2024-2025-1"}'
```

### 2. 更新代码配置

#### 修改 API 路径

打开 `lib/services/jlu_api_service.dart`，找到以下代码：

```dart
// TODO: 根据实际抓包结果填写真实的API路径
static const String loginPath = '/jwapp/sys/emapfunauth/casValidate.do';
static const String coursePath = '/jwapp/sys/wdkb/modules/xskcb/xskcb.do';
static const String gradePath = '/jwapp/sys/cjcx/modules/cjcx/xscjcx.do';
```

替换为你抓包得到的实际路径。

#### 修改字段映射

根据实际的 API 响应格式，修改 `_parseCourse` 方法中的字段映射：

```dart
Course _parseCourse(Map<String, dynamic> json) {
  return Course(
    id: json['你抓包看到的课程ID字段'] ?? '',
    name: json['你抓包看到的课程名字段'] ?? '',
    teacher: json['你抓包看到的教师字段'] ?? '',
    location: json['你抓包看到的教室字段'] ?? '',
    weekday: int.parse(json['你抓包看到的星期字段']?.toString() ?? '1'),
    startSection: int.parse(json['你抓包看到的开始节次字段']?.toString() ?? '1'),
    endSection: int.parse(json['你抓包看到的结束节次字段']?.toString() ?? '2'),
    weeks: _parseWeeks(json['你抓包看到的周次字段']?.toString() ?? '1-16'),
    description: json['课程性质或备注字段'],
  );
}
```

#### 常见字段名对照表

| 功能 | 可能的字段名 |
|------|-------------|
| 课程ID | JXBH, KCH, courseId, id |
| 课程名 | KCM, KCMC, courseName, name |
| 教师 | SKJS, JSXM, teacher, teacherName |
| 教室 | JASMC, JXCDMC, location, classroom |
| 星期 | SKXQ, XQ, weekday, dayOfWeek |
| 开始节次 | KSJC, startSection |
| 结束节次 | JSJC, endSection |
| 周次 | KKZC, ZC, weeks |

### 3. 测试 API

#### 使用 Postman 测试

1. 下载安装 [Postman](https://www.postman.com/)

2. 新建请求，配置：
   - 方法: POST
   - URL: `https://iedu.jlu.edu.cn/你的API路径`
   - Headers: 
     ```
     Content-Type: application/json
     Cookie: 从浏览器复制的Cookie
     ```
   - Body (raw JSON):
     ```json
     {
       "XNXQDM": "2024-2025-1"
     }
     ```

3. 发送请求，检查响应数据

4. 如果成功，说明 API 可用

### 4. 在应用中登录

1. 运行应用
2. 在设置页面点击"未登录"
3. 输入学号和密码
4. 点击登录

**注意**: 首次登录可能失败，需要根据浏览器 Console 的错误信息调整代码。

## 常见问题排查

### 问题 1: 登录失败 403/401

**原因**: 可能缺少必要的请求头或Cookie

**解决方案**:
1. 对比浏览器中成功的请求和代码中的请求
2. 确保 Headers 包含所有必要字段：
   ```dart
   headers: {
     'Content-Type': 'application/x-www-form-urlencoded',
     'User-Agent': '...',
     'Referer': '...',
     'X-Requested-With': 'XMLHttpRequest',
   }
   ```

### 问题 2: 登录成功但获取数据失败

**原因**: Cookie 或 Token 未正确传递

**解决方案**:
1. 检查 `_extractCookies` 方法是否正确提取了 Cookie
2. 确认后续请求都携带了 Cookie
3. 检查是否需要额外的 Token（如 CSRF Token）

### 问题 3: 数据格式不匹配

**原因**: API 返回的字段名与代码中不一致

**解决方案**:
1. 打印响应数据: `print(response.body)`
2. 查看实际的字段名
3. 更新 `_parseCourse` 和 `_parseGrade` 方法中的字段映射

### 问题 4: 验证码

**原因**: 教务系统要求输入验证码

**解决方案**:
- 方案1: 使用 WebView 让用户手动输入验证码
- 方案2: 集成验证码识别服务（如超级鹰、云打码）
- 方案3: 查看是否可以绕过验证码（如使用特定的 User-Agent）

## 调试技巧

### 1. 启用详细日志

在 `jlu_api_service.dart` 中已经添加了 print 语句，运行应用时查看控制台输出：

```dart
print('正在访问登录页面...');
print('获取到初始Cookie: $_cookie');
print('登录成功！');
```

### 2. 使用 Charles/Fiddler 代理抓包

1. 安装 Charles 或 Fiddler
2. 配置手机代理（IP 为电脑 IP，端口 8888）
3. 在手机上操作应用
4. 观察所有网络请求

### 3. 对比请求差异

使用工具对比浏览器请求和应用请求的差异：
- URL 是否完全一致
- Headers 是否完整
- Body 格式是否正确
- Cookie 是否有效

## Python 辅助脚本

如果你熟悉 Python，可以先用以下脚本验证：

```python
import requests
import json

# 1. 测试登录
session = requests.Session()

login_url = 'https://iedu.jlu.edu.cn/jwapp/sys/emapfunauth/casValidate.do'
login_data = {
    'username': '你的学号',
    'password': '你的密码'
}

resp = session.post(login_url, data=login_data)
print('登录响应:', resp.text)

# 2. 获取课程表
course_url = 'https://iedu.jlu.edu.cn/jwapp/sys/wdkb/modules/xskcb/xskcb.do'
course_data = {
    'XNXQDM': '2024-2025-1'
}

resp = session.post(course_url, json=course_data)
print('课程表响应:', json.dumps(resp.json(), indent=2, ensure_ascii=False))
```

将响应数据保存下来，用于调整 Dart 代码中的解析逻辑。

## 安全提醒

1. **不要分享或公开你的学号密码**
2. **不要将包含真实凭证的代码提交到公开仓库**
3. **建议使用环境变量或配置文件存储敏感信息**
4. **考虑使用加密存储密码**

## 下一步

配置完成后：
1. 测试登录功能
2. 确认课程表数据正确显示
3. 测试成绩查询功能
4. 根据需要添加更多功能（如考试安排、教室查询等）

如有问题，请参考 `JLU_API_GUIDE.md` 中的详细说明。
